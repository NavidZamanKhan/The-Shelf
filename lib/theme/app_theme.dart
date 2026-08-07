import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Design System for The Shelf — Bespoke Non-Material Terracotta Aesthetics
abstract class AppTheme {
  // Brand Color Palette Tokens
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

  // Typography Family
  static const String serifFontFamily = 'Georgia';

  // Asymmetric Shape Geometry Tokens
  static const BorderRadius asymmetricCardRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomRight: Radius.circular(20),
    bottomLeft: Radius.circular(6),
  );

  static const BorderRadius asymmetricBadgeRadius = BorderRadius.only(
    topLeft: Radius.circular(14),
    topRight: Radius.circular(14),
    bottomRight: Radius.circular(14),
    bottomLeft: Radius.circular(4),
  );

  // Subtle Gradient Token for Badges
  static const LinearGradient badgeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      gradientStartApricot,
      terracottaLightAccent,
    ],
  );

  /// Primary Theme Data Configuration
  static ThemeData get warmTerracottaTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: softParchmentBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: terracottaPrimary,
        onPrimary: Colors.white,
        primaryContainer: terracottaLightAccent,
        onPrimaryContainer: deepEspressoPrimaryText,
        secondary: warmRustSecondaryText,
        onSecondary: Colors.white,
        error: Color(0xFFB00020),
        onError: Colors.white,
        surface: pureWhiteCard,
        onSurface: deepEspressoPrimaryText,
        onSurfaceVariant: warmRustSecondaryText,
        outline: softWarmBorder,
        outlineVariant: Color(0xFFF4E4D9),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: softParchmentBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: deepEspressoPrimaryText),
        titleTextStyle: TextStyle(
          fontFamily: serifFontFamily,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: deepEspressoPrimaryText,
        ),
      ),
      cardTheme: const CardThemeData(
        color: pureWhiteCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: asymmetricCardRadius,
          side: BorderSide(color: softWarmBorder, width: 1.0),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: pureWhiteCard,
        selectedItemColor: terracottaPrimary,
        unselectedItemColor: navInactiveColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontFamily: serifFontFamily,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: deepEspressoPrimaryText,
        ),
        titleLarge: TextStyle(
          fontFamily: serifFontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: deepEspressoPrimaryText,
        ),
        titleMedium: TextStyle(
          fontFamily: serifFontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: deepEspressoPrimaryText,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: deepEspressoPrimaryText,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: warmRustSecondaryText,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: warmRustSecondaryText,
        ),
      ),
    );
  }

  /// Maps each of the 17 Shelf categories to a specific Phosphor Icon
  static IconData getCategoryIcon(String category) {
    switch (category.trim().toLowerCase()) {
      case 'fantasy':
        return PhosphorIcons.magicWand;
      case 'historical fiction':
        return PhosphorIcons.castleTurret;
      case 'mystery':
        return PhosphorIcons.magnifyingGlass;
      case 'romance':
        return PhosphorIcons.heart;
      case 'science fiction':
      case 'sci-fi':
        return PhosphorIcons.rocketLaunch;
      case 'horror':
        return PhosphorIcons.ghost;
      case 'graphic novels & comics':
      case 'graphic novels':
      case 'comics':
        return PhosphorIcons.chatTeardropText;
      case 'anime & manga':
      case 'manga':
      case 'anime':
        return PhosphorIcons.sparkle;
      case 'poetry':
        return PhosphorIcons.feather;
      case 'history':
        return PhosphorIcons.hourglass;
      case 'biography & memoir':
      case 'biography':
      case 'memoir':
        return PhosphorIcons.userList;
      case 'philosophy':
        return PhosphorIcons.brain;
      case 'self-help & personal development':
      case 'self-help':
        return PhosphorIcons.trendUp;
      case 'school/reference':
      case 'reference':
      case 'school':
        return PhosphorIcons.graduationCap;
      case 'classics':
        return PhosphorIcons.columns;
      case 'religion & spirituality':
      case 'spirituality':
      case 'religion':
        return PhosphorIcons.sun;
      case 'miscellaneous':
      default:
        return PhosphorIcons.folders;
    }
  }
}
