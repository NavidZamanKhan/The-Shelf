import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
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
    final activePalette = context.watch<ThemeCubit>().state;
    final bool isEmpty = widget.itemCount == 0;
    final iconData = AppTheme.getCategoryIcon(widget.category);
    final countText = isEmpty
        ? 'Empty shelf'
        : (widget.itemCount == 1 ? '1 item' : '${widget.itemCount} items');

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
          child: Container(
            decoration: BoxDecoration(
              color: isEmpty ? activePalette.background : activePalette.cardBackground,
              borderRadius: AppTheme.asymmetricCardRadius,
              border: isEmpty
                  ? null
                  : Border.all(color: activePalette.cardBorder, width: 1.0),
            ),
            child: CustomPaint(
              painter: isEmpty ? _DashedBorderPainter(color: activePalette.dashedBorderColor) : null,
              child: Material(
                color: Colors.transparent,
                borderRadius: AppTheme.asymmetricCardRadius,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) => setState(() => _isPressed = false),
                  onTapCancel: () => setState(() => _isPressed = false),
                  onTap: widget.onTap,
                  splashColor: activePalette.lightAccent.withValues(alpha: 0.12),
                  highlightColor: activePalette.lightAccent.withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Icon Badge with Asymmetric Radius & Gradient
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: isEmpty ? null : activePalette.badgeGradient,
                            color: isEmpty ? activePalette.desaturatedEmptyBadge : null,
                            borderRadius: AppTheme.asymmetricBadgeRadius,
                          ),
                          child: Center(
                            child: Icon(
                              iconData,
                              color: isEmpty
                                  ? activePalette.desaturatedEmptyText
                                  : activePalette.primaryText,
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
                                style: TextStyle(
                                  fontFamily: AppTheme.serifFontFamily,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: isEmpty
                                      ? activePalette.desaturatedEmptyText
                                      : activePalette.primaryText,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                countText,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: isEmpty
                                      ? activePalette.desaturatedEmptyText
                                      : activePalette.secondaryText,
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
                                color: isEmpty
                                    ? activePalette.desaturatedEmptyBadge
                                    : activePalette.subtleBadgeBackground,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isEmpty
                                      ? activePalette.dashedBorderColor
                                      : activePalette.cardBorder,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${widget.itemCount}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isEmpty
                                      ? activePalette.desaturatedEmptyText
                                      : activePalette.primaryText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              PhosphorIcons.caretRight,
                              size: 16,
                              color: isEmpty
                                  ? activePalette.desaturatedEmptyText
                                  : activePalette.secondaryText,
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
        ),
      ),
    );
  }
}

/// CustomPainter for drawing dashed borders on empty shelf cards
class _DashedBorderPainter extends CustomPainter {
  final Color color;

  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomRight: const Radius.circular(20),
      bottomLeft: const Radius.circular(6),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    const double dashWidth = 6.0;
    const double dashSpace = 4.0;

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        dashPath.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
