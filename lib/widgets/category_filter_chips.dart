import 'package:flutter/material.dart';

/// Reusable horizontal scrolling category filter chip row widget.
class CategoryFilterChips extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final List<String> categories;

  const CategoryFilterChips({
    super.key,
    this.selectedCategory = 'All Items',
    required this.onCategorySelected,
    this.categories = const ['All Items', 'Books', 'PDFs', 'Articles'],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories.map((category) {
          final bool isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onCategorySelected(category);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
