import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../services/folder_service.dart';
import '../../services/photo_service.dart';
import '../../services/screenshot_receipt_service.dart';
import '../../utils/constants.dart';

enum _DetectTab { screenshots, receipts }

class AutoDetectScreen extends StatefulWidget {
  const AutoDetectScreen({super.key});

  @override
  State<AutoDetectScreen> createState() => _AutoDetectScreenState();
}

class _AutoDetectScreenState extends State<AutoDetectScreen> {
  final _service = ScreenshotReceiptService();
  final _folderService = FolderService();
  final _photoService = PhotoService();

  _DetectTab _tab = _DetectTab.screenshots;
  bool _scanningScreenshots = true;
  bool _scanningReceipts = true;
  List<AssetEntity> _screenshots = [];
  List<AssetEntity> _receipts = [];
  final Set<String> _selected = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _scanScreenshots();
    _scanReceipts();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _scanScreenshots() async {
    final results = await _service.scanForScreenshots();
    if (mounted) {
      setState(() {
        _screenshots = results;
        _scanningScreenshots = false;
      });
    }
  }

  Future<void> _scanReceipts() async {
    final results = await _service.scanForReceipts();
    if (mounted) {
      setState(() {
        _receipts = results;
        _scanningReceipts = false;
      });
    }
  }

  List<AssetEntity> get _currentList => _tab == _DetectTab.screenshots ? _screenshots : _receipts;
  bool get _currentlyScanning => _tab == _DetectTab.screenshots ? _scanningScreenshots : _scanningReceipts;
  String get _targetFolderName => _tab == _DetectTab.screenshots ? 'Screenshots' : 'Receipts';

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _addSelectedToFolder() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);
    try {
      final folder = await _folderService.getOrCreateSystemFolder(_targetFolderName);
      final selectedAssets = _currentList.where((a) => _selected.contains(a.id)).toList();

      for (final asset in selectedAssets) {
        final file = await asset.file;
        if (file == null) continue;
        await _photoService.savePhotoToAlbum(file.path, folder.albumName);
        if (folder.id != null) await _folderService.incrementPhotoCount(folder.id!);
      }

      if (mounted) {
        setState(() => _selected.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${selectedAssets.length} photo(s) to "$_targetFolderName"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Something went wrong: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Auto-Detect', style: TextStyle(color: AppColors.textDark)),
      ),
      body: Column(
        children: [
          _tabSelector(),
          Expanded(child: _content()),
        ],
      ),
      floatingActionButton: _selected.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: _saving ? null : _addSelectedToFolder,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text('Add ${_selected.length} to $_targetFolderName'),
            )
          : null,
    );
  }

  Widget _tabSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: _tabButton('Screenshots', Icons.screenshot_outlined, _DetectTab.screenshots, _screenshots.length),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _tabButton('Receipts', Icons.receipt_long_outlined, _DetectTab.receipts, _receipts.length),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, IconData icon, _DetectTab tab, int count) {
    final selected = _tab == tab;
    return GestureDetector(
      onTap: () => setState(() {
        _tab = tab;
        _selected.clear();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          color: selected ? null : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : AppColors.textMuted, size: 20),
            const SizedBox(height: 4),
            Text(
              count > 0 ? '$label ($count)' : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (_currentlyScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              _tab == _DetectTab.screenshots ? 'Scanning for screenshots...' : 'Scanning for receipts (this can take a moment)...',
              style: AppTextStyles.subheading,
            ),
          ],
        ),
      );
    }

    if (_currentList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _tab == _DetectTab.screenshots ? Icons.screenshot_outlined : Icons.receipt_long_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                _tab == _DetectTab.screenshots ? 'No screenshots found' : 'No receipts found',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _currentList.length,
        itemBuilder: (context, index) {
          final asset = _currentList[index];
          final selected = _selected.contains(asset.id);
          return GestureDetector(
            onTap: () => _toggle(asset.id),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FutureBuilder(
                    future: asset.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done || snapshot.data == null) {
                        return Container(color: Colors.grey.shade200);
                      }
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    },
                  ),
                ),
                if (selected)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary, width: 3),
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.check, size: 13, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
