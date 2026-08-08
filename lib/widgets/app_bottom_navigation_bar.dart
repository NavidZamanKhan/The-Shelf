import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';

/// Bespoke non-Material bottom navigation footer widget with dot active indicators.
class AppBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const List<_NavItemData> _items = [
    _NavItemData('Shelf', PhosphorIcons.books),
    _NavItemData('Collections', PhosphorIcons.bookmarkSimple),
    _NavItemData('Insights', PhosphorIcons.sparkle),
    _NavItemData('Settings', PhosphorIcons.gear),
  ];

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;

    return Container(
      decoration: BoxDecoration(
        color: activePalette.cardBackground,
        border: Border(
          top: BorderSide(
            color: activePalette.cardBorder,
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final bool isSelected = selectedIndex == index;
            final color = isSelected
                ? activePalette.primaryAccent
                : activePalette.navInactiveColor;

            return Expanded(
              child: InkWell(
                onTap: () => onDestinationSelected(index),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: color,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Active 4px circular dot indicator beneath active item
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? activePalette.primaryAccent
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;

  const _NavItemData(this.label, this.icon);
}
