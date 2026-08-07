import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../services/on_this_day_service.dart';
import '../../utils/constants.dart';

class OnThisDayScreen extends StatefulWidget {
  const OnThisDayScreen({super.key});

  @override
  State<OnThisDayScreen> createState() => _OnThisDayScreenState();
}

class _OnThisDayScreenState extends State<OnThisDayScreen> {
  final _service = OnThisDayService();
  List<OnThisDayGroup> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final groups = await _service.getTodayMemories();
    if (mounted) {
      setState(() {
        _groups = groups;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('On ${months[today.month - 1]} ${today.day}', style: const TextStyle(color: AppColors.textDark)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _groups.length,
                  itemBuilder: (context, index) => _yearSection(_groups[index]),
                ),
    );
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
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 18),
            const Text('No memories from this day yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            const Text(
              'Come back next year - photos you take today\nwill show up here in the future.',
              textAlign: TextAlign.center,
              style: AppTextStyles.subheading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _yearSection(OnThisDayGroup group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${group.yearsAgo} year${group.yearsAgo == 1 ? '' : 's'} ago \u00b7 ${group.year}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: group.photos.length,
            itemBuilder: (context, index) {
              final asset = group.photos[index];
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
          ),
        ],
      ),
    );
  }
}
