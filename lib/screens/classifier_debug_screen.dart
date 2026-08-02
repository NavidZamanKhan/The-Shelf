import 'package:flutter/material.dart';
import 'package:the_shelf/services/shelf_classifier_service.dart';

class ClassifierDebugScreen extends StatefulWidget {
  const ClassifierDebugScreen({super.key});

  @override
  State<ClassifierDebugScreen> createState() => _ClassifierDebugScreenState();
}

class _ClassifierDebugScreenState extends State<ClassifierDebugScreen> {
  final TextEditingController _textController = TextEditingController();
  ClassificationResult? _result;
  bool _isLoading = false;

  final List<Map<String, String>> _samplePrompts = const [
    {
      'title': 'Fantasy (Wizard & Kingdom)',
      'text': 'A dark wizard threatens the magical kingdom with ancient dark spells',
    },
    {
      'title': 'Historical Fiction (WWII)',
      'text': 'The history of World War II and European political alliances in the 20th century',
    },
    {
      'title': 'Mystery (Detective)',
      'text': 'A detective investigates a mysterious murder mystery in a foggy city',
    },
    {
      'title': 'Poetry (Romantic Poems)',
      'text': 'A collection of romantic poems expressing deep love, heartbreak, and emotional devotion',
    },
    {
      'title': 'Philosophy (Consciousness)',
      'text': 'Deep philosophical thoughts on human consciousness, morality, and existence',
    },
    {
      'title': 'Bangla Horror (ভূতের ঘটনা)',
      'text': 'একটি ভয়ংকর পুরনো রাজবাড়িতে অশরীরী ভূতের রহস্যময় উপদ্রব ও আতঙ্কের ঘটনা...',
    },
    {
      'title': 'Bangla Misc/Romance (গভীর ভালোবাসা)',
      'text': 'দুটি তরুণ হৃদয়ের গভীর ভালোবাসা, প্রেম, ব্যাকুলতা ও আবেগঘন বিরহের কাহিনী...',
    },
    {
      'title': 'Bangla Sci-Fi (মহাকাশ অভিযান)',
      'text': 'ভবিষ্যতের মহাকাশ অভিযান, ভিনগ্রহের প্রাণী ও রোবটের বৈজ্ঞানিক কল্পকাহিনী...',
    },
  ];

  @override
  void initState() {
    super.initState();
    _textController.text = _samplePrompts.first['text']!;
    _runClassification();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _runClassification() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await ShelfClassifierService.instance.classifyAsync(text);
      if (mounted) {
        setState(() {
          _result = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Classification Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classifier Debug & Verification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sample Prompts Chips
            Text(
              'Sample Test Sentences:',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _samplePrompts.map((sample) {
                return ChoiceChip(
                  label: Text(sample['title']!),
                  selected: _textController.text == sample['text'],
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _textController.text = sample['text']!;
                      });
                      _runClassification();
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Input Text Field
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Input Text / Metadata',
                hintText: 'Enter book title, synopsis, or document text...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _textController.clear();
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Action Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _runClassification,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isLoading ? 'Classifying...' : 'Classify Shelf'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 24),

            // Results Card
            if (_result != null) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Predicted Shelf',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_result!.latencyMs.toStringAsFixed(3)} ms',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _result!.label,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Confidence: ${(_result!.confidence * 100).toStringAsFixed(2)}%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Top 3 Shelf Probabilities:',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._result!.top3.map((entry) {
                        final category = entry.key;
                        final prob = entry.value;
                        final percentStr = (prob * 100).toStringAsFixed(1);
                        final isTop = category == _result!.label;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    '$percentStr%',
                                    style: TextStyle(
                                      fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                                      color: isTop ? theme.colorScheme.primary : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: prob,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                color: isTop ? theme.colorScheme.primary : theme.colorScheme.outline,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
