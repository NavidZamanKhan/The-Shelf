import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/models/mock_shelf_items.dart';
import 'package:the_shelf/theme/app_theme.dart';
import 'package:the_shelf/widgets/book_row.dart';

class ShelfDetailScreen extends StatelessWidget {
  final String category;

  const ShelfDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;
    final iconData = AppTheme.getCategoryIcon(category);

    return Scaffold(
      backgroundColor: activePalette.background,
      appBar: AppBar(
        backgroundColor: activePalette.background,
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
            Icon(iconData, size: 22, color: activePalette.primaryAccent),
            const SizedBox(width: 8),
            Text(
              category,
              style: TextStyle(
                fontFamily: AppTheme.serifFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: activePalette.primaryText,
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<ShelfBloc, ShelfState>(
        builder: (context, state) {
          if (state is ShelfLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: activePalette.primaryAccent,
              ),
            );
          } else if (state is ShelfLoaded) {
            // Combine state items with gated dev mock items for visual verification
            List<ShelfItem> effectiveItems = List.from(state.items);
            if (showMockDataInDev) {
              final existingIds = effectiveItems.map((e) => e.id).toSet();
              for (final mock in devMockShelfItems) {
                if (!existingIds.contains(mock.id)) {
                  effectiveItems.add(mock);
                }
              }
            }

            // Filter strictly by this screen's category
            final shelfItems = effectiveItems
                .where(
                  (item) =>
                      item.shelf.trim().toLowerCase() ==
                      category.trim().toLowerCase(),
                )
                .toList();

            if (shelfItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: activePalette.desaturatedEmptyBadge,
                        borderRadius: AppTheme.asymmetricBadgeRadius,
                      ),
                      child: Center(
                        child: Icon(
                          iconData,
                          size: 36,
                          color: activePalette.desaturatedEmptyText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Documents in $category',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: activePalette.primaryText,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Tap the "+" icon in the top header to import documents into this shelf.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: activePalette.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                // Streamlined Category Summary Banner (No duplicate category title text)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: activePalette.cardBackground,
                        borderRadius: AppTheme.asymmetricCardRadius,
                        border: Border.all(
                          color: activePalette.cardBorder,
                          width: 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: activePalette.badgeGradient,
                              borderRadius: AppTheme.asymmetricBadgeRadius,
                            ),
                            child: Center(
                              child: Icon(
                                iconData,
                                color: activePalette.primaryText,
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
                                  '${shelfItems.length} ${shelfItems.length == 1 ? 'document' : 'documents'} stored in this shelf',
                                  style: TextStyle(
                                    fontFamily: AppTheme.serifFontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: activePalette.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tap any item to view document details',
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

                // Book Rows Card List with Asymmetric Geometry
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: activePalette.cardBackground,
                        borderRadius: AppTheme.asymmetricCardRadius,
                        border: Border.all(
                          color: activePalette.cardBorder,
                          width: 1.0,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: shelfItems.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          thickness: 1,
                          color: activePalette.cardBorder,
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final item = shelfItems[index];
                          return TweenAnimationBuilder<double>(
                            duration: Duration(
                              milliseconds: 300 + (index * 50),
                            ),
                            curve: Curves.decelerate,
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            builder: (context, animVal, child) {
                              return Opacity(
                                opacity: animVal,
                                child: Transform.translate(
                                  offset: Offset(0, 14 * (1 - animVal)),
                                  child: child,
                                ),
                              );
                            },
                            child: BookRow(
                              item: item,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Opening "${item.title}"...'),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: activePalette.primaryAccent,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          }

          return const Center(child: Text('Initialize Shelf'));
        },
      ),
    );
  }
}
