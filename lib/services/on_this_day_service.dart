import 'package:photo_manager/photo_manager.dart';
import 'photo_service.dart';

class OnThisDayGroup {
  final int yearsAgo;
  final int year;
  final List<AssetEntity> photos;
  OnThisDayGroup({required this.yearsAgo, required this.year, required this.photos});
}

/// Finds photos taken on today's month/day in previous years - the classic
/// "memories" feature that drives daily re-opens in Google Photos / Facebook.
class OnThisDayService {
  final _photoService = PhotoService();

  Future<List<OnThisDayGroup>> getTodayMemories() async {
    final now = DateTime.now();
    final allPhotos = await _photoService.getAllDevicePhotos();

    final byYear = <int, List<AssetEntity>>{};
    for (final asset in allPhotos) {
      final date = asset.createDateTime;
      if (date.month == now.month && date.day == now.day && date.year != now.year) {
        byYear.putIfAbsent(date.year, () => []).add(asset);
      }
    }

    final groups = byYear.entries
        .map((e) => OnThisDayGroup(yearsAgo: now.year - e.key, year: e.key, photos: e.value))
        .toList();
    groups.sort((a, b) => a.year.compareTo(b.year)); // oldest memory first
    return groups;
  }
}
