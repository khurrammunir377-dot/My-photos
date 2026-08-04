import 'package:flutter/material.dart';

class AppThemeDef {
  final String name;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final List<Color> accentPalette;

  const AppThemeDef({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.accentPalette,
  });

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, secondary, tertiary],
      );
}

/// 10 selectable themes. Each defines a 3-stop gradient (used across headers,
/// buttons, and active states) plus a small accent palette for folder/person
/// card icons.
class AppThemes {
  static const violetSunset = AppThemeDef(
    name: 'Violet Sunset',
    primary: Color(0xFF7C4DFF),
    secondary: Color(0xFFFF4D9D),
    tertiary: Color(0xFFFF8A3D),
    accentPalette: [Color(0xFF7C4DFF), Color(0xFFFF4D9D), Color(0xFFFF8A3D), Color(0xFF2ECC71), Color(0xFF29B6F6), Color(0xFFFFC107)],
  );

  static const oceanBlue = AppThemeDef(
    name: 'Ocean Blue',
    primary: Color(0xFF0072FF),
    secondary: Color(0xFF00C6FF),
    tertiary: Color(0xFF43E8D8),
    accentPalette: [Color(0xFF0072FF), Color(0xFF00C6FF), Color(0xFF43E8D8), Color(0xFF7C4DFF), Color(0xFFFFC107), Color(0xFFFF6E6E)],
  );

  static const forestGreen = AppThemeDef(
    name: 'Forest Green',
    primary: Color(0xFF11998E),
    secondary: Color(0xFF38EF7D),
    tertiary: Color(0xFFA8E063),
    accentPalette: [Color(0xFF11998E), Color(0xFF38EF7D), Color(0xFFA8E063), Color(0xFF29B6F6), Color(0xFFFFC107), Color(0xFFFF6E9D)],
  );

  static const midnightDark = AppThemeDef(
    name: 'Midnight',
    primary: Color(0xFF232526),
    secondary: Color(0xFF485563),
    tertiary: Color(0xFF7C4DFF),
    accentPalette: [Color(0xFF7C4DFF), Color(0xFF29B6F6), Color(0xFFFF4D9D), Color(0xFF43E8D8), Color(0xFFFFC107), Color(0xFF66BB6A)],
  );

  static const roseGold = AppThemeDef(
    name: 'Rose Gold',
    primary: Color(0xFFEF9A9A),
    secondary: Color(0xFFF48FB1),
    tertiary: Color(0xFFFFCC80),
    accentPalette: [Color(0xFFEF9A9A), Color(0xFFF48FB1), Color(0xFFFFCC80), Color(0xFFCE93D8), Color(0xFF80CBC4), Color(0xFFFFF59D)],
  );

  static const sunnyYellow = AppThemeDef(
    name: 'Sunny',
    primary: Color(0xFFF7971E),
    secondary: Color(0xFFFFD200),
    tertiary: Color(0xFFFF6E6E),
    accentPalette: [Color(0xFFF7971E), Color(0xFFFFD200), Color(0xFFFF6E6E), Color(0xFF29B6F6), Color(0xFF66BB6A), Color(0xFF7C4DFF)],
  );

  static const berryPurple = AppThemeDef(
    name: 'Berry',
    primary: Color(0xFF8E2DE2),
    secondary: Color(0xFF4A00E0),
    tertiary: Color(0xFFFF4D9D),
    accentPalette: [Color(0xFF8E2DE2), Color(0xFF4A00E0), Color(0xFFFF4D9D), Color(0xFF29B6F6), Color(0xFFFFC107), Color(0xFF66BB6A)],
  );

  static const coralReef = AppThemeDef(
    name: 'Coral Reef',
    primary: Color(0xFFFF5F6D),
    secondary: Color(0xFFFFC371),
    tertiary: Color(0xFF43E8D8),
    accentPalette: [Color(0xFFFF5F6D), Color(0xFFFFC371), Color(0xFF43E8D8), Color(0xFF7C4DFF), Color(0xFF29B6F6), Color(0xFFFFF176)],
  );

  static const emerald = AppThemeDef(
    name: 'Emerald',
    primary: Color(0xFF0BA360), // no leading space
    secondary: Color(0xFF3CBA92),
    tertiary: Color(0xFFA1FFCE),
    accentPalette: [Color(0xFF0BA360), Color(0xFF3CBA92), Color(0xFFA1FFCE), Color(0xFF7C4DFF), Color(0xFFFF6E9D), Color(0xFFFFC107)],
  );

  static const classicBlue = AppThemeDef(
    name: 'Classic Blue',
    primary: Color(0xFF4FC3F7),
    secondary: Color(0xFF29B6F6),
    tertiary: Color(0xFF0288D1),
    accentPalette: [Color(0xFF4FC3F7), Color(0xFF29B6F6), Color(0xFF0288D1), Color(0xFFFF6E9D), Color(0xFFFFC107), Color(0xFF66BB6A)],
  );

  static const List<AppThemeDef> all = [
    violetSunset,
    oceanBlue,
    forestGreen,
    midnightDark,
    roseGold,
    sunnyYellow,
    berryPurple,
    coralReef,
    emerald,
    classicBlue,
  ];
}
