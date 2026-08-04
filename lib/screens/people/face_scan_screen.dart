import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../models/person_model.dart';
import '../../services/face_detection_service.dart';
import '../../services/people_service.dart';
import '../../services/photo_service.dart';
import '../../utils/constants.dart';

class FaceScanScreen extends StatefulWidget {
  /// If set, newly selected photos are added to this existing person
  /// instead of creating a new one.
  final PersonModel? addToPerson;
  const FaceScanScreen({super.key, this.addToPerson});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  final _photoService = PhotoService();
  final _faceService = FaceDetectionService();
  final _peopleService = PeopleService();

  bool _scanning = false;
  bool _scanned = false;
  List<AssetEntity> _photosWithFaces = [];
  final Set<String> _selected = {};
  String? _error;

  @override
  void dispose() {
    _faceService.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final allPhotos = await _photoService.getAllDevicePhotos();
      final alreadyAssigned = await _peopleService.getAllAssignedPhotoIds();
      final candidates = allPhotos.where((a) => !alreadyAssigned.contains(a.id)).take(300).toList();

      final faces = await _faceService.scanForFaces(candidates);
      final assetIdsWithFaces = faces.map((f) => f.assetId).toSet();
      final matched = candidates.where((a) => assetIdsWithFaces.contains(a.id)).toList();

      setState(() {
        _photosWithFaces = matched;
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

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _confirmSelection() async {
    if (_selected.isEmpty) return;

    if (widget.addToPerson != null) {
      await _peopleService.addPhotosToPerson(widget.addToPerson!.id!, _selected.toList());
      if (mounted) Navigator.pop(context, true);
      return;
    }

    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NamePersonDialog(),
    );
    if (name == null || name.trim().isEmpty) return;

    await _peopleService.createPerson(name.trim(), _selected.first, _selected.toList());
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          widget.addToPerson != null ? 'Add photos of ${widget.addToPerson!.name}' : 'Find people',
          style: const TextStyle(color: AppColors.textDark),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: _selected.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: _confirmSelection,
              icon: const Icon(Icons.check),
              label: Text('Group ${_selected.length} photo${_selected.length == 1 ? '' : 's'}'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)));
    }

    if (_scanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('Scanning your photos for faces...', style: AppTextStyles.subheading),
          ],
        ),
      );
    }

    if (!_scanned) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Find photos with people in them', style: AppTextStyles.heading),
            const SizedBox(height: 8),
            const Text(
              'We\'ll scan your photos on-device for faces (nothing uploaded), then '
              'you pick which ones show the same person to group them together.',
              style: AppTextStyles.subheading,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _startScan,
                  icon: const Icon(Icons.face_retouching_natural, color: Colors.white),
                  label: const Text('Start Scan', style: AppTextStyles.button),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_photosWithFaces.isEmpty) {
      return const Center(
        child: Text('No new faces found.', style: AppTextStyles.subheading),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Tap every photo that shows the same person, then confirm.',
            style: AppTextStyles.subheading,
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
            itemCount: _photosWithFaces.length,
            itemBuilder: (context, index) {
              final asset = _photosWithFaces[index];
              final selected = _selected.contains(asset.id);
              return GestureDetector(
                onTap: () => _toggle(asset.id),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FutureBuilder(
                      future: asset.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
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
                    if (selected)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary, width: 3),
                          color: AppColors.primary.withOpacity(0.25),
                        ),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: CircleAvatar(
                              radius: 11,
                              backgroundColor: AppColors.primary,
                              child: const Icon(Icons.check, size: 14, color: Colors.white),
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
        const SizedBox(height: 70), // room for FAB
      ],
    );
  }
}

class _NamePersonDialog extends StatefulWidget {
  @override
  State<_NamePersonDialog> createState() => _NamePersonDialogState();
}

class _NamePersonDialogState extends State<_NamePersonDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Name this person'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'e.g. Mom, Ahmed, Sara'),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
