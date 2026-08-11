import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/models/collection_model.dart';
import 'package:the_shelf/theme/app_theme.dart';

class CollectionCard extends StatefulWidget {
  final CollectionModel collection;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  const CollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
    this.onMoreTap,
  });

  /// Maps string icon names to PhosphorIconData
  static IconData getCollectionIcon(String iconName) {
    switch (iconName) {
      case 'folder':
        return PhosphorIcons.folder;
      case 'star':
        return PhosphorIcons.star;
      case 'heart':
        return PhosphorIcons.heart;
      case 'tag':
        return PhosphorIcons.tag;
      case 'bookOpen':
        return PhosphorIcons.bookOpen;
      case 'lightning':
        return PhosphorIcons.lightning;
      case 'archive':
        return PhosphorIcons.archive;
      case 'bookmarkSimple':
      default:
        return PhosphorIcons.bookmarkSimple;
    }
  }

  /// Parses hex color string into Color object
  static Color parseHexColor(String hexString, Color defaultColor) {
    try {
      final cleanHex = hexString.replaceAll('#', '');
      if (cleanHex.length == 6) {
        return Color(int.parse('FF$cleanHex', radix: 16));
      }
      return defaultColor;
    } catch (_) {
      return defaultColor;
    }
  }

  @override
  State<CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<CollectionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;
    final accentColor = CollectionCard.parseHexColor(
      widget.collection.colorHex,
      activePalette.primaryAccent,
    );
    final iconData = CollectionCard.getCollectionIcon(widget.collection.iconName);

    return AnimatedScale(
      scale: _isPressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOutCubic,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: activePalette.cardBackground,
          borderRadius: AppTheme.asymmetricCardRadius,
          border: Border.all(
            color: activePalette.cardBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppTheme.asymmetricCardRadius,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              splashColor: accentColor.withValues(alpha: 0.1),
              highlightColor: accentColor.withValues(alpha: 0.05),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Left Custom Color Accent Bar
                    Container(
                      width: 6,
                      color: accentColor,
                    ),
                    const SizedBox(width: 14),

                    // Icon Badge with custom color background
                    Container(
                      width: 44,
                      height: 44,
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
                          size: 22,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Collection Title and Subtitle metadata
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.collection.name,
                              style: TextStyle(
                                fontFamily: AppTheme.serifFontFamily,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: activePalette.primaryText,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.collection.itemCount} ${widget.collection.itemCount == 1 ? 'item' : 'items'} • Custom Collection',
                              style: TextStyle(
                                fontSize: 13,
                                color: activePalette.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Chevron or optional overflow menu button
                    if (widget.onMoreTap != null)
                      IconButton(
                        icon: Icon(
                          PhosphorIcons.dotsThreeVertical,
                          color: activePalette.secondaryText,
                        ),
                        onPressed: widget.onMoreTap,
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Icon(
                          PhosphorIcons.caretRight,
                          size: 18,
                          color: activePalette.secondaryText.withValues(alpha: 0.6),
                        ),
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
