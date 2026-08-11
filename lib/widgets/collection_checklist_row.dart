import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/theme/app_theme.dart';

class CollectionChecklistRow extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isChecked;
  final Color accentColor;
  final IconData iconData;
  final ValueChanged<bool> onChanged;

  const CollectionChecklistRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isChecked,
    required this.accentColor,
    required this.iconData,
    required this.onChanged,
  });

  @override
  State<CollectionChecklistRow> createState() => _CollectionChecklistRowState();
}

class _CollectionChecklistRowState extends State<CollectionChecklistRow> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;

    return AnimatedScale(
      scale: _isPressed ? 0.988 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOutCubic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () => widget.onChanged(!widget.isChecked),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: activePalette.cardBackground,
            borderRadius: AppTheme.asymmetricCardRadius,
            border: Border.all(
              color: widget.isChecked
                  ? widget.accentColor.withValues(alpha: 0.5)
                  : activePalette.cardBorder,
              width: widget.isChecked ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Icon Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.18),
                  borderRadius: AppTheme.asymmetricBadgeRadius,
                  border: Border.all(
                    color: widget.accentColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    widget.iconData,
                    size: 20,
                    color: widget.accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: AppTheme.serifFontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: activePalette.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: activePalette.secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Phosphor Checkbox Indicator
              Icon(
                widget.isChecked
                    ? PhosphorIcons.checkSquareFill
                    : PhosphorIcons.square,
                size: 22,
                color: widget.isChecked
                    ? widget.accentColor
                    : activePalette.secondaryText.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
