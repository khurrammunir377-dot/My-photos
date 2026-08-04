import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_theme.dart';

/// Singleton controller for the active app theme. AppColors reads from this
/// so every screen using AppColors.primary / AppColors.brandGradient / etc.
/// updates automatically the moment the theme changes - no need to thread
/// theme state through every widget individually.
class ThemeController {
  ThemeController._internal();
  static final ThemeController instance = ThemeController._internal();

  static const _prefKey = 'selected_theme_index';

  final ValueNotifier<AppThemeDef> notifier = ValueNotifier(AppThemes.violetSunset);

  AppThemeDef get current => notifier.value;

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_prefKey) ?? 0;
    if (index >= 0 && index < AppThemes.all.length) {
      notifier.value = AppThemes.all[index];
    }
  }

  Future<void> select(int index) async {
    if (index < 0 || index >= AppThemes.all.length) return;
    notifier.value = AppThemes.all[index];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, index);
  }

  int get currentIndex => AppThemes.all.indexOf(notifier.value);
}
