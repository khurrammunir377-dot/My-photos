import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../models/person_model.dart';
import '../../services/people_service.dart';
import '../../utils/constants.dart';
import 'face_scan_screen.dart';
import 'person_detail_screen.dart';

class PeopleScreen extends StatefulWidget {
  final VoidCallback onMenuTap;
  const PeopleScreen({super.key, required this.onMenuTap});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final _peopleService = PeopleService();
  List<PersonModel> _people = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final people = await _peopleService.getAllPeople();
    if (mounted) {
      setState(() {
        _people = people;
        _loading = false;
      });
    }
  }

  Future<void> _startScan() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FaceScanScreen()),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _header()),
                    if (_people.isEmpty)
                      SliverFillRemaining(hasScrollBody: false, child: _emptyState())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 18,
                            childAspectRatio: 0.8,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _PersonCard(person: _people[index], onOpen: _load),
                            childCount: _people.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startScan,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.face_retouching_natural),
        label: const Text('Find People'),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: widget.onMenuTap,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.menu_rounded, color: AppColors.textDark, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('People', style: AppTextStyles.heading),
              Text('${_people.length}', style: AppTextStyles.subheading),
            ],
          ),
        ],
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
              child: const Icon(Icons.face_retouching_natural, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 18),
            const Text('No people grouped yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            const Text(
              'Tap "Find People" to scan your photos for faces\nand group them by person.',
              textAlign: TextAlign.center,
              style: AppTextStyles.subheading,
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final PersonModel person;
  final VoidCallback onOpen;
  const _PersonCard({required this.person, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PersonDetailScreen(person: person)),
        );
        onOpen();
      },
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: AspectRatio(
                aspectRatio: 1,
                child: FutureBuilder<AssetEntity?>(
                  future: AssetEntity.fromId(person.coverPhotoId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data == null) {
                      return Container(color: Colors.grey.shade200);
                    }
                    return FutureBuilder(
                      future: snapshot.data!.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                      builder: (context, thumbSnap) {
                        if (thumbSnap.connectionState != ConnectionState.done || thumbSnap.data == null) {
                          return Container(color: Colors.grey.shade200);
                        }
                        return Image.memory(thumbSnap.data!, fit: BoxFit.cover);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            person.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Text('${person.photoIds.length} photos', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
