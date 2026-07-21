import 'package:flutter/material.dart';

/// App-wide constants
class AppConstants {
  static const String appName = "My Photo Organizer";
  static const String albumPrefix = "MyPhotoOrganizer"; // e.g. MyPhotoOrganizer_ProjectSite
  static const int freeTierFolderLimit = 1;

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
  static const Color primary = Color(0xFF4FC3F7);   // brand blue
  static const Color accent = Color(0xFF2ECC71);    // green accent
  static const Color background = Color(0xFFF7F8FA);
  static const Color cardBackground = Colors.white;
  static const Color textDark = Color(0xFF1E2A38);
  static const Color textMuted = Color(0xFF7C8A99);
  static const Color error = Color(0xFFE74C3C);
  static const Color proGold = Color(0xFFFFB300);
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );
  static const TextStyle subheading = TextStyle(
    fontSize: 16,
    color: AppColors.textMuted,
  );
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
