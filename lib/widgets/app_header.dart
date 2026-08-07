import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/theme/app_theme.dart';

/// Reusable compact top SliverAppBar widget without excess top padding.
class AppHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAddItemPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onFilterPressed;

  const AppHeader({
    super.key,
    this.title = 'The Shelf',
    this.onAddItemPressed,
    this.onSearchPressed,
    this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      centerTitle: false,
      titleSpacing: 16.0,
      toolbarHeight: 56.0,
      backgroundColor: AppTheme.softParchmentBackground,
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: AppTheme.serifFontFamily,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.deepEspressoPrimaryText,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            PhosphorIcons.plusCircle,
            size: 24,
            color: AppTheme.terracottaPrimary,
          ),
          tooltip: 'Add Document',
          onPressed: onAddItemPressed,
        ),
        IconButton(
          icon: const Icon(
            PhosphorIcons.magnifyingGlass,
            size: 22,
            color: AppTheme.deepEspressoPrimaryText,
          ),
          tooltip: 'Search Library',
          onPressed: onSearchPressed ?? () {},
        ),
        IconButton(
          icon: const Icon(
            PhosphorIcons.funnel,
            size: 22,
            color: AppTheme.deepEspressoPrimaryText,
          ),
          tooltip: 'Filter Shelves',
          onPressed: onFilterPressed ?? () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
