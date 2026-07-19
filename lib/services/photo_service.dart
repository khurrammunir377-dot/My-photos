import 'dart:io';
import 'package:gal/gal.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles saving captured photos into named public-gallery sub-albums,
/// and reading existing device photos for the auto-organize feature.
class PhotoService {
  /// Requests camera + storage/photos permission. Call before opening the camera screen.
  Future<bool> requestPermissions() async {
    final camera = await Permission.camera.request();
    final photos = await PhotoManager.requestPermissionExtend();
    return camera.isGranted && photos.isAuth;
  }

  /// Saves a captured photo file into the given album name (creates the album if needed).
  /// Uses `gal`, which writes via MediaStore on Android 10+ (scoped storage compliant).
  Future<void> savePhotoToAlbum(String filePath, String albumName) async {
    final hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      final granted = await Gal.requestAccess();
      if (!granted) {
        throw Exception('Gallery access denied. Enable photo permissions in settings.');
      }
    }
    await Gal.putImage(filePath, album: albumName);
  }

  /// Fetches all photo assets currently on the device (used by Auto-Organize).
  /// Returns lightweight AssetEntity references; call `.file` lazily per-item to avoid
  /// loading everything into memory at once.
  Future<List<AssetEntity>> getAllDevicePhotos() async {
    final permitted = await PhotoManager.requestPermissionExtend();
    if (!permitted.isAuth) return [];

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (albums.isEmpty) return [];

    final recentAlbum = albums.first;
    final count = await recentAlbum.assetCountAsync;
    return recentAlbum.getAssetListRange(start: 0, end: count);
  }

  Future<File?> assetToFile(AssetEntity asset) async {
    return asset.file;
  }
}
