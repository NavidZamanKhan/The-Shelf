import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Design System for The Shelf — Warm & Cozy Terracotta Aesthetics
abstract class AppTheme {
  // Brand Color Palette Tokens
  static const Color terracottaPrimary = Color(0xFFD85A30);
  static const Color terracottaLightAccent = Color(0xFFF0997B);
  static const Color warmRustSecondaryText = Color(0xFF993C1D);
  static const Color deepEspressoPrimaryText = Color(0xFF4A1B0C);
  static const Color warmCreamBackground = Color(0xFFFFF8F3);
  static const Color pureWhiteCard = Color(0xFFFFFFFF);
  static const Color softWarmBorder = Color(0xFFF0D9C9);
  static const Color subtleBadgeBackground = Color(0xFFF9EFE7);

  // Typography Family
  static const String serifFontFamily = 'Georgia';

  /// Primary Theme Data Configuration
  static ThemeData get warmTerracottaTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: warmCreamBackground,
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
        outlineVariant: Color(0xFFF7E8DE),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: warmCreamBackground,
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
      cardTheme: CardThemeData(
        color: pureWhiteCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: softWarmBorder, width: 1.0),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: pureWhiteCard,
        disabledColor: pureWhiteCard.withValues(alpha: 0.5),
        selectedColor: terracottaPrimary,
        secondarySelectedColor: terracottaPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(
          color: deepEspressoPrimaryText,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: softWarmBorder, width: 1.0),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: terracottaPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: pureWhiteCard,
        selectedItemColor: terracottaPrimary,
        unselectedItemColor: warmRustSecondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
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
