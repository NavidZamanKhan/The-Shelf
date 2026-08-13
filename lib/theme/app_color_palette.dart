import 'package:flutter/material.dart';

/// Representation of a cohesive Theme Family containing both Light and Dark mode variations.
class ThemeFamily {
  final String id;
  final String name;
  final AppColorPalette light;
  final AppColorPalette dark;

  const ThemeFamily({
    required this.id,
    required this.name,
    required this.light,
    required this.dark,
  });

  AppColorPalette getPalette({required bool isDark}) => isDark ? dark : light;
}

/// Immutable color palette tokens for The Shelf theme system.
class AppColorPalette {
  final String id;
  final String familyId;
  final String name;
  final bool isDark;
  final Color primaryAccent;
  final Color lightAccent;
  final Color gradientStart;
  final Color secondaryText;
  final Color primaryText;
  final Color background;
  final Color cardBackground;
  final Color cardBorder;
  final Color subtleBadgeBackground;
  final Color desaturatedEmptyText;
  final Color desaturatedEmptyBadge;
  final Color dashedBorderColor;
  final Color navInactiveColor;
  final LinearGradient badgeGradient;

  const AppColorPalette({
    required this.id,
    required this.familyId,
    required this.name,
    this.isDark = false,
    required this.primaryAccent,
    required this.lightAccent,
    required this.gradientStart,
    required this.secondaryText,
    required this.primaryText,
    required this.background,
    required this.cardBackground,
    required this.cardBorder,
    required this.subtleBadgeBackground,
    required this.desaturatedEmptyText,
    required this.desaturatedEmptyBadge,
    required this.dashedBorderColor,
    required this.navInactiveColor,
    required this.badgeGradient,
  });

