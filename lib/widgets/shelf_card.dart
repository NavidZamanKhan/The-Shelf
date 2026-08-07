import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/theme/app_theme.dart';

class ShelfCard extends StatefulWidget {
  final String category;
  final int itemCount;
  final int cardIndex;
  final VoidCallback onTap;

  const ShelfCard({
    super.key,
    required this.category,
    required this.itemCount,
    required this.onTap,
    this.cardIndex = 0,
  });

  @override
  State<ShelfCard> createState() => _ShelfCardState();
}

class _ShelfCardState extends State<ShelfCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final iconData = AppTheme.getCategoryIcon(widget.category);
    final countText = widget.itemCount == 1 ? '1 item' : '${widget.itemCount} items';

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (widget.cardIndex * 45)),
      curve: Curves.decelerate,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 18 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedScale(
          scale: _isPressed ? 0.988 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: widget.onTap,
              splashColor: AppTheme.terracottaLightAccent.withValues(alpha: 0.15),
              highlightColor: AppTheme.terracottaLightAccent.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Icon Badge Container
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.terracottaLightAccent.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          iconData,
                          color: AppTheme.terracottaPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Shelf Name & Count Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.category,
                            style: const TextStyle(
                              fontFamily: AppTheme.serifFontFamily,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.deepEspressoPrimaryText,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            countText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.warmRustSecondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Count Badge Tag & Caret Indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.subtleBadgeBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.softWarmBorder,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${widget.itemCount}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.deepEspressoPrimaryText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          PhosphorIcons.caretRight,
                          size: 16,
                          color: AppTheme.warmRustSecondaryText,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
