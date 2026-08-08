import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import '../../services/folder_service.dart';
import '../../services/photo_service.dart';
import '../../utils/constants.dart';

class BeforeAfterViewerScreen extends StatefulWidget {
  final AssetEntity before;
  final AssetEntity after;
  const BeforeAfterViewerScreen({super.key, required this.before, required this.after});

  @override
  State<BeforeAfterViewerScreen> createState() => _BeforeAfterViewerScreenState();
}

class _BeforeAfterViewerScreenState extends State<BeforeAfterViewerScreen> {
  double _dividerFraction = 0.5; // 0 = fully "after", 1 = fully "before"
  bool _saving = false;

  void _onDragUpdate(DragUpdateDetails details, double width) {
    setState(() {
      _dividerFraction = (_dividerFraction + details.delta.dx / width).clamp(0.0, 1.0);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final beforeFile = await widget.before.file;
      final afterFile = await widget.after.file;
      if (beforeFile == null || afterFile == null) throw Exception('Could not read photo files');

      final composited = await _composite(beforeFile, afterFile, _dividerFraction);
      if (composited == null) throw Exception('Could not process photos');

      final tempPath = '${Directory.systemTemp.path}/before_after_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(composited);

      final folder = await FolderService().getOrCreateSystemFolder('Before & After');
      await PhotoService().savePhotoToAlbum(tempPath, folder.albumName);
      if (folder.id != null) await FolderService().incrementPhotoCount(folder.id!);
      await tempFile.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to "Before & After" folder')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Composites the two photos side-by-side at the current divider position
  /// into a single image with a thin divider line - this is a one-off
  /// operation on exactly 2 photos (not a batch loop), so full-resolution
  /// decoding here is safe, unlike the earlier per-photo scan crash.
  Future<List<int>?> _composite(File beforeFile, File afterFile, double fraction) async {
    final beforeImg = img.decodeImage(await beforeFile.readAsBytes());
    final afterImg = img.decodeImage(await afterFile.readAsBytes());
    if (beforeImg == null || afterImg == null) return null;

    // Normalize both to the same target size (based on the smaller image,
    // capped for a reasonable file size) so they align cleanly.
    final targetWidth = [beforeImg.width, afterImg.width, 1600].reduce((a, b) => a < b ? a : b);
    final beforeResized = img.copyResize(beforeImg, width: targetWidth);
    final afterResized = img.copyResize(afterImg, width: targetWidth);
    final targetHeight = beforeResized.height < afterResized.height ? beforeResized.height : afterResized.height;

    final canvas = img.Image(width: targetWidth, height: targetHeight);
    final splitX = (targetWidth * fraction).round();

    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        final pixel = x < splitX ? beforeResized.getPixel(x, y) : afterResized.getPixel(x, y);
        canvas.setPixel(x, y, pixel);
      }
    }
    // divider line
    for (int y = 0; y < targetHeight; y++) {
      for (int dx = -2; dx <= 2; dx++) {
        final x = splitX + dx;
        if (x >= 0 && x < targetWidth) {
          canvas.setPixelRgba(x, y, 255, 255, 255, 255);
        }
      }
    }

    return img.encodeJpg(canvas, quality: 90);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Before / After', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.download_outlined, color: Colors.white),
            onPressed: _saving ? null : _save,
            tooltip: 'Save as one photo',
          ),
        ],
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return GestureDetector(
              onHorizontalDragUpdate: (details) => _onDragUpdate(details, width),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // "after" as the full background
                    _assetImage(widget.after),
                    // "before" clipped to the divider position
                    ClipRect(
                      clipper: _LeftClipper(_dividerFraction),
                      child: _assetImage(widget.before),
                    ),
                    // divider handle
                    Positioned(
                      left: width * _dividerFraction - 18,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.drag_indicator, color: AppColors.textDark, size: 20),
                        ),
                      ),
                    ),
                    Positioned(
                      left: width * _dividerFraction,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 2, color: Colors.white),
                    ),
                    const Positioned(top: 12, left: 12, child: _Badge(label: 'BEFORE')),
                    const Positioned(top: 12, right: 12, child: _Badge(label: 'AFTER')),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _assetImage(AssetEntity asset) {
    return FutureBuilder(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(1000, 1300)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || snapshot.data == null) {
          return Container(color: Colors.grey.shade900);
        }
        return Image.memory(snapshot.data!, fit: BoxFit.cover);
      },
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  final double fraction;
  _LeftClipper(this.fraction);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(covariant _LeftClipper oldClipper) => oldClipper.fraction != fraction;
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }
}
