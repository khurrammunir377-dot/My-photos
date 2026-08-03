import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../models/person_model.dart';
import '../../services/people_service.dart';
import '../../utils/constants.dart';
import 'face_scan_screen.dart';

class PersonDetailScreen extends StatefulWidget {
  final PersonModel person;
  const PersonDetailScreen({super.key, required this.person});

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  final _peopleService = PeopleService();
  late PersonModel _person;

  @override
  void initState() {
    super.initState();
    _person = widget.person;
  }

  Future<void> _refresh() async {
    final all = await _peopleService.getAllPeople();
    final updated = all.where((p) => p.id == _person.id).toList();
    if (updated.isNotEmpty && mounted) setState(() => _person = updated.first);
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: _person.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (newName != null && newName.trim().isNotEmpty && _person.id != null) {
      await _peopleService.renamePerson(_person.id!, newName.trim());
      setState(() => _person = _person.copyWith(name: newName.trim()));
    }
  }

  Future<void> _addMorePhotos() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FaceScanScreen(addToPerson: _person)),
    );
    if (result == true) _refresh();
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this person?'),
        content: Text('This removes "${_person.name}" as a group. Your photos are not deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && _person.id != null) {
      await _peopleService.deletePerson(_person.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(_person.name, style: const TextStyle(color: AppColors.textDark)),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted), onPressed: _rename),
          IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: _delete),
        ],
      ),
      body: _person.photoIds.isEmpty
          ? const Center(child: Text('No photos yet', style: AppTextStyles.subheading))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _person.photoIds.length,
              itemBuilder: (context, index) {
                return FutureBuilder<AssetEntity?>(
                  future: AssetEntity.fromId(_person.photoIds[index]),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data == null) {
                      return Container(color: Colors.grey.shade200);
                    }
                    return FutureBuilder(
                      future: snapshot.data!.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
                      builder: (context, thumbSnap) {
                        if (thumbSnap.connectionState != ConnectionState.done || thumbSnap.data == null) {
                          return Container(color: Colors.grey.shade200);
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(thumbSnap.data!, fit: BoxFit.cover),
                        );
                      },
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _addMorePhotos,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Add Photos'),
      ),
    );
  }
}
