import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/theme/app_theme.dart';

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
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.pureWhiteCard,
        border: Border(
          top: BorderSide(
            color: AppTheme.softWarmBorder,
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final bool isSelected = selectedIndex == index;
            final color = isSelected ? AppTheme.terracottaPrimary : AppTheme.navInactiveColor;

            return InkWell(
              onTap: () => onDestinationSelected(index),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: SizedBox(
                width: 72,
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
                    ),
                    const SizedBox(height: 4),

                    // Active 4px circular dot indicator beneath active item
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppTheme.terracottaPrimary : Colors.transparent,
                      ),
                    ),
                  ],
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
