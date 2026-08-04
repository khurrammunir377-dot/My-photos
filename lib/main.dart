import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'models/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/theme_controller.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConstants.kFirebaseEnabled) {
    await Firebase.initializeApp();
  }
  await ThemeController.instance.loadSaved();
  runApp(const MyPhotoOrganizerApp());
}

class MyPhotoOrganizerApp extends StatelessWidget {
  const MyPhotoOrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeDef>(
      valueListenable: ThemeController.instance.notifier,
      builder: (context, theme, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: theme.primary,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.primary,
              primary: theme.primary,
            ),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
