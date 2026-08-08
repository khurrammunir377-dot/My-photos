import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'duplicate_detector.dart';
import 'photo_service.dart';
import 'screenshot_receipt_service.dart';

class StorageStats {
  final int totalPhotos;
  final double totalSizeMb;
  final int largePhotoCount; // photos over 5MB
  final int screenshotCount;
  final int likelyDuplicateGroups;

  StorageStats({
    required this.totalPhotos,
    required this.totalSizeMb,
    required this.largePhotoCount,
    required this.screenshotCount,
    required this.likelyDuplicateGroups,
  });
}

/// Builds a lightweight "storage coach" summary. Deliberately avoids
/// decoding full images (that's what caused the auto-organize crash before)
/// - file sizes come from a cheap filesystem stat() call, not a content read.
class StorageCoachService {
  final _photoService = PhotoService();
  final _screenshotService = ScreenshotReceiptService();
  final _duplicateDetector = DuplicateDetector();

  static const _lastShownKey = 'storage_coach_last_shown';
  static const _digestIntervalDays = 7;

  Future<bool> shouldShowDigest() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShownMillis = prefs.getInt(_lastShownKey);
    if (lastShownMillis == null) return true;
    final lastShown = DateTime.fromMillisecondsSinceEpoch(lastShownMillis);
    return DateTime.now().difference(lastShown).inDays >= _digestIntervalDays;
  }

  Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastShownKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<StorageStats> getStats({int sampleCap = 300}) async {
    final allPhotos = await _photoService.getAllDevicePhotos();
    final sample = allPhotos.take(sampleCap).toList();

    double totalMb = 0;
    int largeCount = 0;
    for (final asset in sample) {
      try {
        final file = await asset.file;
        if (file == null) continue;
        final bytes = await file.length(); // cheap filesystem stat, no content read
        final mb = bytes / (1024 * 1024);
        totalMb += mb;
        if (mb > 5) largeCount++;
      } catch (_) {
        continue;
      }
    }
    // Extrapolate sampled size to the full library if we only sampled a subset.
    final scaleFactor = sample.isEmpty ? 1.0 : allPhotos.length / sample.length;
    final estimatedTotalMb = totalMb * scaleFactor;
    final estimatedLargeCount = (largeCount * scaleFactor).round();

    final screenshots = await _screenshotService.scanForScreenshots();

    // Reuse the same lightweight thumbnail-hash approach as Auto-Organize for
    // a rough duplicate-group estimate, capped small since this is just a summary stat.
    final dupSample = sample.take(150).toList();
    final Map<int, int> hashes = {};
    for (int i = 0; i < dupSample.length; i++) {
      final thumb = await dupSample[i].thumbnailDataWithSize(const ThumbnailSize(64, 64));
      if (thumb == null) continue;
      final hash = await _duplicateDetector.computeHashFromBytes(thumb);
      if (hash != null) hashes[i] = hash;
    }
    final dupGroups = _duplicateDetector.groupSimilar(hashes, threshold: 5);

    return StorageStats(
      totalPhotos: allPhotos.length,
      totalSizeMb: estimatedTotalMb,
      largePhotoCount: estimatedLargeCount,
      screenshotCount: screenshots.length,
      likelyDuplicateGroups: dupGroups.length,
    );
  }

  void dispose() {
    _screenshotService.dispose();
  }
}
