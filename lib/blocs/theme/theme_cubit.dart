import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_shelf/theme/app_color_palette.dart';

/// User's chosen brightness preference.
enum ThemeBrightness { light, dark, system }

/// Immutable state holding the active theme configuration.
class ThemeState {
  final String familyId;
  final ThemeBrightness brightness;
  final AppColorPalette resolvedPalette;

  const ThemeState({
    required this.familyId,
    required this.brightness,
    required this.resolvedPalette,
  });

  // Forward all color and style getters to resolvedPalette for seamless compatibility
  String get id => resolvedPalette.id;
  String get name => resolvedPalette.name;
  bool get isDark => resolvedPalette.isDark;
  Color get primaryAccent => resolvedPalette.primaryAccent;
  Color get lightAccent => resolvedPalette.lightAccent;
  Color get gradientStart => resolvedPalette.gradientStart;
  Color get secondaryText => resolvedPalette.secondaryText;
  Color get primaryText => resolvedPalette.primaryText;
  Color get background => resolvedPalette.background;
  Color get cardBackground => resolvedPalette.cardBackground;
  Color get cardBorder => resolvedPalette.cardBorder;
  Color get subtleBadgeBackground => resolvedPalette.subtleBadgeBackground;
  Color get desaturatedEmptyText => resolvedPalette.desaturatedEmptyText;
  Color get desaturatedEmptyBadge => resolvedPalette.desaturatedEmptyBadge;
  Color get dashedBorderColor => resolvedPalette.dashedBorderColor;
  Color get navInactiveColor => resolvedPalette.navInactiveColor;
  LinearGradient get badgeGradient => resolvedPalette.badgeGradient;

  ThemeState copyWith({
    String? familyId,
    ThemeBrightness? brightness,
    AppColorPalette? resolvedPalette,
  }) {
    return ThemeState(
      familyId: familyId ?? this.familyId,
      brightness: brightness ?? this.brightness,
      resolvedPalette: resolvedPalette ?? this.resolvedPalette,
    );
  }
}

class ThemeCubit extends Cubit<ThemeState> {
  static const String _prefFamilyKey = 'theme_family_id';
  static const String _prefBrightnessKey = 'theme_brightness';

  /// Current platform brightness (updated from outside when system mode active)
  Brightness _platformBrightness = Brightness.light;

  ThemeCubit()
      : super(ThemeState(
          familyId: 'terracotta',
          brightness: ThemeBrightness.light,
          resolvedPalette: AppColorPalette.terracottaLight,
        ));

  /// Reads persisted theme family + brightness from SharedPreferences on boot
  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFamily = prefs.getString(_prefFamilyKey) ?? 'terracotta';
      final savedBrightnessName = prefs.getString(_prefBrightnessKey) ?? 'light';
      final brightness = ThemeBrightness.values.firstWhere(
        (b) => b.name == savedBrightnessName,
        orElse: () => ThemeBrightness.light,
      );
      _emitResolved(savedFamily, brightness);
    } catch (_) {
      // Fallback to initial state
    }
  }

  /// Sets the active color family (terracotta, teal, aurora)
  Future<void> setFamily(String familyId) async {
    _emitResolved(familyId, state.brightness);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefFamilyKey, familyId);
    } catch (_) {}
  }

  /// Sets the brightness preference (light, dark, system)
  Future<void> setBrightness(ThemeBrightness brightness) async {
    _emitResolved(state.familyId, brightness);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefBrightnessKey, brightness.name);
    } catch (_) {}
  }

  /// Called when platform brightness changes (for system mode)
  void updatePlatformBrightness(Brightness platformBrightness) {
    _platformBrightness = platformBrightness;
    if (state.brightness == ThemeBrightness.system) {
      _emitResolved(state.familyId, state.brightness);
    }
  }

  /// Backward compatibility: switch palette by old-style ID
  Future<void> setPalette(String paletteId) async {
    // Extract family from palette ID (e.g. "terracotta_light" → "terracotta")
    String familyId = paletteId;
    if (paletteId.endsWith('_light') || paletteId.endsWith('_dark')) {
      familyId = paletteId.replaceAll(RegExp(r'_(light|dark)$'), '');
    }
    await setFamily(familyId);
  }

  void _emitResolved(String familyId, ThemeBrightness brightness) {
    final bool useDark;
    switch (brightness) {
      case ThemeBrightness.light:
        useDark = false;
      case ThemeBrightness.dark:
        useDark = true;
      case ThemeBrightness.system:
        useDark = _platformBrightness == Brightness.dark;
    }

    final palette = AppColorPalette.resolve(familyId, dark: useDark);
    emit(ThemeState(
      familyId: familyId,
      brightness: brightness,
      resolvedPalette: palette,
    ));
  }
}
