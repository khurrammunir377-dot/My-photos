import 'package:flutter/material.dart';
import '../../models/app_theme.dart';
import '../../services/theme_controller.dart';
import '../../utils/constants.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('App Theme', style: TextStyle(color: AppColors.textDark)),
      ),
      body: ValueListenableBuilder<AppThemeDef>(
        valueListenable: ThemeController.instance.notifier,
        builder: (context, currentTheme, _) {
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
            ),
            itemCount: AppThemes.all.length,
            itemBuilder: (context, index) {
              final theme = AppThemes.all[index];
              final selected = theme.name == currentTheme.name;
              return GestureDetector(
                onTap: () => ThemeController.instance.select(index),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: theme.gradient,
                    borderRadius: BorderRadius.circular(20),
                    border: selected ? Border.all(color: Colors.white, width: 3) : null,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primary.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          theme.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                      if (selected)
                        const Align(
                          alignment: Alignment.topRight,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.check, size: 16, color: AppColors.textDark),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
