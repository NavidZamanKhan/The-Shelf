import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

/// Classification result data container.
class ClassificationResult {
  final String label;
  final double confidence;
  final Map<String, double> probabilities;
  final List<MapEntry<String, double>> top3;
  final double latencyMs;

  ClassificationResult({
    required this.label,
    required this.confidence,
    required this.probabilities,
    required this.top3,
    required this.latencyMs,
  });
}

/// On-device pure Dart TF-IDF + Logistic Regression Classifier.
class _ShelfClassifier {
  final List<String> classes;
  final Map<String, int> vocabulary;
  final List<double> idf;
  final List<List<double>> coef;
  final List<double> intercept;
  final bool sublinearTf;

  _ShelfClassifier({
    required this.classes,
    required this.vocabulary,
    required this.idf,
    required this.coef,
    required this.intercept,
    this.sublinearTf = true,
  });

  factory _ShelfClassifier.fromJson(Map<String, dynamic> json) {
    final classesList = List<String>.from(json['classes']);
    final vocabMap = Map<String, int>.from(json['vocabulary']);
    final idfList = (json['idf'] as List).map((e) => (e as num).toDouble()).toList();
    final coefList = (json['coef'] as List)
        .map((row) => (row as List).map((e) => (e as num).toDouble()).toList())
        .toList();
    final interceptList =
        (json['intercept'] as List).map((e) => (e as num).toDouble()).toList();
    final sublinear = json['sublinear_tf'] ?? true;

    return _ShelfClassifier(
      classes: classesList,
      vocabulary: vocabMap,
      idf: idfList,
      coef: coefList,
      intercept: interceptList,
      sublinearTf: sublinear,
    );
  }

  /// Tokenizes string into lowercased words and extracts 1-grams & 2-grams.
  List<String> _extractTokens(String text) {
    final RegExp wordRegExp = RegExp(r'[\p{L}\p{N}]+', unicode: true);
    final Iterable<Match> matches = wordRegExp.allMatches(text.toLowerCase());
    final List<String> words = matches.map((m) => m.group(0)!).toList();

    final List<String> tokens = [];
    for (int i = 0; i < words.length; i++) {
      tokens.add(words[i]);
      if (i < words.length - 1) {
        tokens.add('${words[i]} ${words[i + 1]}');
      }
    }
    return tokens;
  }

  ClassificationResult predict(String text) {
    final stopwatch = Stopwatch()..start();
    final List<String> tokens = _extractTokens(text);

    // Count term frequencies
    final Map<int, int> termCounts = {};
    for (final token in tokens) {
      if (vocabulary.containsKey(token)) {
        final int idx = vocabulary[token]!;
        termCounts[idx] = (termCounts[idx] ?? 0) + 1;
      }
    }

    // Build sublinear TF * IDF sparse vector
    final Map<int, double> sparseVec = {};
    double sumSq = 0.0;

    termCounts.forEach((idx, count) {
      final double tf = sublinearTf ? (1.0 + log(count)) : count.toDouble();
      final double val = tf * idf[idx];
      sparseVec[idx] = val;
      sumSq += val * val;
    });

    // L2 Normalize
    final double l2Norm = sqrt(sumSq);
    if (l2Norm > 0) {
      sparseVec.updateAll((key, val) => val / l2Norm);
    }

    // Dot product: scores = (coef * sparseVec) + intercept
    final int numClasses = classes.length;
    final List<double> scores = List<double>.from(intercept);

    sparseVec.forEach((featureIdx, featureVal) {
      for (int c = 0; c < numClasses; c++) {
        scores[c] += coef[c][featureIdx] * featureVal;
      }
    });

    // Softmax
    double maxScore = scores.reduce(max);
    double expSum = 0.0;
    final List<double> expScores = List.filled(numClasses, 0.0);

    for (int c = 0; c < numClasses; c++) {
      final double expVal = exp(scores[c] - maxScore);
      expScores[c] = expVal;
      expSum += expVal;
    }

    final Map<String, double> probabilities = {};
    for (int c = 0; c < numClasses; c++) {
      probabilities[classes[c]] = expScores[c] / expSum;
    }

    // Sorted probability entries
    final sortedEntries = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    stopwatch.stop();
    final double latency = stopwatch.elapsedMicroseconds / 1000.0;

    final topEntry = sortedEntries.first;
    final top3 = sortedEntries.take(3).toList();

    return ClassificationResult(
      label: topEntry.key,
      confidence: topEntry.value,
      probabilities: probabilities,
      top3: top3,
      latencyMs: latency,
    );
  }
}

/// Singleton Service for Managing Classifier Lifecycle & Inference.
class ShelfClassifierService {
  static final ShelfClassifierService instance = ShelfClassifierService._internal();
  ShelfClassifierService._internal();

  _ShelfClassifier? _classifier;
  Future<void>? _initFuture;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Thread-safe memoized initialization guard.
  Future<void> ensureInitialized() {
    _initFuture ??= _loadModelAsset();
    return _initFuture!;
  }

  Future<void> _loadModelAsset() async {
    if (_isInitialized) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/models/tfidf_model.json');
      final jsonMap = jsonDecode(jsonStr);
      _classifier = _ShelfClassifier.fromJson(jsonMap);
      _isInitialized = true;
    } catch (e) {
      _initFuture = null; // Allow retry on failure
      rethrow;
    }
  }

  /// Synchronous classification call (requires ensureInitialized() completed).
  ClassificationResult classify(String text) {
    if (!_isInitialized || _classifier == null) {
      throw StateError('ShelfClassifierService is not initialized. Call ensureInitialized() first.');
    }
    return _classifier!.predict(text);
  }

  /// Async classification call that safely awaits initialization if not yet ready.
  Future<ClassificationResult> classifyAsync(String text) async {
    await ensureInitialized();
    return classify(text);
  }
}
