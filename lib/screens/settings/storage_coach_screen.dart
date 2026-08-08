import 'package:flutter/material.dart';
import '../../services/storage_coach_service.dart';
import '../../utils/constants.dart';
import '../organize/auto_detect_screen.dart';
import '../organize/auto_organize_screen.dart';

class StorageCoachScreen extends StatefulWidget {
  const StorageCoachScreen({super.key});

  @override
  State<StorageCoachScreen> createState() => _StorageCoachScreenState();
}

class _StorageCoachScreenState extends State<StorageCoachScreen> {
  final _service = StorageCoachService();
  StorageStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.markShown();
    final stats = await _service.getStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Storage Coach', style: TextStyle(color: AppColors.textDark)),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _buildContent(),
    );
  }

  Widget _buildContent() {
    final stats = _stats!;
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _loading = true);
        await _load();
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: AppColors.richBrandGradient, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.insights_outlined, color: Colors.white),
                    SizedBox(width: 8),
                    Text('This week', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 14),
                Text('${stats.totalPhotos} photos', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                Text('~${stats.totalSizeMb.toStringAsFixed(0)} MB estimated', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Suggestions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 10),
          if (stats.likelyDuplicateGroups > 0)
            _suggestionCard(
              icon: Icons.copy_all_outlined,
              iconColor: AppColors.secondary,
              title: '${stats.likelyDuplicateGroups} possible duplicate group(s)',
              subtitle: 'Review and clean up similar photos',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AutoOrganizeScreen())),
            ),
          if (stats.screenshotCount > 0)
            _suggestionCard(
              icon: Icons.screenshot_outlined,
              iconColor: AppColors.primary,
              title: '${stats.screenshotCount} screenshot(s) found',
              subtitle: 'Move them into a dedicated folder',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AutoDetectScreen())),
            ),
          if (stats.largePhotoCount > 0)
            _suggestionCard(
              icon: Icons.photo_size_select_large_outlined,
              iconColor: AppColors.proGold,
              title: '~${stats.largePhotoCount} large photo(s) (over 5MB)',
              subtitle: 'These take up the most space in your library',
              onTap: null,
            ),
          if (stats.likelyDuplicateGroups == 0 && stats.screenshotCount == 0 && stats.largePhotoCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: const [
                  Icon(Icons.check_circle_outline, size: 48, color: AppColors.accent),
                  SizedBox(height: 12),
                  Text('Your library looks tidy!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _suggestionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: onTap != null ? const Icon(Icons.chevron_right, color: AppColors.textMuted) : null,
      ),
    );
  }
}
