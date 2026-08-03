import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../services/photo_service.dart';
import '../../utils/constants.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final _photoService = PhotoService();
  bool _loading = true;
  final Map<String, List<AssetEntity>> _grouped = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final photos = await _photoService.getAllDevicePhotos();
    final grouped = <String, List<AssetEntity>>{};
    for (final asset in photos) {
      final date = asset.createDateTime;
      final key = _monthLabel(date);
      grouped.putIfAbsent(key, () => []).add(asset);
    }
    if (mounted) {
      setState(() {
        _grouped
          ..clear()
          ..addAll(grouped);
        _loading = false;
      });
    }
  }

  String _monthLabel(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month) return 'This month';
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _grouped.isEmpty
                ? _emptyState()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Timeline', style: AppTextStyles.heading),
                                Text(
                                  '${_grouped.values.fold<int>(0, (sum, l) => sum + l.length)} photos',
                                  style: AppTextStyles.subheading,
                                ),
                              ],
                            ),
                          ),
                        ),
                        for (final entry in _grouped.entries) ..._monthSection(entry.key, entry.value),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  ),
      ),
    );
  }

  List<Widget> _monthSection(String label, List<AssetEntity> photos) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final asset = photos[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FutureBuilder(
                  future: asset.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done || snapshot.data == null) {
                      return Container(color: Colors.grey.shade200);
                    }
                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  },
                ),
              );
            },
            childCount: photos.length,
          ),
        ),
      ),
    ];
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
              child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 18),
            const Text('No photos yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Photos you capture will show up here.', style: AppTextStyles.subheading),
          ],
        ),
      ),
    );
  }
}
