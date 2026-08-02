import 'package:flutter/material.dart';

/// Reusable compact top SliverAppBar widget without excess top padding.
class AppHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onFilterPressed;

  const AppHeader({
    super.key,
    this.title = 'The Shelf',
    this.onSearchPressed,
    this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      pinned: true,
      floating: true,
      centerTitle: false,
      titleSpacing: 16.0,
      toolbarHeight: 56.0,
      title: Text(
        title,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: 'Search Library',
          onPressed: onSearchPressed ?? () {},
        ),
        IconButton(
          icon: const Icon(Icons.filter_list_rounded),
          tooltip: 'Filter Shelves',
          onPressed: onFilterPressed ?? () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
