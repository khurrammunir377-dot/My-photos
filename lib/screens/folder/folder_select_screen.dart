import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/folder_model.dart';
import '../../services/auth_service.dart';
import '../../services/folder_service.dart';
import '../../services/local_session_service.dart';
import '../../utils/constants.dart';
import '../admin/admin_dashboard_screen.dart';
import '../camera/camera_screen.dart';
import '../gallery/gallery_screen.dart';
import '../organize/auto_organize_screen.dart';
import '../subscription/subscription_screen.dart';
import '../welcome_screen.dart';
import 'create_folder_screen.dart';

class FolderSelectScreen extends StatefulWidget {
  const FolderSelectScreen({super.key});

  @override
  State<FolderSelectScreen> createState() => _FolderSelectScreenState();
}

class _FolderSelectScreenState extends State<FolderSelectScreen> {
  final _folderService = FolderService();
  List<FolderModel> _folders = [];
  bool _isPro = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final folders = await _folderService.getAllFolders();
    final isPro = await _folderService.isProUser();
    setState(() {
      _folders = folders;
      _isPro = isPro;
      _loading = false;
    });
  }

  Future<void> _createFolder() async {
    final canCreate = await _folderService.canCreateFolder();
    if (!canCreate) {
      _showUpgradeDialog();
      return;
    }
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateFolderScreen()),
    );
    if (created == true) _load();
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Upgrade to Pro'),
        content: const Text(
          'Free plan includes 1 folder. Upgrade to Pro for unlimited folders and more features.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Not now')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.proGold),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()))
                  .then((_) => _load());
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  bool get _isAdmin {
    if (!AppConstants.kFirebaseEnabled) return false; // admin dashboard needs Firestore
    final email = FirebaseAuth.instance.currentUser?.email;
    return email != null && AppConstants.adminEmails.contains(email);
  }

  void _openFolder(FolderModel folder) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CameraScreen(folder: folder)),
    );
  }

  void _viewGallery(FolderModel folder) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GalleryScreen(folder: folder)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(AppConstants.appName, style: TextStyle(color: AppColors.textDark)),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.textMuted),
              tooltip: 'Admin Dashboard',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.workspace_premium_outlined, color: AppColors.proGold),
            tooltip: 'Go Pro',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
            ).then((_) => _load()),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textMuted),
            onPressed: () async {
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
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Your Folders', style: AppTextStyles.heading),
                      if (_isPro)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.proGold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('PRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isPro
                        ? 'Unlimited folders'
                        : '${_folders.length}/${AppConstants.freeTierFolderLimit} folder used (Free plan)',
                    style: AppTextStyles.subheading,
                  ),
                  const SizedBox(height: 20),

                  // Auto-organize entry point
                  Card(
                    color: AppColors.cardBackground,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppColors.accent),
                      ),
                      title: const Text('Auto-Organize Existing Photos', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Find duplicates & similar photos on your device'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AutoOrganizeScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_folders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          const Icon(Icons.folder_off_outlined, size: 56, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text('No folders yet', style: AppTextStyles.subheading),
                        ],
                      ),
                    )
                  else
                    ..._folders.map((folder) => Card(
                          color: AppColors.cardBackground,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.folder, color: AppColors.primary),
                            ),
                            title: Text(folder.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${folder.photoCount} photos'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.photo_library_outlined, color: AppColors.textMuted),
                                  onPressed: () => _viewGallery(folder),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.camera_alt, color: AppColors.primary),
                                  onPressed: () => _openFolder(folder),
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _createFolder,
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('New Folder'),
      ),
    );
  }
}
