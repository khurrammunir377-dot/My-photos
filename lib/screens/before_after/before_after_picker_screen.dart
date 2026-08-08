import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../services/photo_service.dart';
import '../../utils/constants.dart';
import 'before_after_viewer_screen.dart';

class BeforeAfterPickerScreen extends StatefulWidget {
  const BeforeAfterPickerScreen({super.key});

  @override
  State<BeforeAfterPickerScreen> createState() => _BeforeAfterPickerScreenState();
}

class _BeforeAfterPickerScreenState extends State<BeforeAfterPickerScreen> {
  final _photoService = PhotoService();
  List<AssetEntity> _photos = [];
  bool _loading = true;
  AssetEntity? _before;
  AssetEntity? _after;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final photos = await _photoService.getAllDevicePhotos();
    if (mounted) {
      setState(() {
        _photos = photos;
        _loading = false;
      });
    }
  }

  void _onTap(AssetEntity asset) {
    setState(() {
      if (_before == asset) {
        _before = null;
      } else if (_after == asset) {
        _after = null;
      } else if (_before == null) {
        _before = asset;
      } else if (_after == null) {
        _after = asset;
      } else {
        // both already picked - start over with this as the new "before"
        _before = asset;
        _after = null;
      }
    });
  }

  void _continue() {
    if (_before == null || _after == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BeforeAfterViewerScreen(before: _before!, after: _after!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Before / After', style: TextStyle(color: AppColors.textDark)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Expanded(child: _slotLabel('Before', _before)),
                      const SizedBox(width: 12),
                      Expanded(child: _slotLabel('After', _after)),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _photos.length,
                    itemBuilder: (context, index) {
                      final asset = _photos[index];
                      final isBefore = asset == _before;
                      final isAfter = asset == _after;
                      return GestureDetector(
                        onTap: () => _onTap(asset),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
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
                            if (isBefore || isAfter)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primary, width: 3),
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                                    child: Text(
                                      isBefore ? 'Before' : 'After',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: (_before != null && _after != null)
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: _continue,
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Compare'),
            )
          : null,
    );
  }

  Widget _slotLabel(String label, AssetEntity? asset) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: asset != null ? AppColors.primary.withOpacity(0.1) : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: asset != null ? AppColors.primary : Colors.grey.shade200),
      ),
      child: Center(
        child: Text(
          asset != null ? '$label: selected' : '$label: tap a photo',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: asset != null ? AppColors.primary : AppColors.textMuted),
        ),
      ),
    );
  }
}
