import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/collection/collection_bloc.dart';
import 'package:the_shelf/blocs/collection/collection_event.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/models/mock_shelf_items.dart';
import 'package:the_shelf/theme/app_theme.dart';
import 'package:the_shelf/widgets/collection_checklist_row.dart';

class CollectionItemPickerSheet extends StatefulWidget {
  final String collectionId;
  final Set<String> existingDocumentIds;

  const CollectionItemPickerSheet({
    super.key,
    required this.collectionId,
    required this.existingDocumentIds,
  });

  static Future<void> show({
    required BuildContext context,
    required String collectionId,
    required Set<String> existingDocumentIds,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CollectionItemPickerSheet(
        collectionId: collectionId,
        existingDocumentIds: existingDocumentIds,
      ),
    );
  }

  @override
  State<CollectionItemPickerSheet> createState() => _CollectionItemPickerSheetState();
}

class _CollectionItemPickerSheetState extends State<CollectionItemPickerSheet> {
  final Set<String> _selectedDocIds = {};
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: activePalette.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: activePalette.cardBorder,
          width: 1,
        ),
      ),
      child: BlocBuilder<ShelfBloc, ShelfState>(
        builder: (context, state) {
          final List<ShelfItem> rawItems = (state is ShelfLoaded) ? state.items : [];
          List<ShelfItem> allDocs = List.from(rawItems);
          if (showMockDataInDev) {
            final existing = allDocs.map((e) => e.id).toSet();
            for (final mock in devMockShelfItems) {
              if (!existing.contains(mock.id)) {
                allDocs.add(mock);
              }
            }
          }

          // Filter documents matching search query and NOT already in collection
          final availableDocs = allDocs.where((doc) {
            final matchesSearch = _searchQuery.isEmpty ||
                doc.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                doc.shelf.toLowerCase().contains(_searchQuery.toLowerCase());
            final notInCollection = !widget.existingDocumentIds.contains(doc.id);
            return matchesSearch && notInCollection;
          }).toList();

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: activePalette.secondaryText.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and Search
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Items to Collection',
                    style: TextStyle(
                      fontFamily: AppTheme.serifFontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: activePalette.primaryText,
                    ),
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.x, color: activePalette.secondaryText),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search Bar
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(color: activePalette.primaryText, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search documents by title or shelf...',
                  hintStyle: TextStyle(color: activePalette.secondaryText.withValues(alpha: 0.6)),
                  prefixIcon: Icon(PhosphorIcons.magnifyingGlass, color: activePalette.secondaryText),
                  filled: true,
                  fillColor: activePalette.subtleBadgeBackground,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Document list selection
              if (availableDocs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Text(
                    widget.existingDocumentIds.length == allDocs.length
                        ? 'All library documents are already in this collection.'
                        : 'No matching documents found.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: activePalette.secondaryText, fontSize: 14),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: availableDocs.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: activePalette.cardBorder.withValues(alpha: 0.4),
                    ),
                    itemBuilder: (context, index) {
                      final doc = availableDocs[index];
                      final isSelected = _selectedDocIds.contains(doc.id);

                      return CollectionChecklistRow(
                        title: doc.title,
                        subtitle: '${doc.shelf} • ${doc.filePath.split('.').last.toUpperCase()}',
                        isChecked: isSelected,
                        accentColor: activePalette.primaryAccent,
                        iconData: AppTheme.getCategoryIcon(doc.shelf),
                        onChanged: (bool value) {
                          setState(() {
                            if (value) {
                              _selectedDocIds.add(doc.id);
                            } else {
                              _selectedDocIds.remove(doc.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),

              // Add CTA Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _selectedDocIds.isEmpty
                      ? null
                      : () {
                          context.read<CollectionBloc>().add(
                                AddDocumentsToCollectionEvent(
                                  collectionId: widget.collectionId,
                                  documentIds: _selectedDocIds.toList(),
                                ),
                              );
                          Navigator.of(context).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activePalette.primaryAccent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: activePalette.secondaryText.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Add ${_selectedDocIds.length} ${_selectedDocIds.length == 1 ? 'Item' : 'Items'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
