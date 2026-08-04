import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../models/folder_model.dart';
import '../../services/folder_service.dart';
import '../../services/photo_service.dart';
import '../../utils/camera_filters.dart';
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
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _ready = false;
  bool _capturing = false;
  bool _switching = false;
  String? _error;
  int _photosTakenThisSession = 0;
  PhotoFilter _selectedFilter = PhotoFilter.normal;

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
      final backIndex = cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
      _cameras = cameras;
      _cameraIndex = backIndex >= 0 ? backIndex : 0;
      await _startController(_cameraIndex);
    } catch (e) {
      setState(() => _error = 'Could not start camera: $e');
    }
  }

  Future<void> _startController(int index) async {
    // veryHigh gives noticeably sharper captures than the previous `high`
    // preset while still being broadly device-compatible (max can fail to
    // initialize on some lower-end hardware).
    final controller = CameraController(_cameras[index], ResolutionPreset.veryHigh, enableAudio: false);
    await controller.initialize();
    if (!mounted) return;
    setState(() {
      _controller = controller;
      _ready = true;
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _switching) return;
    setState(() {
      _switching = true;
      _ready = false;
    });
    await _controller?.dispose();
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startController(_cameraIndex);
    if (mounted) setState(() => _switching = false);
  }

  Future<void> _capture() async {
    if (_controller == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await _controller!.takePicture();
      await CameraFilters.bakeIntoFile(file.path, _selectedFilter);
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
          if (_cameras.length > 1)
            IconButton(
              icon: _switching
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.cameraswitch_outlined, color: Colors.white),
              onPressed: _switching ? null : _switchCamera,
              tooltip: 'Switch camera',
            ),
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
                    Positioned.fill(
                      child: FilteredPreview(filter: _selectedFilter, child: CameraPreview(_controller!)),
                    ),
                    Positioned(
                      bottom: 130,
                      left: 0,
                      right: 0,
                      child: _filterStrip(),
                    ),
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

  Widget _filterStrip() {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: CameraFilters.options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final option = CameraFilters.options[index];
          final selected = option.type == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = option.type),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? AppColors.primary : Colors.white54, width: selected ? 3 : 1.5),
                  ),
                  child: ClipOval(
                    child: FilteredPreview(
                      filter: option.type,
                      child: Container(color: Colors.grey.shade400),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  option.label,
                  style: TextStyle(
                    color: selected ? AppColors.primary : Colors.white70,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
