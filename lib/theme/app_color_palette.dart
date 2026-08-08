import 'package:flutter/material.dart';

/// Immutable color palette tokens for The Shelf theme system.
class AppColorPalette {
  final String id;
  final String name;
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
    required this.name,
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

  /// Terracotta (Warm Cream) Palette - Default Theme
  static const AppColorPalette terracotta = AppColorPalette(
    id: 'terracotta',
    name: 'Terracotta (Warm Cream)',
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
      colors: [Color(0xFFF7C5B2), Color(0xFFF0997B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  /// Teal (Fresh Mint) Palette - New Theme Option
  static const AppColorPalette teal = AppColorPalette(
    id: 'teal',
    name: 'Teal (Fresh Mint)',
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
      colors: [Color(0xFFB3D8D3), Color(0xFF7FB8AF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const List<AppColorPalette> allPalettes = [
    terracotta,
    teal,
  ];

  static AppColorPalette fromId(String id) {
    return allPalettes.firstWhere(
      (p) => p.id == id,
      orElse: () => terracotta,
    );
  }
}
