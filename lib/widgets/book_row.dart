import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/collection/collection_bloc.dart';
import 'package:the_shelf/blocs/collection/collection_state.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_event.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/services/cloud_library_service.dart';
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

  void _showOptionsModal(BuildContext context) {
    final activePalette = context.read<ThemeCubit>().state;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: activePalette.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: activePalette.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Document Title
                Text(
                  widget.item.title,
                  style: TextStyle(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: activePalette.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.item.shelf} • ${_getFileExtension(widget.item.filePath)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: activePalette.secondaryText,
                  ),
                ),
                const SizedBox(height: 16),

                // Option 1: Add / Remove Collections
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: activePalette.primaryAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      PhosphorIcons.folderPlus,
                      color: activePalette.primaryAccent,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Add / Remove Collections',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: activePalette.primaryText,
                    ),
                  ),
                  subtitle: const Text('Organize in custom collections'),
                  onTap: () {
                    Navigator.pop(modalContext);
                    AddToCollectionSheet.show(context, widget.item);
                  },
                ),

                // Option 2: Backup to Cloud
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: activePalette.primaryAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      PhosphorIcons.cloudArrowUpBold,
                      color: activePalette.primaryAccent,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Backup to Cloud',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: activePalette.primaryText,
                    ),
                  ),
                  subtitle: const Text('Sync with your account across devices'),
                  onTap: () async {
                    Navigator.pop(modalContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Backing up "${widget.item.title}" to Cloud...'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    try {
                      await CloudLibraryService.instance.uploadDocument(widget.item);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Backed up "${widget.item.title}" to Cloud!'),
                            backgroundColor: activePalette.primaryAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to backup: $e'),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),

                const Divider(height: 24),

                // Option 3: Delete Document
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      PhosphorIcons.trash,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Delete Document',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                  subtitle: const Text('Remove permanently from library'),
                  onTap: () {
                    Navigator.pop(modalContext);
                    _confirmAndDelete(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmAndDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Document?'),
          content: Text('Are you sure you want to delete "${widget.item.title}" from your library?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<ShelfBloc>().add(DeleteDocumentEvent(widget.item.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${widget.item.title}"'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state.resolvedPalette;
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
            () => FileLauncherService.instance.openFile(
                  context,
                  widget.item.filePath,
                  documentId: widget.item.id,
                  title: widget.item.title,
                ),
        onLongPress: () => _showOptionsModal(context),
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
                        onPressed: () => _showOptionsModal(context),
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
