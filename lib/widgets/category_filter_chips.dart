import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/theme/app_theme.dart';

/// Underline-style category filter tabs row widget.
class CategoryFilterChips extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final List<String> categories;

  const CategoryFilterChips({
    super.key,
    this.selectedCategory = 'All Items',
    required this.onCategorySelected,
    this.categories = const ['All Items', 'Books', 'PDFs'],
  });

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: categories.map((category) {
            final bool isSelected = selectedCategory == category;

            return GestureDetector(
              onTap: () => onCategorySelected(category),
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.only(right: 20),
                padding: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? activePalette.primaryAccent
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontFamily: isSelected ? AppTheme.serifFontFamily : null,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? activePalette.primaryText
                        : activePalette.secondaryText,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
