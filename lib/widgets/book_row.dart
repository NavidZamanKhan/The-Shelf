import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/collection/collection_bloc.dart';
import 'package:the_shelf/blocs/collection/collection_state.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/services/file_launcher_service.dart';
import 'package:the_shelf/theme/app_theme.dart';
import 'package:the_shelf/widgets/add_to_collection_sheet.dart';

class BookRow extends StatefulWidget {
  final ShelfItem item;
  final VoidCallback? onTap;
  final bool showShelfName;

  const BookRow({
    super.key,
    required this.item,
    this.onTap,
    this.showShelfName = false,
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
    final activePalette = context.watch<ThemeCubit>().state;
    final ext = _getFileExtension(widget.item.filePath);
    final iconData = AppTheme.getCategoryIcon(widget.item.shelf);

    final subtitleText = widget.showShelfName
        ? '${widget.item.shelf} • $ext'
        : '$ext document';

    return AnimatedScale(
      scale: _isPressed ? 0.988 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutCubic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap ??
            () => FileLauncherService.instance.openFile(context, widget.item.filePath),
        onLongPress: () => AddToCollectionSheet.show(context, widget.item),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon Badge (Asymmetric Radius + Subtle Gradient)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: activePalette.badgeGradient,
                  borderRadius: AppTheme.asymmetricBadgeRadius,
                ),
                child: Center(
                  child: Icon(
                    iconData,
                    color: activePalette.primaryText,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title & Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.item.title,
                      style: TextStyle(
                        fontFamily: AppTheme.serifFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: activePalette.primaryText,
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: activePalette.secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Collection indicator chip & Format Tag
              BlocBuilder<CollectionBloc, CollectionState>(
                builder: (context, colState) {
                  final colMap = (colState is CollectionLoaded)
                      ? colState.documentCollectionMap
                      : <String, Set<String>>{};
                  final memberCount = colMap[widget.item.id]?.length ?? 0;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (memberCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: activePalette.primaryAccent.withValues(alpha: 0.12),
                            borderRadius: AppTheme.asymmetricBadgeRadius,
                            border: Border.all(
                              color: activePalette.primaryAccent.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                PhosphorIcons.bookmarkSimpleFill,
                                size: 12,
                                color: activePalette.primaryAccent,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$memberCount',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: activePalette.primaryAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: activePalette.subtleBadgeBackground,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: activePalette.cardBorder,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          ext,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: activePalette.primaryText,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          PhosphorIcons.dotsThreeVertical,
                          size: 18,
                          color: activePalette.secondaryText,
                        ),
                        onPressed: () => AddToCollectionSheet.show(context, widget.item),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
