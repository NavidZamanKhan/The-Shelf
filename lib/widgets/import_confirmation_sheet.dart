import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/models/imported_document_summary.dart';
import 'package:the_shelf/theme/app_theme.dart';

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
    final activePalette = context.watch<ThemeCubit>().state;
    final classification = widget.summary.classification;
    final String recommendedShelf = classification.label;
    final double confidence = classification.confidence;
    final bool isLowConfidence = widget.summary.isLowConfidence;
    final bool isRecommendedSelected = _selectedShelf == recommendedShelf;
    final bool isEpub = widget.summary.fileName.toLowerCase().endsWith('.epub');

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
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: activePalette.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Document Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: activePalette.subtleBadgeBackground,
                      borderRadius: AppTheme.asymmetricBadgeRadius,
                      border: Border.all(
                        color: activePalette.cardBorder,
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isEpub ? PhosphorIcons.bookBookmarkBold : PhosphorIcons.filePdfBold,
                        color: activePalette.primaryAccent,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import Document',
                          style: TextStyle(
                            fontFamily: AppTheme.serifFontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: activePalette.primaryText,
                          ),
                        ),
                        if (widget.summary.isOcrUsed) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: activePalette.primaryAccent.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: activePalette.primaryAccent.withAlpha(50),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  PhosphorIcons.scanBold,
                                  size: 12,
                                  color: activePalette.primaryAccent,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'On-Device OCR Recognized',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                    color: activePalette.primaryAccent,
                                  ),
                                ),
                              ],
                            ),
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
                        ? activePalette.primaryAccent.withAlpha(25)
                        : activePalette.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRecommendedSelected
                          ? activePalette.primaryAccent
                          : activePalette.cardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.sparkleBold,
                        color: activePalette.primaryAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smart Recommendation',
                              style: TextStyle(
                                fontSize: 11,
                                color: activePalette.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$recommendedShelf (${(confidence * 100).toStringAsFixed(1)}% confidence)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: activePalette.primaryText,
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
                    color: activePalette.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: activePalette.cardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.infoBold,
                        color: activePalette.primaryAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Shelf Required',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: activePalette.primaryAccent,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Low text clarity detected • Please select the best shelf category below.',
                              style: TextStyle(
                                fontSize: 12,
                                color: activePalette.secondaryText,
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
                    style: TextStyle(fontSize: 12, color: activePalette.secondaryText),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        widget.summary.textSnippet,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: activePalette.secondaryText,
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
