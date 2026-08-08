import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/theme/app_color_palette.dart';

class AppTheme {
  // Legacy terracotta fallback constants
  static const Color terracottaPrimary = Color(0xFFC85A30);
  static const Color terracottaLightAccent = Color(0xFFF0997B);
  static const Color gradientStartApricot = Color(0xFFF7C5B2);
  static const Color warmRustSecondaryText = Color(0xFF993C1D);
  static const Color deepEspressoPrimaryText = Color(0xFF4A1B0C);
  static const Color softParchmentBackground = Color(0xFFFAF4ED);
  static const Color pureWhiteCard = Color(0xFFFFFFFF);
  static const Color softWarmBorder = Color(0xFFE8D5C8);
  static const Color subtleBadgeBackground = Color(0xFFF9EFE7);
  static const Color desaturatedEmptyText = Color(0xFFB59A8B);
  static const Color desaturatedEmptyBadge = Color(0xFFF5EDE6);
  static const Color dashedBorderColor = Color(0xFFE5D0C0);
  static const Color navInactiveColor = Color(0xFFA08575);

  static const LinearGradient badgeGradient = LinearGradient(
    colors: [gradientStartApricot, terracottaLightAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const String serifFontFamily = 'Georgia';

  static const BorderRadius asymmetricCardRadius = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(6),
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(16),
  );

  static const BorderRadius asymmetricBadgeRadius = BorderRadius.only(
    topLeft: Radius.circular(14),
    topRight: Radius.circular(4),
    bottomLeft: Radius.circular(14),
    bottomRight: Radius.circular(14),
  );

  /// Dynamically builds ThemeData tailored to an active AppColorPalette
  static ThemeData getThemeData(AppColorPalette palette) {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: palette.background,
      fontFamily: null,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: palette.primaryAccent,
        onPrimary: Colors.white,
        secondary: palette.secondaryText,
        onSecondary: Colors.white,
        error: const Color(0xFFB00020),
        onError: Colors.white,
        surface: palette.cardBackground,
        onSurface: palette.primaryText,
        outline: palette.cardBorder,
        outlineVariant: palette.dashedBorderColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: palette.primaryText),
        titleTextStyle: TextStyle(
          fontFamily: serifFontFamily,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: palette.primaryText,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: serifFontFamily, color: palette.primaryText),
        displayMedium: TextStyle(fontFamily: serifFontFamily, color: palette.primaryText),
        headlineMedium: TextStyle(fontFamily: serifFontFamily, color: palette.primaryText),
        titleLarge: TextStyle(
          fontFamily: serifFontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: palette.primaryText,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: palette.primaryText,
        ),
        bodyLarge: TextStyle(fontSize: 15, color: palette.primaryText),
        bodyMedium: TextStyle(fontSize: 14, color: palette.secondaryText),
      ),
    );
  }

  /// Category icon mapping helper
  static IconData getCategoryIcon(String category) {
    final key = category.trim().toLowerCase();
    switch (key) {
      case 'fantasy':
        return PhosphorIcons.sparkle;
      case 'historical fiction':
        return PhosphorIcons.scroll;
      case 'mystery':
        return PhosphorIcons.magnifyingGlass;
      case 'romance':
        return PhosphorIcons.heart;
      case 'science fiction':
        return PhosphorIcons.planet;
      case 'horror':
        return PhosphorIcons.ghost;
      case 'graphic novels & comics':
        return PhosphorIcons.bookOpen;
      case 'anime & manga':
        return PhosphorIcons.lightning;
      case 'poetry':
        return PhosphorIcons.feather;
      case 'history':
        return PhosphorIcons.hourglass;
      case 'biography & memoir':
        return PhosphorIcons.identificationCard;
      case 'philosophy':
        return PhosphorIcons.brain;
      case 'self-help & personal development':
        return PhosphorIcons.compass;
      case 'school/reference':
        return PhosphorIcons.graduationCap;
      case 'classics':
        return PhosphorIcons.bookOpenText;
      case 'religion & spirituality':
        return PhosphorIcons.sun;
      case 'miscellaneous':
      default:
        return PhosphorIcons.folderSimple;
    }
  }
}
