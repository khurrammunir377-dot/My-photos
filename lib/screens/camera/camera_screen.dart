import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../models/folder_model.dart';
import '../../services/folder_service.dart';
import '../../services/photo_service.dart';
import '../../utils/constants.dart';

class CameraScreen extends StatefulWidget {
  final FolderModel folder;
  const CameraScreen({super.key, required this.folder});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _photoService = PhotoService();
  final _folderService = FolderService();

  CameraController? _controller;
  bool _ready = false;
  bool _capturing = false;
  String? _error;
  int _photosTakenThisSession = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final granted = await _photoService.requestPermissions();
    if (!granted) {
      setState(() => _error = 'Camera and photo permissions are required.');
      return;
    }
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(backCamera, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (e) {
      setState(() => _error = 'Could not start camera: $e');
    }
  }

  Future<void> _capture() async {
    if (_controller == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await _controller!.takePicture();
      await _photoService.savePhotoToAlbum(file.path, widget.folder.albumName);
      if (widget.folder.id != null) {
        await _folderService.incrementPhotoCount(widget.folder.id!);
      }
      setState(() => _photosTakenThisSession++);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to "${widget.folder.name}"'),
            duration: const Duration(milliseconds: 900),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save photo: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(widget.folder.name, style: const TextStyle(color: Colors.white)),
        actions: [
          if (_photosTakenThisSession > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('$_photosTakenThisSession saved', style: const TextStyle(color: Colors.white70)),
              ),
            ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              ),
            )
          : !_ready
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Stack(
                  children: [
                    Positioned.fill(child: CameraPreview(_controller!)),
                    Positioned(
                      bottom: 32,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _capture,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: _capturing ? Colors.white24 : Colors.transparent,
                            ),
                            child: _capturing
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(color: Colors.white),
                                  )
                                : Container(
                                    margin: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
