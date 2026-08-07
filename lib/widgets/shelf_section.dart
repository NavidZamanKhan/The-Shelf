import 'package:flutter/material.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/theme/app_theme.dart';
import 'package:the_shelf/widgets/book_row.dart';

class ShelfSection extends StatelessWidget {
  final String category;
  final List<ShelfItem> items;
  final int sectionIndex;
  final Function(ShelfItem item)? onItemTap;

  const ShelfSection({
    super.key,
    required this.category,
    required this.items,
    this.sectionIndex = 0,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final iconData = AppTheme.getCategoryIcon(category);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + (sectionIndex * 60)),
      curve: Curves.decelerate,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    iconData,
                    size: 20,
                    color: AppTheme.terracottaPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: const TextStyle(
                      fontFamily: AppTheme.serifFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepEspressoPrimaryText,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Pill Count Tag with subtle contrast
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.terracottaLightAccent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${items.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepEspressoPrimaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Container encapsulating BookRows
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppTheme.softWarmBorder,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return BookRow(
                    item: item,
                    onTap: () => onItemTap?.call(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
