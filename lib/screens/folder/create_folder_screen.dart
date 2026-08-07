import 'package:flutter/material.dart';
import '../../services/folder_service.dart';
import '../../utils/constants.dart';

class CreateFolderScreen extends StatefulWidget {
  final int? parentId;
  final bool isVault;
  const CreateFolderScreen({super.key, this.parentId, this.isVault = false});

  @override
  State<CreateFolderScreen> createState() => _CreateFolderScreenState();
}

class _CreateFolderScreenState extends State<CreateFolderScreen> {
  final _folderService = FolderService();
  final _nameController = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a folder name');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _folderService.createFolder(name, parentId: widget.parentId, isVault: widget.isVault);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _title {
    if (widget.isVault) return 'New Vault Folder';
    if (widget.parentId != null) return 'New Subfolder';
    return 'New Folder';
  }

  String get _subtitle {
    if (widget.isVault) return 'Name your vault folder';
    if (widget.parentId != null) return 'Name your subfolder';
    return 'Name your folder';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(_title, style: const TextStyle(color: AppColors.textDark)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_subtitle, style: AppTextStyles.heading),
            const SizedBox(height: 6),
            const Text(
              'Photos you take will be saved into this album automatically.',
              style: AppTextStyles.subheading,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Folder name',
                hintText: 'e.g. Site Visit - Downtown',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Folder', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
