import 'package:flutter/material.dart';
import '../../models/folder_model.dart';
import '../../services/folder_service.dart';
import '../../utils/constants.dart';
import '../camera/camera_screen.dart';
import '../gallery/gallery_screen.dart';
import 'create_folder_screen.dart';

class FolderDetailScreen extends StatefulWidget {
  final FolderModel folder;
  const FolderDetailScreen({super.key, required this.folder});

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  final _folderService = FolderService();
  List<FolderModel> _subfolders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.folder.id == null) return;
    final subfolders = await _folderService.getSubfolders(widget.folder.id!);
    if (mounted) {
      setState(() {
        _subfolders = subfolders;
        _loading = false;
      });
    }
  }

  Future<void> _addSubfolder() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateFolderScreen(parentId: widget.folder.id)),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(widget.folder.name, style: const TextStyle(color: AppColors.textDark)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _actionCard(
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CameraScreen(folder: widget.folder))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionCard(
                        icon: Icons.photo_library_outlined,
                        label: 'Gallery',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GalleryScreen(folder: widget.folder))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subfolders', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    TextButton.icon(
                      onPressed: _addSubfolder,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_subfolders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No subfolders yet. Use "Add" to organize photos inside "${widget.folder.name}" even further.',
                      style: AppTextStyles.subheading,
                    ),
                  )
                else
                  ..._subfolders.asMap().entries.map((entry) => _subfolderTile(entry.value, entry.key)),
              ],
            ),
    );
  }

  Widget _actionCard({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(18)),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _subfolderTile(FolderModel subfolder, int index) {
    final color = AppColors.accentFor(index + 1);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => FolderDetailScreen(folder: subfolder)));
          _load();
        },
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.folder_rounded, color: color),
        ),
        title: Text(subfolder.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${subfolder.photoCount} photos'),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      ),
    );
  }
}
