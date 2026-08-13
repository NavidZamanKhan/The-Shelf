import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/models/sort_option.dart';
import 'package:the_shelf/theme/app_theme.dart';

/// Modal bottom sheet allowing users to select sorting criteria for the library.
class SortOptionsModal extends StatelessWidget {
  final SortOption currentOption;
  final ValueChanged<SortOption> onOptionSelected;

  const SortOptionsModal({
    super.key,
    required this.currentOption,
    required this.onOptionSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required SortOption currentOption,
    required ValueChanged<SortOption> onOptionSelected,
  }) {
    final activePalette = context.read<ThemeCubit>().state;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: activePalette.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return SortOptionsModal(
          currentOption: currentOption,
          onOptionSelected: onOptionSelected,
        );
      },
    );
  }

  IconData _getIconForOption(SortOption option) {
    switch (option) {
      case SortOption.recentlyAdded:
        return PhosphorIcons.clockCounterClockwise;
      case SortOption.populatedFirst:
        return PhosphorIcons.sparkle;
      case SortOption.alphabeticalAsc:
        return PhosphorIcons.sortAscending;
      case SortOption.alphabeticalDesc:
        return PhosphorIcons.sortDescending;
      case SortOption.mostItems:
        return PhosphorIcons.stack;
      case SortOption.leastItems:
        return PhosphorIcons.stackSimple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: activePalette.secondaryText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.funnel,
                      size: 20,
                      color: activePalette.primaryAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sort & Filter Shelves',
                      style: TextStyle(
                        fontFamily: AppTheme.serifFontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: activePalette.primaryText,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    PhosphorIcons.x,
                    color: activePalette.secondaryText,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Options List
            Column(
              children: SortOption.values.map((option) {
                final isSelected = option == currentOption;
                final iconData = _getIconForOption(option);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      onOptionSelected(option);
                      Navigator.of(context).pop();
                    },
                    borderRadius: AppTheme.asymmetricCardRadius,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activePalette.subtleBadgeBackground
                            : Colors.transparent,
                        borderRadius: AppTheme.asymmetricCardRadius,
                        border: Border.all(
                          color: isSelected
                              ? activePalette.primaryAccent.withValues(alpha: 0.4)
                              : activePalette.cardBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? activePalette.primaryAccent.withValues(alpha: 0.15)
                                  : activePalette.subtleBadgeBackground,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconData,
                              size: 18,
                              color: isSelected
                                  ? activePalette.primaryAccent
                                  : activePalette.secondaryText,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? activePalette.primaryAccent
                                        : activePalette.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  option.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: activePalette.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              PhosphorIcons.checkCircleFill,
                              size: 20,
                              color: activePalette.primaryAccent,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
