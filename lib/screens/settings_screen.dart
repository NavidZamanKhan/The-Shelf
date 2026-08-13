import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/screens/classifier_debug_screen.dart';
import 'package:the_shelf/screens/home_screen.dart';
import 'package:the_shelf/services/app_settings_service.dart';
import 'package:the_shelf/theme/app_color_palette.dart';
import 'package:the_shelf/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _instantAutoFile = false;
  Set<String> _hiddenShelves = {};
  int _storageBytes = 0;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final instant = await AppSettingsService.instance.getInstantAutoFile();
      final hidden = await AppSettingsService.instance.getHiddenShelves();
      final bytes = await AppSettingsService.instance.getStorageUsageBytes();

      if (mounted) {
        setState(() {
          _instantAutoFile = instant;
          _hiddenShelves = hidden;
          _storageBytes = bytes;
          _isLoadingSettings = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSettings = false);
      }
    }
  }

  Future<void> _clearCache() async {
    await AppSettingsService.instance.clearLocalCache();
    final updatedBytes = await AppSettingsService.instance.getStorageUsageBytes();
    if (mounted) {
      setState(() {
        _storageBytes = updatedBytes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Temporary cache cleared successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showHideShelvesModal(BuildContext context, AppColorPalette activePalette) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: activePalette.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Text(
                        'Hide / Unhide Shelves',
                        style: TextStyle(
                          fontFamily: AppTheme.serifFontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: activePalette.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Uncheck categories to hide them from your main home screen.',
                        style: TextStyle(
                          fontSize: 13,
                          color: activePalette.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: all17Categories.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: activePalette.cardBorder.withValues(alpha: 0.5),
                          ),
                          itemBuilder: (context, index) {
                            final cat = all17Categories[index];
                            final bool isHidden = _hiddenShelves.contains(cat);
                            final iconData = AppTheme.getCategoryIcon(cat);

                            return CheckboxListTile(
                              value: !isHidden,
                              activeColor: activePalette.primaryAccent,
                              title: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isHidden
                                      ? activePalette.secondaryText
                                      : activePalette.primaryText,
                                ),
                              ),
                              secondary: Icon(
                                iconData,
                                color: isHidden
                                    ? activePalette.desaturatedEmptyText
                                    : activePalette.primaryAccent,
                                size: 20,
                              ),
                              onChanged: (bool? visible) {
                                setModalState(() {
                                  if (visible == true) {
                                    _hiddenShelves.remove(cat);
                                  } else {
                                    _hiddenShelves.add(cat);
                                  }
                                });
                                setState(() {});
                                AppSettingsService.instance.setHiddenShelves(_hiddenShelves);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final activePalette = themeState.resolvedPalette;
        return Scaffold(
          backgroundColor: activePalette.background,
          appBar: AppBar(
            backgroundColor: activePalette.background,
            elevation: 0,
            title: Text(
              'Settings',
              style: TextStyle(
                fontFamily: AppTheme.serifFontFamily,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: activePalette.primaryText,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- Section 1: Library & Smart Import ---
              Text(
                'LIBRARY & SMART IMPORT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: activePalette.secondaryText,
                ),
              ),
              const SizedBox(height: 12),

              // Item 1: Instant Auto-Filing Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: activePalette.cardBackground,
                  borderRadius: AppTheme.asymmetricCardRadius,
                  border: Border.all(color: activePalette.cardBorder, width: 1.0),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: activePalette.badgeGradient,
                        borderRadius: AppTheme.asymmetricBadgeRadius,
                        border: Border.all(
                          color: activePalette.cardBorder,
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          PhosphorIcons.lightningBold,
                          color: activePalette.isDark
                              ? activePalette.primaryText
                              : Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instant Auto-Filing',
                            style: TextStyle(
                              fontFamily: AppTheme.serifFontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: activePalette.primaryText,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Automatically file imports without asking for confirmation',
                            style: TextStyle(
                              fontSize: 12,
                              color: activePalette.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _instantAutoFile,
                      activeTrackColor: activePalette.primaryAccent,
                      onChanged: (val) {
                        setState(() => _instantAutoFile = val);
                        AppSettingsService.instance.setInstantAutoFile(val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Item 2: Storage & Local Cache Usage Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: activePalette.cardBackground,
                  borderRadius: AppTheme.asymmetricCardRadius,
                  border: Border.all(color: activePalette.cardBorder, width: 1.0),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: activePalette.badgeGradient,
                        borderRadius: AppTheme.asymmetricBadgeRadius,
                        border: Border.all(
                          color: activePalette.cardBorder,
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          PhosphorIcons.hardDrivesBold,
                          color: activePalette.isDark
                              ? activePalette.primaryText
                              : Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Storage & Local Cache',
                            style: TextStyle(
                              fontFamily: AppTheme.serifFontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: activePalette.primaryText,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _isLoadingSettings
                                ? 'Calculating storage usage...'
                                : '${AppSettingsService.formatBytes(_storageBytes)} used by imported documents & media',
                            style: TextStyle(
                              fontSize: 12,
                              color: activePalette.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _clearCache,
                      child: Text(
                        'Clear Cache',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: activePalette.primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Item 3: Hide / Unhide Shelves Selector
              GestureDetector(
                onTap: () => _showHideShelvesModal(context, activePalette),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: activePalette.cardBackground,
                    borderRadius: AppTheme.asymmetricCardRadius,
                    border: Border.all(color: activePalette.cardBorder, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: activePalette.badgeGradient,
                          borderRadius: AppTheme.asymmetricBadgeRadius,
                          border: Border.all(
                            color: activePalette.cardBorder,
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            PhosphorIcons.stackBold,
                            color: activePalette.isDark
                              ? activePalette.primaryText
                              : Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hide / Unhide Shelves',
                              style: TextStyle(
                                fontFamily: AppTheme.serifFontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: activePalette.primaryText,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _hiddenShelves.isEmpty
                                  ? 'All 21 categories visible on home screen'
                                  : '${_hiddenShelves.length} ${_hiddenShelves.length == 1 ? 'category' : 'categories'} hidden from home screen',
                              style: TextStyle(
                                fontSize: 12,
                                color: activePalette.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        PhosphorIcons.caretRightBold,
                        size: 16,
                        color: activePalette.secondaryText,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- Section 2: Appearance & Theme ---
              Text(
                'APPEARANCE & THEME',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: activePalette.secondaryText,
                ),
              ),
              const SizedBox(height: 12),

              // Theme Mode Selector (Light / Dark / System)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: activePalette.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: activePalette.cardBorder),
                ),
                child: Row(
                  children: [
                    _buildThemeModeOption(
                      context: context,
                      activePalette: activePalette,
                      currentBrightness: themeState.brightness,
                      mode: ThemeBrightness.light,
                      label: 'Light',
                      icon: PhosphorIcons.sunBold,
                    ),
                    _buildThemeModeOption(
                      context: context,
                      activePalette: activePalette,
                      currentBrightness: themeState.brightness,
                      mode: ThemeBrightness.dark,
                      label: 'Dark',
                      icon: PhosphorIcons.moonBold,
                    ),
                    _buildThemeModeOption(
                      context: context,
                      activePalette: activePalette,
                      currentBrightness: themeState.brightness,
                      mode: ThemeBrightness.system,
                      label: 'System',
                      icon: PhosphorIcons.gearSixBold,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Theme Family Cards (Terracotta, Teal, Aurora)
              Column(
                children: AppColorPalette.families.map((family) {
                  final bool isSelected = themeState.familyId == family.id;
                  final palette = family.getPalette(isDark: activePalette.isDark);

                  return GestureDetector(
                    onTap: () {
                      context.read<ThemeCubit>().setFamily(family.id);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: palette.cardBackground,
                        borderRadius: AppTheme.asymmetricCardRadius,
                        border: Border.all(
                          color: isSelected
                              ? activePalette.primaryAccent
                              : palette.cardBorder,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Color Swatches Preview
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: palette.badgeGradient,
                              borderRadius: AppTheme.asymmetricBadgeRadius,
                            ),
                            child: Center(
                                child: Icon(
                                  PhosphorIcons.palette,
                                  color: palette.isDark
                                      ? palette.primaryText
                                      : Colors.white,
                                  size: 24,
                                ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Palette Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  family.name,
                                  style: TextStyle(
                                    fontFamily: AppTheme.serifFontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: palette.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildColorDot(palette.primaryAccent),
                                    const SizedBox(width: 6),
                                    _buildColorDot(palette.background),
                                    const SizedBox(width: 6),
                                    _buildColorDot(palette.primaryText),
                                    const SizedBox(width: 8),
                                    Text(
                                      isSelected ? 'Active' : 'Tap to apply',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected
                                            ? activePalette.primaryAccent
                                            : palette.secondaryText,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Checkmark Status Badge
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: activePalette.primaryAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                PhosphorIcons.checkBold,
                                color: activePalette.isDark
                                    ? activePalette.primaryText
                                    : Colors.white,
                                size: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // --- Section 3: About ---
              Text(
                'ABOUT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: activePalette.secondaryText,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: activePalette.cardBackground,
                  borderRadius: AppTheme.asymmetricCardRadius,
                  border: Border.all(color: activePalette.cardBorder, width: 1.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIcons.books,
                      size: 24,
                      color: activePalette.primaryAccent,
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'The Shelf',
                          style: TextStyle(
                            fontFamily: AppTheme.serifFontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: activePalette.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Version 1.0.0 • Personal Library Organizer',
                          style: TextStyle(
                            fontSize: 12,
                            color: activePalette.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Developer Tools Section (Gated in kDebugMode)
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                Text(
                  'DEVELOPER TOOLS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: activePalette.secondaryText,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClassifierDebugScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: activePalette.cardBackground,
                      borderRadius: AppTheme.asymmetricCardRadius,
                      border: Border.all(color: activePalette.cardBorder, width: 1.0),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: activePalette.badgeGradient,
                            borderRadius: AppTheme.asymmetricBadgeRadius,
                          ),
                          child: Center(
                            child: Icon(
                              PhosphorIcons.bug,
                              color: activePalette.primaryText,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Classifier Verification Debugger',
                                style: TextStyle(
                                  fontFamily: AppTheme.serifFontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: activePalette.primaryText,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Test on-device text classifier predictions',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: activePalette.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          PhosphorIcons.caretRightBold,
                          size: 16,
                          color: activePalette.secondaryText,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeModeOption({
    required BuildContext context,
    required AppColorPalette activePalette,
    required ThemeBrightness currentBrightness,
    required ThemeBrightness mode,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = currentBrightness == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<ThemeCubit>().setBrightness(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? activePalette.primaryAccent
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? (activePalette.isDark ? activePalette.primaryText : Colors.white)
                    : activePalette.secondaryText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (activePalette.isDark ? activePalette.primaryText : Colors.white)
                      : activePalette.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorDot(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12, width: 1),
      ),
    );
  }
}
