import 'package:flutter/material.dart';
import '../../models/folder_model.dart';
import '../../services/folder_service.dart';
import '../../utils/constants.dart';
import '../camera/camera_screen.dart';
import '../gallery/gallery_screen.dart';
import '../organize/auto_organize_screen.dart';
import '../subscription/subscription_screen.dart';
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
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final folders = await _folderService.getAllFolders();
    final isPro = await _folderService.isProUser();
    if (mounted) {
      setState(() {
        _folders = folders;
        _isPro = isPro;
        _loading = false;
      });
    }
  }

  List<FolderModel> get _filteredFolders {
    if (_query.trim().isEmpty) return _folders;
    final q = _query.toLowerCase();
    return _folders.where((f) => f.name.toLowerCase().contains(q)).toList();
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

  void _openFolder(FolderModel folder) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CameraScreen(folder: folder)));
  }

  void _viewGallery(FolderModel folder) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GalleryScreen(folder: folder)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _header()),
                  SliverToBoxAdapter(child: _searchBar()),
                  SliverToBoxAdapter(child: _autoOrganizeCard()),
                  if (_filteredFolders.isEmpty)
                    SliverFillRemaining(hasScrollBody: false, child: _emptyState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _folderCard(_filteredFolders[index], index),
                          childCount: _filteredFolders.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createFolder,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('New Folder'),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your Folders', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
              if (_isPro)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: const Text('PRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _isPro
                ? 'Unlimited folders'
                : '${_folders.length}/${AppConstants.freeTierFolderLimit} folder used \u00b7 Free plan',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: 'Search folders',
            prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _autoOrganizeCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AutoOrganizeScreen())),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auto-Organize', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    SizedBox(height: 2),
                    Text('Find duplicates & similar photos', style: AppTextStyles.subheading),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
              child: const Icon(Icons.folder_off_outlined, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 18),
            const Text('No folders yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Tap "New Folder" to get started.', style: AppTextStyles.subheading),
          ],
        ),
      ),
    );
  }

  Widget _folderCard(FolderModel folder, int index) {
    final color = AppColors.accentFor(index);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.folder_rounded, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(folder.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('${folder.photoCount} photos', style: AppTextStyles.subheading),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.photo_library_outlined, color: AppColors.textMuted),
              onPressed: () => _viewGallery(folder),
            ),
            Container(
              decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: () => _openFolder(folder),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
