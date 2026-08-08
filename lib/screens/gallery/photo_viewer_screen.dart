import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../annotate/annotate_screen.dart';

class PhotoViewerScreen extends StatefulWidget {
  final List<AssetEntity> photos;
  final int initialIndex;
  const PhotoViewerScreen({super.key, required this.photos, required this.initialIndex});

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  Future<void> _annotate() async {
    final asset = widget.photos[_index];
    final file = await asset.file;
    if (file == null || !mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => AnnotateScreen(imagePath: file.path)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          '${_index + 1} / ${widget.photos.length}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: 'Annotate',
            onPressed: _annotate,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          return FutureBuilder(
            future: widget.photos[i].thumbnailDataWithSize(const ThumbnailSize(1600, 1600)),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done || snapshot.data == null) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              return InteractiveViewer(
                child: Center(child: Image.memory(snapshot.data!)),
              );
            },
          );
        },
      ),
    );
  }
}
