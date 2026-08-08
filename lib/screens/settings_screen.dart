import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/screens/classifier_debug_screen.dart';
import 'package:the_shelf/theme/app_color_palette.dart';
import 'package:the_shelf/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppColorPalette>(
      builder: (context, activePalette) {
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
              // Appearance Section Header
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

              // Theme Swatch Selector Cards
              Column(
                children: AppColorPalette.allPalettes.map((palette) {
                  final bool isSelected = activePalette.id == palette.id;

                  return GestureDetector(
                    onTap: () {
                      context.read<ThemeCubit>().setPalette(palette.id);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: palette.cardBackground,
                        borderRadius: AppTheme.asymmetricCardRadius,
                        border: Border.all(
                          color: isSelected
                              ? palette.primaryAccent
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
                                color: palette.primaryText,
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
                                  palette.name,
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
                                            ? palette.primaryAccent
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
                                color: palette.primaryAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                PhosphorIcons.checkBold,
                                color: Colors.white,
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

              // About Section Header
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
