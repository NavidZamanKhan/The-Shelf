import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_event.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/models/mock_shelf_items.dart';
import 'package:the_shelf/theme/app_theme.dart';
import 'package:the_shelf/widgets/book_row.dart';

class ShelfDetailScreen extends StatelessWidget {
  final String category;

  const ShelfDetailScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;
    final iconData = AppTheme.getCategoryIcon(category);

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
            Icon(iconData, size: 22, color: activePalette.primaryAccent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                category,
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
      ),
      body: BlocBuilder<ShelfBloc, ShelfState>(
        builder: (context, state) {
          if (state is ShelfLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: activePalette.primaryAccent,
              ),
            );
          }

          // Safely extract loaded items or default to empty list
          final List<ShelfItem> rawItems = (state is ShelfLoaded) ? state.items : [];

          // Combine state items with gated dev mock items for visual verification
          List<ShelfItem> effectiveItems = List.from(rawItems);
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
                  Text(
                    'Tap + above to import files into this shelf',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: activePalette.secondaryText,
                        ),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
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
                            gradient: activePalette.badgeGradient,
                            borderRadius: AppTheme.asymmetricBadgeRadius,
                          ),
                          child: Center(
                            child: Icon(
                              iconData,
                              size: 24,
                              color: activePalette.primaryText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category,
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
                                '${shelfItems.length} ${shelfItems.length == 1 ? 'item' : 'items'} total',
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
                      itemCount: shelfItems.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: activePalette.cardBorder.withValues(alpha: 0.5),
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final item = shelfItems[index];
                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.redAccent.withValues(alpha: 0.9),
                            child: const Icon(
                              PhosphorIcons.trash,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          onDismissed: (_) {
                            context.read<ShelfBloc>().add(DeleteDocumentEvent(item.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Deleted "${item.title}"'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: BookRow(item: item),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}
