import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../models/folder_model.dart';
import '../../utils/constants.dart';
import 'photo_viewer_screen.dart';

class GalleryScreen extends StatefulWidget {
  final FolderModel folder;
  const GalleryScreen({super.key, required this.folder});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<AssetEntity> _photos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final permitted = await PhotoManager.requestPermissionExtend();
    if (!permitted.isAuth) {
      setState(() => _loading = false);
      return;
    }
    // Find the album matching this folder's album name
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    final match = albums.where((a) => a.name == widget.folder.albumName).toList();

    if (match.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    final count = await match.first.assetCountAsync;
    final assets = await match.first.getAssetListRange(start: 0, end: count);
    setState(() {
      _photos = assets;
      _loading = false;
    });
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
          : _photos.isEmpty
              ? const Center(child: Text('No photos in this folder yet', style: AppTextStyles.subheading))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PhotoViewerScreen(photos: _photos, initialIndex: index)),
                      ),
                      child: FutureBuilder(
                        future: _photos[index].thumbnailDataWithSize(const ThumbnailSize(300, 300)),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done || snapshot.data == null) {
                            return Container(color: Colors.grey.shade200);
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
