import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/folder_service.dart';
import '../../services/local_session_service.dart';
import '../../utils/constants.dart';
import '../admin/admin_dashboard_screen.dart';
import '../settings/theme_settings_screen.dart';
import '../subscription/subscription_screen.dart';
import '../welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _folderService = FolderService();
  String? _email;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    String? email;
    if (AppConstants.kFirebaseEnabled) {
      email = FirebaseAuth.instance.currentUser?.email;
    } else {
      email = await LocalSessionService().getEmail();
    }
    final isPro = await _folderService.isProUser();
    if (mounted) {
      setState(() {
        _email = email;
        _isPro = isPro;
      });
    }
  }

  bool get _isAdmin {
    if (!AppConstants.kFirebaseEnabled) return false;
    final email = FirebaseAuth.instance.currentUser?.email;
    return email != null && AppConstants.adminEmails.contains(email);
  }

  Future<void> _logout() async {
    if (AppConstants.kFirebaseEnabled) {
      await AuthService().signOut();
    } else {
      await LocalSessionService().logout();
    }
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            const Text('Profile', style: AppTextStyles.heading),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _email ?? 'Guest',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isPro ? 'Pro member' : 'Free plan',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _tile(
              icon: Icons.workspace_premium_outlined,
              iconColor: AppColors.proGold,
              title: 'Go Pro',
              subtitle: 'Unlimited folders, plans & referrals',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())).then((_) => _load()),
            ),
            _tile(
              icon: Icons.palette_outlined,
              iconColor: AppColors.secondary,
              title: 'Change Theme',
              subtitle: 'Pick from 10 color themes',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeSettingsScreen())),
            ),
            if (_isAdmin)
              _tile(
                icon: Icons.admin_panel_settings_outlined,
                iconColor: AppColors.primary,
                title: 'Admin Dashboard',
                subtitle: 'Users, stats, activity',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
              ),
            _tile(
              icon: Icons.logout,
              iconColor: AppColors.error,
              title: 'Log out',
              subtitle: null,
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
