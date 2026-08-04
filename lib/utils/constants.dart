import 'package:flutter/material.dart';
import '../services/theme_controller.dart';

/// App-wide constants
class AppConstants {
  static const String appName = "My Photo Organizer";
  static const String albumPrefix = "MyPhotoOrganizer"; // e.g. MyPhotoOrganizer_ProjectSite
  static const int freeTierFolderLimit = 1;

  // Master switch for Firebase (Auth + Firestore). Set to true once you've:
  // 1) created a Firebase project, 2) added google-services.json to android/app/,
  // 3) re-added the google-services Gradle plugin (see README "Re-enabling Firebase").
  // While false, the app uses a simple local-only login instead, so you can test
  // everything else (camera, folders, filters, gallery, auto-organize) right away.
  static const bool kFirebaseEnabled = false;

  // SharedPreferences keys
  static const String prefIsPro = "is_pro_user";
  static const String prefUserId = "user_id";

  // Emails allowed to open the Admin Dashboard. Add your own email(s) here
  // before building - this is a simple client-side gate for phase 1;
  // for stronger protection, also add a matching check in Firestore security rules
  // (e.g. only these UIDs can read the full `users` collection).
  static const List<String> adminEmails = [
    "admin@uudsaero.com", // TODO: replace with your real admin email
  ];
}

class AppColors {
  // Dynamic - reads the currently selected theme (see ThemeController /
  // AppThemes). Every screen using AppColors.primary / brandGradient /
  // accentFor(...) updates automatically when the user changes theme.
  static Color get primary => ThemeController.instance.current.primary;
  static Color get secondary => ThemeController.instance.current.secondary;
  static List<Color> get accentPalette => ThemeController.instance.current.accentPalette;
  static LinearGradient get brandGradient => ThemeController.instance.current.gradient;

  // Fixed neutrals - stay the same across all themes for readability/contrast.
  static const Color accent = Color(0xFF2ECC71);
  static const Color background = Color(0xFFF8F7FC);
  static const Color cardBackground = Colors.white;
  static const Color textDark = Color(0xFF1B1530);
  static const Color textMuted = Color(0xFF8B87A3);
  static const Color error = Color(0xFFE74C3C);
  static const Color proGold = Color(0xFFFFB300);

  static Color accentFor(int index) => accentPalette[index % accentPalette.length];
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    letterSpacing: -0.3,
  );
  static const TextStyle subheading = TextStyle(
    fontSize: 15,
    color: AppColors.textMuted,
    height: 1.4,
  );
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}
