import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/theme/app_theme.dart';

/// Reusable compact top app header widget.
///
/// Supports both sliver mode (SliverAppBar for use inside CustomScrollView)
/// and non-sliver mode (regular container for use inside Column/PageView layouts).
class AppHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAddItemPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onFilterPressed;
  final bool isSliver;

  const AppHeader({
    super.key,
    this.title = 'The Shelf',
    this.onAddItemPressed,
    this.onSearchPressed,
    this.onFilterPressed,
    this.isSliver = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isSliver) {
      return SliverAppBar(
        pinned: true,
        floating: true,
        centerTitle: false,
        titleSpacing: 16.0,
        toolbarHeight: 56.0,
        backgroundColor: AppTheme.softParchmentBackground,
        title: _buildTitle(),
        actions: _buildActions(),
      );
    }

    // Non-sliver mode: a SafeArea + Container matching the SliverAppBar look
    return SafeArea(
      bottom: false,
      child: Container(
        height: 56.0,
        color: AppTheme.softParchmentBackground,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(child: _buildTitle()),
            ..._buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: AppTheme.serifFontFamily,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppTheme.deepEspressoPrimaryText,
        letterSpacing: -0.3,
      ),
    );
  }

  List<Widget> _buildActions() {
    return [
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
    ];
  }
}
