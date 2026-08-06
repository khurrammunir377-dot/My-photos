import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../services/duplicate_detector.dart';
import '../../services/photo_service.dart';
import '../../utils/constants.dart';

class AutoOrganizeScreen extends StatefulWidget {
  const AutoOrganizeScreen({super.key});

  @override
  State<AutoOrganizeScreen> createState() => _AutoOrganizeScreenState();
}

class _AutoOrganizeScreenState extends State<AutoOrganizeScreen> {
  final _photoService = PhotoService();
  final _detector = DuplicateDetector();

  bool _scanning = false;
  bool _scanned = false;
  int _totalScanned = 0;
  List<List<AssetEntity>> _groups = [];
  String? _error;

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _error = null;
      _groups = [];
    });

    try {
      final photos = await _photoService.getAllDevicePhotos();
      if (photos.isEmpty) {
        setState(() {
          _scanning = false;
          _scanned = true;
        });
        return;
      }

      // Cap scan size for a responsive MVP experience; can be raised for Pro users.
      final scanBatch = photos.take(500).toList();
      final Map<int, int> assetIndexToHash = {};

      for (int i = 0; i < scanBatch.length; i++) {
        try {
          // Hash a small thumbnail, not the full-resolution photo - this is
          // both correct (dHash only needs a tiny grayscale version) and
          // avoids decoding hundreds of multi-megapixel images, which is
          // what was causing the scan to crash on real devices.
          final thumbBytes = await scanBatch[i].thumbnailDataWithSize(const ThumbnailSize(64, 64));
          if (thumbBytes == null) continue;
          final hash = await _detector.computeHashFromBytes(thumbBytes);
          if (hash != null) assetIndexToHash[i] = hash;
        } catch (_) {
          continue; // skip any single unreadable/corrupt asset rather than aborting the whole scan
        }

        // Yield back to the UI thread periodically so the app stays responsive
        // during a large scan instead of blocking for the whole batch at once.
        if (i % 25 == 0) {
          await Future.delayed(Duration.zero);
        }
      }

      final indexGroups = _detector.groupSimilar(assetIndexToHash, threshold: 5);
      final assetGroups = indexGroups.map((group) => group.map((i) => scanBatch[i]).toList()).toList();

      setState(() {
        _groups = assetGroups;
        _totalScanned = scanBatch.length;
        _scanning = false;
        _scanned = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Scan failed: $e';
        _scanning = false;
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
        title: const Text('Auto-Organize', style: TextStyle(color: AppColors.textDark)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)));
    }

    if (_scanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning your photos for duplicates...', style: AppTextStyles.subheading),
          ],
        ),
      );
    }

    if (!_scanned) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Find duplicate & similar photos', style: AppTextStyles.heading),
          const SizedBox(height: 8),
          const Text(
            'We\'ll scan your device photos on-device (nothing uploaded) and group visually '
            'similar or duplicate photos so you can quickly clean up your gallery.',
            style: AppTextStyles.subheading,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: _startScan,
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: const Text('Start Scan', style: AppTextStyles.button),
            ),
          ),
        ],
      );
    }

    if (_groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 56, color: AppColors.accent),
            const SizedBox(height: 12),
            Text('Scanned $_totalScanned photos', style: AppTextStyles.subheading),
            const SizedBox(height: 4),
            const Text('No duplicates or similar groups found.', style: AppTextStyles.subheading),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Found ${_groups.length} group(s) in $_totalScanned photos', style: AppTextStyles.subheading),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: _groups.length,
            itemBuilder: (context, groupIndex) {
              final group = _groups[groupIndex];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Group ${groupIndex + 1} \u2022 ${group.length} similar photos',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: group.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, i) {
                            return FutureBuilder(
                              future: group[i].thumbnailDataWithSize(const ThumbnailSize(160, 160)),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState != ConnectionState.done || snapshot.data == null) {
                                  return Container(
                                    width: 80,
                                    color: Colors.grey.shade200,
                                  );
                                }
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(snapshot.data!, width: 80, height: 80, fit: BoxFit.cover),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
