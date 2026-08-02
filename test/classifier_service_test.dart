import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_shelf/services/shelf_classifier_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ShelfClassifierService integration test with asset model', () async {
    // Read model JSON directly from asset path
    final file = File('assets/models/tfidf_model.json');
    expect(file.existsSync(), isTrue);

    final jsonStr = await file.readAsString();
    expect(jsonStr.isNotEmpty, isTrue);

    // Initialize service
    await ShelfClassifierService.instance.ensureInitialized();
    expect(ShelfClassifierService.instance.isInitialized, isTrue);

    final List<Map<String, String>> testCases = [
      {
        'text': 'A dark wizard threatens the magical kingdom with ancient dark spells',
        'expected': 'Fantasy',
      },
      {
        'text': 'The history of World War II and European political alliances in the 20th century',
        'expected': 'Historical Fiction',
      },
      {
        'text': 'A detective investigates a mysterious murder mystery in a foggy city',
        'expected': 'Mystery',
      },
      {
        'text': 'A collection of romantic poems expressing deep love, heartbreak, and emotional devotion',
        'expected': 'Poetry',
      },
      {
        'text': 'Deep philosophical thoughts on human consciousness, morality, and existence',
        'expected': 'Self-Help & Personal Development',
      },
      {
        'text': 'একটি ভয়ংকর পুরনো রাজবাড়িতে অশরীরী ভূতের রহস্যময় উপদ্রব ও আতঙ্কের ঘটনা...',
        'expected': 'Horror',
      },
      {
        'text': 'দুটি তরুণ হৃদয়ের গভীর ভালোবাসা, প্রেম, ব্যাকুলতা ও আবেগঘন বিরহের কাহিনী...',
        'expected': 'Miscellaneous',
      },
      {
        'text': 'ভবিষ্যতের মহাকাশ অভিযান, ভিনগ্রহের প্রাণী ও রোবটের বৈজ্ঞানিক কল্পকাহিনী...',
        'expected': 'Science Fiction',
      },
    ];

    print('\n============================================================');
    print('FLUTTER CLASSIFIER SERVICE INTEGRATION TEST RESULTS');
    print('============================================================');

    for (int i = 0; i < testCases.length; i++) {
      final text = testCases[i]['text']!;
      final expected = testCases[i]['expected']!;

      final result = ShelfClassifierService.instance.classify(text);

      print('[Sample ${i + 1}]: "${text.length > 50 ? text.substring(0, 50) + "..." : text}"');
      print('  -> Predicted: [${result.label}] (Confidence: ${(result.confidence * 100).toStringAsFixed(2)}%) | Latency: ${result.latencyMs.toStringAsFixed(3)} ms');
      print('  -> Top 3: ${result.top3.map((e) => "${e.key}: ${(e.value * 100).toStringAsFixed(1)}%").join(', ')}');

      expect(result.label, equals(expected));
    }

    print('============================================================\n');
  });
}
