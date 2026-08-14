import 'package:flutter/material.dart';
import 'package:the_shelf/models/imported_document_summary.dart';

/// Modal bottom sheet for reviewing extracted document metadata, recommended shelf prediction,
/// and confirming shelf assignment.
class ImportConfirmationSheet extends StatefulWidget {
  final ImportedDocumentSummary summary;

  const ImportConfirmationSheet({
    super.key,
    required this.summary,
  });

  @override
  State<ImportConfirmationSheet> createState() => _ImportConfirmationSheetState();
}

class _ImportConfirmationSheetState extends State<ImportConfirmationSheet> {
  late TextEditingController _titleController;
  String? _selectedShelf;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.summary.title);
    // If low confidence or insufficient text, do NOT default to Miscellaneous. Require user choice.
    if (!widget.summary.isLowConfidence) {
      _selectedShelf = widget.summary.classification.label;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classification = widget.summary.classification;
    final String recommendedShelf = classification.label;
    final double confidence = classification.confidence;
    final bool isLowConfidence = widget.summary.isLowConfidence;
    final bool isRecommendedSelected = _selectedShelf == recommendedShelf;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Document Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.summary.fileName.toLowerCase().endsWith('.epub')
                          ? Icons.book
                          : Icons.picture_as_pdf,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import Document',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.summary.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (widget.summary.isOcrUsed) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.document_scanner,
                                size: 12,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Extracted via On-Device OCR',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Title Editor Field
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Document Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),

              const SizedBox(height: 16),

              // Recommendation Badge or Low-Confidence Notice
              if (!isLowConfidence)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isRecommendedSelected
                        ? theme.colorScheme.secondaryContainer.withAlpha(128)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRecommendedSelected
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: theme.colorScheme.secondary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smart Recommendation',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '$recommendedShelf (${(confidence * 100).toStringAsFixed(1)}% confidence)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Shelf Required',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Low text clarity detected • Please select the best shelf category below.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Shelf Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedShelf,
                hint: const Text('Select a Shelf...'),
                decoration: const InputDecoration(
                  labelText: 'Assign to Shelf',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shelves),
                ),
                items: classification.probabilities.keys.map((String shelf) {
                  final bool isTop = !isLowConfidence && (shelf == recommendedShelf);
                  return DropdownMenuItem<String>(
                    value: shelf,
                    child: Text(
                      isTop ? '$shelf  (Recommended)' : shelf,
                      style: TextStyle(
                        fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedShelf = newValue;
                  });
                },
              ),

              const SizedBox(height: 12),

              // Extracted Text Preview Tile
              if (widget.summary.textSnippet.isNotEmpty)
                ExpansionTile(
                  leading: const Icon(Icons.short_text),
                  title: const Text('Extracted Text Preview'),
                  subtitle: Text(
                    '${widget.summary.textSnippet.length} characters excerpt used for classification',
                    style: theme.textTheme.bodySmall,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        widget.summary.textSnippet,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectedShelf == null
                          ? null
                          : () {
                              final confirmedTitle = _titleController.text.trim();
                              Navigator.pop(context, {
                                'confirmed': true,
                                'title': confirmedTitle.isEmpty
                                    ? widget.summary.title
                                    : confirmedTitle,
                                'shelf': _selectedShelf!,
                              });
                            },
                      icon: const Icon(Icons.check),
                      label: const Text('Add to Shelf'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