  // ---------------------------------------------------------------------------
  // 1. Sedona Sandstone — Light
  // ---------------------------------------------------------------------------
  static const AppColorPalette terracottaLight = AppColorPalette(
    id: 'terracotta_light',
    familyId: 'terracotta',
    name: 'Sedona Sandstone',
    primaryAccent: Color(0xFFC85A30),
    lightAccent: Color(0xFFF0997B),
    gradientStart: Color(0xFFF7C5B2),
    secondaryText: Color(0xFF993C1D),
    primaryText: Color(0xFF4A1B0C),
    background: Color(0xFFFAF4ED),
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE8D5C8),
    subtleBadgeBackground: Color(0xFFF9EFE7),
    desaturatedEmptyText: Color(0xFFB59A8B),
    desaturatedEmptyBadge: Color(0xFFF5EDE6),
    dashedBorderColor: Color(0xFFE5D0C0),
    navInactiveColor: Color(0xFFA08575),
    badgeGradient: LinearGradient(
      colors: [Color(0xFFC85A30), Color(0xFFC85A30)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ---------------------------------------------------------------------------
  // 1. Sedona Sandstone — Dark
  // ---------------------------------------------------------------------------
  static const AppColorPalette terracottaDark = AppColorPalette(
    id: 'terracotta_dark',
    familyId: 'terracotta',
    name: 'Sedona Sandstone',
    isDark: true,
    primaryAccent: Color(0xFFD97349),
    lightAccent: Color(0xFFE28E69),
    gradientStart: Color(0xFF4A2617),
    secondaryText: Color(0xFFA89385),
    primaryText: Color(0xFFEAE0D7),
    background: Color(0xFF171412),
    cardBackground: Color(0xFF211D1A),
    cardBorder: Color(0xFF352E28),
    subtleBadgeBackground: Color(0xFF2A241F),
    desaturatedEmptyText: Color(0xFF6E5D52),
    desaturatedEmptyBadge: Color(0xFF26201C),
    dashedBorderColor: Color(0xFF38302A),
    navInactiveColor: Color(0xFF7D6C61),
    badgeGradient: LinearGradient(
      colors: [Color(0xFFD97349), Color(0xFFD97349)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ---------------------------------------------------------------------------
  // 2. Nordic Fjord — Light
  // ---------------------------------------------------------------------------
  static const AppColorPalette tealLight = AppColorPalette(
    id: 'teal_light',
    familyId: 'teal',
    name: 'Nordic Fjord',
    primaryAccent: Color(0xFF4A9088),
    lightAccent: Color(0xFF7FB8AF),
    gradientStart: Color(0xFFB3D8D3),
    secondaryText: Color(0xFF4D766F),
    primaryText: Color(0xFF163430),
    background: Color(0xFFF1F7F6),
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFD3E5E2),
    subtleBadgeBackground: Color(0xFFE4F0EE),
    desaturatedEmptyText: Color(0xFF8AAEA8),
    desaturatedEmptyBadge: Color(0xFFE6F0EE),
    dashedBorderColor: Color(0xFFC2DDD8),
    navInactiveColor: Color(0xFF7A9A95),
    badgeGradient: LinearGradient(
      colors: [Color(0xFF4A9088), Color(0xFF4A9088)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ---------------------------------------------------------------------------
  // 2. Nordic Fjord — Dark
  // ---------------------------------------------------------------------------
  static const AppColorPalette tealDark = AppColorPalette(
    id: 'teal_dark',
    familyId: 'teal',
    name: 'Nordic Fjord',
    isDark: true,
    primaryAccent: Color(0xFF4CA89C),
    lightAccent: Color(0xFF6DBBB0),
    gradientStart: Color(0xFF173934),
    secondaryText: Color(0xFF8BABA5),
    primaryText: Color(0xFFE1ECE9),
    background: Color(0xFF111616),
    cardBackground: Color(0xFF1A2222),
    cardBorder: Color(0xFF283534),
    subtleBadgeBackground: Color(0xFF222E2D),
    desaturatedEmptyText: Color(0xFF57726D),
    desaturatedEmptyBadge: Color(0xFF1E2827),
    dashedBorderColor: Color(0xFF2B3B39),
    navInactiveColor: Color(0xFF6F8E88),
    badgeGradient: LinearGradient(
      colors: [Color(0xFF4CA89C), Color(0xFF4CA89C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ---------------------------------------------------------------------------
  // 3. Reynisfjara — Light
  // ---------------------------------------------------------------------------
  static const AppColorPalette moonbowLight = AppColorPalette(
    id: 'moonbow_light',
    familyId: 'moonbow',
    name: 'Reynisfjara',
    primaryAccent: Color(0xFF1C1C1E),
    lightAccent: Color(0xFF8E8E93),
    gradientStart: Color(0xFF1C1C1E),
    secondaryText: Color(0xFF6C6C70),
    primaryText: Color(0xFF1C1C1E),
    background: Color(0xFFF2F2F7),
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE5E5EA),
    subtleBadgeBackground: Color(0xFFEBEBF0),
    desaturatedEmptyText: Color(0xFFAEAEC0),
    desaturatedEmptyBadge: Color(0xFFF2F2F7),
    dashedBorderColor: Color(0xFFD1D1D6),
    navInactiveColor: Color(0xFF8E8E93),
    badgeGradient: LinearGradient(
      colors: [Color(0xFF1C1C1E), Color(0xFF1C1C1E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ---------------------------------------------------------------------------
  // 3. Reynisfjara — Dark
  // ---------------------------------------------------------------------------
  static const AppColorPalette moonbowDark = AppColorPalette(
    id: 'moonbow_dark',
    familyId: 'moonbow',
    name: 'Reynisfjara',
    isDark: true,
    primaryAccent: Color(0xFFE5E5EA),
    lightAccent: Color(0xFFA1A1A6),
    gradientStart: Color(0xFF2C2C2E),
    secondaryText: Color(0xFF8E8E93),
    primaryText: Color(0xFFFFFFFF),
    background: Color(0xFF0D0D0E),
    cardBackground: Color(0xFF1C1C1E),
    cardBorder: Color(0xFF2C2C2E),
    subtleBadgeBackground: Color(0xFF242426),
    desaturatedEmptyText: Color(0xFF636366),
    desaturatedEmptyBadge: Color(0xFF1C1C1E),
    dashedBorderColor: Color(0xFF3A3A3C),
    navInactiveColor: Color(0xFF636366),
    badgeGradient: LinearGradient(
      colors: [Color(0xFF2C2C2E), Color(0xFF2C2C2E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ---------------------------------------------------------------------------
  // 4. Sakura Hanafubuki — Light
  // ---------------------------------------------------------------------------
  static const AppColorPalette sakuraLight = AppColorPalette(
    id: 'sakura_light',
    familyId: 'sakura',
    name: 'Sakura Hanafubuki',
    primaryAccent: Color(0xFFE27396),
    lightAccent: Color(0xFFEA9AB2),
    gradientStart: Color(0xFFE27396),
    secondaryText: Color(0xFF7D5A68),
    primaryText: Color(0xFF332029),
    background: Color(0xFFFAF5F7),
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFF2DFE6),
    subtleBadgeBackground: Color(0xFFF9ECF1),
    desaturatedEmptyText: Color(0xFFB89CA7),
    desaturatedEmptyBadge: Color(0xFFF5E8EE),
    dashedBorderColor: Color(0xFFE8D3DC),
    navInactiveColor: Color(0xFF9E7E8B),
    badgeGradient: LinearGradient(
      colors: [Color(0xFFE27396), Color(0xFFE27396)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ---------------------------------------------------------------------------
  // 4. Sakura Hanafubuki — Dark
  // ---------------------------------------------------------------------------
  static const AppColorPalette sakuraDark = AppColorPalette(
    id: 'sakura_dark',
    familyId: 'sakura',
    name: 'Sakura Hanafubuki',
    isDark: true,
    primaryAccent: Color(0xFFF095B0),
    lightAccent: Color(0xFFE27396),
    gradientStart: Color(0xFFF095B0),
    secondaryText: Color(0xFFA8949E),
    primaryText: Color(0xFFF7EFF2),
    background: Color(0xFF141013),
    cardBackground: Color(0xFF1F1A1E),
    cardBorder: Color(0xFF332830),
    subtleBadgeBackground: Color(0xFF282026),
    desaturatedEmptyText: Color(0xFF6E5964),
    desaturatedEmptyBadge: Color(0xFF211B1F),
    dashedBorderColor: Color(0xFF382B34),
    navInactiveColor: Color(0xFF7E6975),
    badgeGradient: LinearGradient(
      colors: [Color(0xFFF095B0), Color(0xFFF095B0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ---------------------------------------------------------------------------
  // 5. Kyoto Moss — Light
  // ---------------------------------------------------------------------------
  static const AppColorPalette kyotoMossLight = AppColorPalette(
    id: 'kyoto_moss_light',
    familyId: 'kyoto_moss',
    name: 'Kyoto Moss',
    primaryAccent: Color(0xFF3B6E4C),
    lightAccent: Color(0xFF6B9B78),
    gradientStart: Color(0xFF3B6E4C),
    secondaryText: Color(0xFF4E6B56),
    primaryText: Color(0xFF1B2E21),
    background: Color(0xFFF3F7F4),
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFD6E3D9),
    subtleBadgeBackground: Color(0xFFE8F1EB),
    desaturatedEmptyText: Color(0xFF8DA895),
    desaturatedEmptyBadge: Color(0xFFEAF0EC),
    dashedBorderColor: Color(0xFFC7D9CB),
    navInactiveColor: Color(0xFF7A9682),
    badgeGradient: LinearGradient(
      colors: [Color(0xFF3B6E4C), Color(0xFF3B6E4C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ---------------------------------------------------------------------------
  // 5. Kyoto Moss — Dark
  // ---------------------------------------------------------------------------
  static const AppColorPalette kyotoMossDark = AppColorPalette(
    id: 'kyoto_moss_dark',
    familyId: 'kyoto_moss',
    name: 'Kyoto Moss',
    isDark: true,
    primaryAccent: Color(0xFF5E9C72),
    lightAccent: Color(0xFF7CB890),
    gradientStart: Color(0xFF5E9C72),
    secondaryText: Color(0xFF8FA896),
    primaryText: Color(0xFFE7F0E9),
    background: Color(0xFF101612),
    cardBackground: Color(0xFF18221B),
    cardBorder: Color(0xFF27382D),
    subtleBadgeBackground: Color(0xFF1F2E24),
    desaturatedEmptyText: Color(0xFF55705E),
    desaturatedEmptyBadge: Color(0xFF1A241D),
    dashedBorderColor: Color(0xFF2C3E33),
    navInactiveColor: Color(0xFF6B8674),
    badgeGradient: LinearGradient(
      colors: [Color(0xFF5E9C72), Color(0xFF5E9C72)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ---------------------------------------------------------------------------
  // 6. Wisteria Twilight — Light
  // ---------------------------------------------------------------------------
  static const AppColorPalette wisteriaLight = AppColorPalette(
    id: 'wisteria_light',
    familyId: 'wisteria',
    name: 'Wisteria Twilight',
    primaryAccent: Color(0xFF6A4C9C),
    lightAccent: Color(0xFF9B82C4),
    gradientStart: Color(0xFF6A4C9C),
    secondaryText: Color(0xFF614E7E),
    primaryText: Color(0xFF221736),
    background: Color(0xFFF7F5FB),
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE2DCEE),
    subtleBadgeBackground: Color(0xFFEFEAF7),
    desaturatedEmptyText: Color(0xFF9D91B5),
    desaturatedEmptyBadge: Color(0xFFECE7F4),
    dashedBorderColor: Color(0xFFD6CEE5),
    navInactiveColor: Color(0xFF897B9F),
    badgeGradient: LinearGradient(
      colors: [Color(0xFF6A4C9C), Color(0xFF6A4C9C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ---------------------------------------------------------------------------
  // 6. Wisteria Twilight — Dark
  // ---------------------------------------------------------------------------
  static const AppColorPalette wisteriaDark = AppColorPalette(
    id: 'wisteria_dark',
    familyId: 'wisteria',
    name: 'Wisteria Twilight',
    isDark: true,
    primaryAccent: Color(0xFF9978D4),
    lightAccent: Color(0xFFB89FE4),
    gradientStart: Color(0xFF9978D4),
    secondaryText: Color(0xFFA597BF),
    primaryText: Color(0xFFEFEBF6),
    background: Color(0xFF131018),
    cardBackground: Color(0xFF1D1826),
    cardBorder: Color(0xFF2E263D),
    subtleBadgeBackground: Color(0xFF261E33),
    desaturatedEmptyText: Color(0xFF66597D),
    desaturatedEmptyBadge: Color(0xFF1E1828),
    dashedBorderColor: Color(0xFF362C47),
    navInactiveColor: Color(0xFF7A6D91),
    badgeGradient: LinearGradient(
      colors: [Color(0xFF9978D4), Color(0xFF9978D4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ---------------------------------------------------------------------------
  // Theme Families
  // ---------------------------------------------------------------------------

  /// The list of curated theme families
  static const List<ThemeFamily> families = [
    ThemeFamily(
      id: 'terracotta',
      name: 'Sedona Sandstone',
      light: terracottaLight,
      dark: terracottaDark,
    ),
    ThemeFamily(
      id: 'teal',
      name: 'Nordic Fjord',
      light: tealLight,
      dark: tealDark,
    ),
    ThemeFamily(
      id: 'moonbow',
      name: 'Reynisfjara',
      light: moonbowLight,
      dark: moonbowDark,
    ),
    ThemeFamily(
      id: 'sakura',
      name: 'Sakura Hanafubuki',
      light: sakuraLight,
      dark: sakuraDark,
    ),
    ThemeFamily(
      id: 'kyoto_moss',
      name: 'Kyoto Moss',
      light: kyotoMossLight,
      dark: kyotoMossDark,
    ),
    ThemeFamily(
      id: 'wisteria',
      name: 'Wisteria Twilight',
      light: wisteriaLight,
      dark: wisteriaDark,
    ),
  ];

  /// Ordered list of family IDs
  static const List<String> familyIds = [
    'terracotta',
    'teal',
    'moonbow',
    'sakura',
    'kyoto_moss',
    'wisteria',
  ];

  /// Light palette for each family
  static const Map<String, AppColorPalette> lightPalettes = {
    'terracotta': terracottaLight,
    'teal': tealLight,
    'moonbow': moonbowLight,
    'sakura': sakuraLight,
    'kyoto_moss': kyotoMossLight,
    'wisteria': wisteriaLight,
  };

  /// Dark palette for each family
  static const Map<String, AppColorPalette> darkPalettes = {
    'terracotta': terracottaDark,
    'teal': tealDark,
    'moonbow': moonbowDark,
    'sakura': sakuraDark,
    'kyoto_moss': kyotoMossDark,
    'wisteria': wisteriaDark,
  };

  /// All palettes (flat list for backward compatibility)
  static const List<AppColorPalette> allPalettes = [
    terracottaLight,
    terracottaDark,
    tealLight,
    tealDark,
    moonbowLight,
    moonbowDark,
    sakuraLight,
    sakuraDark,
    kyotoMossLight,
    kyotoMossDark,
    wisteriaLight,
    wisteriaDark,
  ];

  /// Resolve a palette by family + dark flag (with fallback for previous IDs)
  static AppColorPalette resolve(String familyId, {required bool dark}) {
    final effectiveId = (familyId == 'aurora') ? 'moonbow' : familyId;
    if (dark) {
      return darkPalettes[effectiveId] ?? terracottaDark;
    }
    return lightPalettes[effectiveId] ?? terracottaLight;
  }

  /// Backward-compatible lookup by ID
  static AppColorPalette fromId(String id) {
    if (id.startsWith('aurora')) {
      return id.contains('dark') ? moonbowDark : moonbowLight;
    }
    return allPalettes.firstWhere(
      (p) => p.id == id,
      orElse: () => terracottaLight,
    );
  }

  /// Legacy aliases for backward compatibility
  static const AppColorPalette terracotta = terracottaLight;
  static const AppColorPalette teal = tealLight;
  static const AppColorPalette moonbow = moonbowLight;
  static const AppColorPalette sakura = sakuraLight;
  static const AppColorPalette kyotoMoss = kyotoMossLight;
  static const AppColorPalette wisteria = wisteriaLight;
}
