import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/collection/collection_bloc.dart';
import 'package:the_shelf/blocs/collection/collection_event.dart';
import 'package:the_shelf/blocs/collection/collection_state.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/theme/app_theme.dart';
import 'package:the_shelf/widgets/collection_card.dart';
import 'package:the_shelf/widgets/create_collection_modal.dart';

import 'package:the_shelf/widgets/collection_checklist_row.dart';

class AddToCollectionSheet extends StatefulWidget {
  final ShelfItem item;

  const AddToCollectionSheet({
    super.key,
    required this.item,
  });

  static Future<void> show(BuildContext context, ShelfItem item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToCollectionSheet(item: item),
    );
  }

  @override
  State<AddToCollectionSheet> createState() => _AddToCollectionSheetState();
}

class _AddToCollectionSheetState extends State<AddToCollectionSheet> {
  final Set<String> _selectedCollectionIds = {};
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
      child: BlocBuilder<CollectionBloc, CollectionState>(
        builder: (context, state) {
          if (state is CollectionLoading) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final collections = (state is CollectionLoaded) ? state.collections : [];
          final docMap = (state is CollectionLoaded)
              ? state.documentCollectionMap
              : <String, Set<String>>{};

          if (!_isInitialized) {
            final initialMemberships = docMap[widget.item.id] ?? <String>{};
            _selectedCollectionIds.addAll(initialMemberships);
            _isInitialized = true;
          }

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
                    color: activePalette.secondaryText.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and Document context
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add to Collection',
                          style: TextStyle(
                            fontFamily: AppTheme.serifFontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: activePalette.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.item.title,
                          style: TextStyle(
                            fontSize: 13,
                            color: activePalette.secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.x, color: activePalette.secondaryText),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Empty Collections view vs Checklist
              if (collections.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: activePalette.subtleBadgeBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        PhosphorIcons.bookmarkSimple,
                        size: 36,
                        color: activePalette.secondaryText,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Collections Created Yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: activePalette.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create custom collections to organize documents across shelves.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: activePalette.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          CreateCollectionModal.show(context);
                        },
                        icon: const Icon(PhosphorIcons.plus, size: 18),
                        label: const Text('Create Collection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activePalette.primaryAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: collections.length,
                    itemBuilder: (context, index) {
                      final col = collections[index];
                      final isChecked = _selectedCollectionIds.contains(col.id);
                      final colColor = CollectionCard.parseHexColor(col.colorHex, activePalette.primaryAccent);
                      final iconData = CollectionCard.getCollectionIcon(col.iconName);

                      return CollectionChecklistRow(
                        title: col.name,
                        subtitle: '${col.itemCount} ${col.itemCount == 1 ? 'item' : 'items'}',
                        isChecked: isChecked,
                        accentColor: colColor,
                        iconData: iconData,
                        onChanged: (bool value) {
                          setState(() {
                            if (value) {
                              _selectedCollectionIds.add(col.id);
                            } else {
                              _selectedCollectionIds.remove(col.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Footer CTA Buttons (Add New + Save)
                Row(
                  children: [
                    if (collections.length < 20)
                      TextButton.icon(
                        onPressed: () {
                          CreateCollectionModal.show(context);
                        },
                        icon: Icon(PhosphorIcons.plus, size: 16, color: activePalette.primaryAccent),
                        label: Text(
                          'New Collection',
                          style: TextStyle(color: activePalette.primaryAccent),
                        ),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        context.read<CollectionBloc>().add(
                              BatchSetDocumentCollections(
                                documentId: widget.item.id,
                                collectionIds: _selectedCollectionIds.toList(),
                              ),
                            );
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activePalette.primaryAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save Membership'),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
