import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/collection/collection_bloc.dart';
import 'package:the_shelf/blocs/collection/collection_event.dart';
import 'package:the_shelf/blocs/collection/collection_state.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/models/collection_model.dart';
import 'package:the_shelf/models/mock_shelf_items.dart';
import 'package:the_shelf/theme/app_theme.dart';
import 'package:the_shelf/widgets/book_row.dart';
import 'package:the_shelf/widgets/collection_card.dart';
import 'package:the_shelf/widgets/collection_item_picker_sheet.dart';
import 'package:the_shelf/widgets/create_collection_modal.dart';

class CollectionDetailScreen extends StatefulWidget {
  final CollectionModel collection;

  const CollectionDetailScreen({
    super.key,
    required this.collection,
  });

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  late CollectionModel _currentCollection;

  @override
  void initState() {
    super.initState();
    _currentCollection = widget.collection;
  }

  void _showOverflowMenu(BuildContext context) {
    final activePalette = context.read<ThemeCubit>().state;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: activePalette.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: activePalette.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(ctx).pop();
                CreateCollectionModal.show(context, initialCollection: _currentCollection);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: AppTheme.asymmetricCardRadius,
                  border: Border.all(
                    color: activePalette.cardBorder,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIcons.pencil, color: activePalette.primaryText, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Edit Collection',
                      style: TextStyle(
                        fontFamily: AppTheme.serifFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: activePalette.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmDelete(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: AppTheme.asymmetricCardRadius,
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(PhosphorIcons.trash, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Delete Collection',
                      style: TextStyle(
                        fontFamily: AppTheme.serifFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final activePalette = context.read<ThemeCubit>().state;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: activePalette.cardBackground,
        title: Text(
          'Delete Collection?',
          style: TextStyle(
            fontFamily: AppTheme.serifFontFamily,
            color: activePalette.primaryText,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${_currentCollection.name}"? Documents inside will not be deleted.',
          style: TextStyle(color: activePalette.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: activePalette.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CollectionBloc>().add(DeleteCollection(_currentCollection.id));
              Navigator.of(ctx).pop(); // pop dialog
              Navigator.of(context).pop(); // pop detail screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state.resolvedPalette;
    final accentColor = CollectionCard.parseHexColor(_currentCollection.colorHex, activePalette.primaryAccent);
    final iconData = CollectionCard.getCollectionIcon(_currentCollection.iconName);

    return MultiBlocListener(
      listeners: [
        BlocListener<CollectionBloc, CollectionState>(
          listener: (context, state) {
            if (state is CollectionLoaded) {
              final updated = state.collections.firstWhere(
                (c) => c.id == _currentCollection.id,
                orElse: () => _currentCollection,
              );
              setState(() {
                _currentCollection = updated;
              });
            }
          },
        ),
      ],
      child: BlocBuilder<CollectionBloc, CollectionState>(
        builder: (context, collectionState) {
          final docMap = (collectionState is CollectionLoaded)
              ? collectionState.documentCollectionMap
              : <String, Set<String>>{};

          return BlocBuilder<ShelfBloc, ShelfState>(
            builder: (context, shelfState) {
              final rawDocs = (shelfState is ShelfLoaded) ? shelfState.items : <ShelfItem>[];
              List<ShelfItem> effectiveDocs = List.from(rawDocs);
              if (showMockDataInDev) {
                final existingIds = effectiveDocs.map((e) => e.id).toSet();
                for (final mock in devMockShelfItems) {
                  if (!existingIds.contains(mock.id)) {
                    effectiveDocs.add(mock);
                  }
                }
              }

              // Filter documents that belong to this collection in docMap
              final collectionDocs = effectiveDocs.where((doc) {
                final colIds = docMap[doc.id] ?? <String>{};
                return colIds.contains(_currentCollection.id);
              }).toList();

              final collectionDocIds = collectionDocs.map((d) => d.id).toSet();

              return Scaffold(
                backgroundColor: activePalette.background,
                appBar: AppBar(
                  backgroundColor: activePalette.background,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(
                      PhosphorIcons.arrowLeft,
                      color: activePalette.primaryText,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconData, size: 22, color: accentColor),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _currentCollection.name,
                          style: TextStyle(
                            fontFamily: AppTheme.serifFontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: activePalette.primaryText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(PhosphorIcons.plus, color: accentColor),
                      tooltip: 'Add items to collection',
                      onPressed: () {
                        CollectionItemPickerSheet.show(
                          context: context,
                          collectionId: _currentCollection.id,
                          existingDocumentIds: collectionDocIds,
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(PhosphorIcons.dotsThreeVertical, color: activePalette.primaryText),
                      onPressed: () => _showOverflowMenu(context),
                    ),
                  ],
                ),
                body: CustomScrollView(
                  slivers: [
                    // Header Banner Card
                    SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverToBoxAdapter(
                        child: Container(
                          decoration: BoxDecoration(
                            color: activePalette.cardBackground,
                            borderRadius: AppTheme.asymmetricCardRadius,
                            border: Border.all(
                              color: activePalette.cardBorder,
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.18),
                                  borderRadius: AppTheme.asymmetricBadgeRadius,
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    iconData,
                                    size: 24,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentCollection.name,
                                      style: TextStyle(
                                        fontFamily: AppTheme.serifFontFamily,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: activePalette.primaryText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${collectionDocs.length} ${collectionDocs.length == 1 ? 'item' : 'items'} total',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: activePalette.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Empty state vs Document List
                    if (collectionDocs.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.12),
                                  borderRadius: AppTheme.asymmetricBadgeRadius,
                                ),
                                child: Center(
                                  child: Icon(
                                    iconData,
                                    size: 36,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Items in Collection',
                                style: TextStyle(
                                  fontFamily: AppTheme.serifFontFamily,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: activePalette.primaryText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap "+" above to organize documents here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: activePalette.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverToBoxAdapter(
                          child: Container(
                            decoration: BoxDecoration(
                              color: activePalette.cardBackground,
                              borderRadius: AppTheme.asymmetricCardRadius,
                              border: Border.all(
                                color: activePalette.cardBorder,
                                width: 1,
                              ),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: collectionDocs.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: activePalette.cardBorder.withValues(alpha: 0.5),
                                indent: 16,
                                endIndent: 16,
                              ),
                              itemBuilder: (context, index) {
                                final item = collectionDocs[index];
                                return BookRow(
                                  item: item,
                                  showShelfName: true,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
