import 'package:flutter/material.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/theme/app_theme.dart';

class BookRow extends StatefulWidget {
  final ShelfItem item;
  final VoidCallback? onTap;

  const BookRow({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  State<BookRow> createState() => _BookRowState();
}

class _BookRowState extends State<BookRow> {
  bool _isPressed = false;

  String _getFileExtension(String path) {
    final ext = path.split('.').last.toUpperCase();
    if (ext.length <= 4) return ext;
    return 'DOC';
  }

  @override
  Widget build(BuildContext context) {
    final ext = _getFileExtension(widget.item.filePath);
    final iconData = AppTheme.getCategoryIcon(widget.item.shelf);

    return AnimatedScale(
      scale: _isPressed ? 0.988 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutCubic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon Badge (Asymmetric Radius + Subtle Gradient)
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: AppTheme.badgeGradient,
                  borderRadius: AppTheme.asymmetricBadgeRadius,
                ),
                child: Center(
                  child: Icon(
                    iconData,
                    color: AppTheme.deepEspressoPrimaryText,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title & Author/Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.item.title,
                      style: const TextStyle(
                        fontFamily: AppTheme.serifFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepEspressoPrimaryText,
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.item.shelf} • $ext',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.warmRustSecondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Sharp-Cornered Format Tag (4px radius for crisp contrast)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.subtleBadgeBackground,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.softWarmBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  ext,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppTheme.deepEspressoPrimaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
