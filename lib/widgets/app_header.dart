import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/theme/app_color_palette.dart';
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
    final activePalette = context.watch<ThemeCubit>().state;

    if (isSliver) {
      return SliverAppBar(
        pinned: true,
        floating: true,
        centerTitle: false,
        titleSpacing: 16.0,
        toolbarHeight: 56.0,
        backgroundColor: activePalette.background,
        title: _buildTitle(activePalette),
        actions: _buildActions(activePalette),
      );
    }

    // Non-sliver mode: a SafeArea + Container matching the SliverAppBar look
    return SafeArea(
      bottom: false,
      child: Container(
        height: 56.0,
        color: activePalette.background,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(child: _buildTitle(activePalette)),
            ..._buildActions(activePalette),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(AppColorPalette palette) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: AppTheme.serifFontFamily,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: palette.primaryText,
        letterSpacing: -0.3,
      ),
    );
  }

  List<Widget> _buildActions(AppColorPalette palette) {
    return [
      IconButton(
        icon: Icon(
          PhosphorIcons.plusCircle,
          size: 24,
          color: palette.primaryAccent,
        ),
        tooltip: 'Add Document',
        onPressed: onAddItemPressed,
      ),
      IconButton(
        icon: Icon(
          PhosphorIcons.magnifyingGlass,
          size: 22,
          color: palette.primaryText,
        ),
        tooltip: 'Search Library',
        onPressed: onSearchPressed ?? () {},
      ),
      IconButton(
        icon: Icon(
          PhosphorIcons.funnel,
          size: 22,
          color: palette.primaryText,
        ),
        tooltip: 'Filter Shelves',
        onPressed: onFilterPressed ?? () {},
      ),
      const SizedBox(width: 8),
    ];
  }
}
