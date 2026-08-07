import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';
import '../services/local_session_service.dart';
import '../utils/constants.dart';
import 'settings/theme_settings_screen.dart';
import 'vault/vault_screen.dart';
import 'welcome_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const SizedBox(height: 8),
            _item(context, Icons.home_rounded, 'Home', () => Navigator.pop(context)),
            _item(context, Icons.lock_outline_rounded, 'Vault', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultScreen()));
            }),
            _item(context, Icons.palette_outlined, 'Change Theme', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()));
            }),
            _item(context, Icons.ios_share_rounded, 'Share App', () {
              Navigator.pop(context);
              SharePlus.instance.share(
                ShareParams(text: 'Check out My Photo Organizer - capture, organize, and clean up your photos!'),
              );
            }),
            _item(context, Icons.star_outline_rounded, 'Rate Us', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thanks! This will open the Play Store listing once published.')),
              );
            }),
            _item(context, Icons.chat_bubble_outline_rounded, 'Feedback', () => _showComingSoon(context, 'Feedback')),
            _item(context, Icons.call_outlined, 'Contact Us', () => _showComingSoon(context, 'Contact Us')),
            _item(context, Icons.lightbulb_outline_rounded, 'Feature Request', () => _showComingSoon(context, 'Feature Request')),
            _item(context, Icons.info_outline_rounded, 'About Us', () => _showAbout(context)),
            const Spacer(),
            const Divider(height: 1),
            _item(context, Icons.logout_rounded, 'Log out', () => _logout(context), color: AppColors.error),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: BoxDecoration(gradient: AppColors.brandGradient),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              AppConstants.appName,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textDark),
      title: Text(label, style: TextStyle(color: color ?? AppColors.textDark, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature - coming soon')),
    );
  }

  void _showAbout(BuildContext context) {
    Navigator.pop(context);
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.photo_library_rounded, color: Colors.white),
      ),
      children: const [
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('Capture, organize, and clean up your photos - all in one place.'),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.pop(context);
    if (AppConstants.kFirebaseEnabled) {
      await AuthService().signOut();
    } else {
      await LocalSessionService().logout();
    }
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }
}
