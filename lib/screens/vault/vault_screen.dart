import 'package:flutter/material.dart';
import '../../models/folder_model.dart';
import '../../services/folder_service.dart';
import '../../services/vault_service.dart';
import '../../utils/constants.dart';
import '../camera/camera_screen.dart';
import '../folder/create_folder_screen.dart';
import '../folder/folder_detail_screen.dart';
import '../gallery/gallery_screen.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  bool _checkingSetup = true;
  bool _pinExists = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final exists = await VaultService.instance.hasPinSet();
    if (mounted) {
      setState(() {
        _pinExists = exists;
        _checkingSetup = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSetup) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (VaultService.instance.isUnlocked) {
      return const _VaultContentScreen();
    }
    return _PinGateScreen(
      isSettingUpNewPin: !_pinExists,
      onUnlocked: () => setState(() {}),
    );
  }
}

class _PinGateScreen extends StatefulWidget {
  final bool isSettingUpNewPin;
  final VoidCallback onUnlocked;
  const _PinGateScreen({required this.isSettingUpNewPin, required this.onUnlocked});

  @override
  State<_PinGateScreen> createState() => _PinGateScreenState();
}

class _PinGateScreenState extends State<_PinGateScreen> {
  String _pin = '';
  String? _firstPin; // used during setup's "confirm" step
  String? _error;
  bool _confirming = false;

  void _onDigit(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == 4) _submit();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (widget.isSettingUpNewPin) {
      if (!_confirming) {
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _confirming = true;
        });
        return;
      }
      if (_pin == _firstPin) {
        await VaultService.instance.setPin(_pin);
        widget.onUnlocked();
      } else {
        setState(() {
          _error = "PINs didn't match - try again";
          _pin = '';
          _firstPin = null;
          _confirming = false;
        });
      }
      return;
    }

    final correct = await VaultService.instance.checkPin(_pin);
    if (correct) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = 'Incorrect PIN';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isSettingUpNewPin
        ? (_confirming ? 'Confirm your PIN' : 'Create a Vault PIN')
        : 'Enter Vault PIN';
    final subtitle = widget.isSettingUpNewPin
        ? (_confirming ? 'Type it again to confirm' : 'This protects your private folder')
        : 'Your private, hidden folder';

    return Scaffold(
      backgroundColor: AppColors.textDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? Colors.white : Colors.transparent,
                      border: Border.all(color: Colors.white54, width: 1.5),
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
              const Spacer(),
              _numPad(),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numPad() {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((d) => _digitButton(d)).toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 64, height: 64),
              _digitButton('0'),
              SizedBox(
                width: 64,
                height: 64,
                child: IconButton(
                  onPressed: _onBackspace,
                  icon: const Icon(Icons.backspace_outlined, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _digitButton(String digit) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Material(
        color: Colors.white.withOpacity(0.06),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _onDigit(digit),
          child: Center(
            child: Text(digit, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

class _VaultContentScreen extends StatefulWidget {
  const _VaultContentScreen();

  @override
  State<_VaultContentScreen> createState() => _VaultContentScreenState();
}

class _VaultContentScreenState extends State<_VaultContentScreen> {
  final _folderService = FolderService();
  List<FolderModel> _folders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final folders = await _folderService.getVaultFolders();
    if (mounted) {
      setState(() {
        _folders = folders;
        _loading = false;
      });
    }
  }

  Future<void> _createVaultFolder() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateFolderScreen(isVault: true)),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, size: 18, color: AppColors.textDark),
            SizedBox(width: 8),
            Text('Vault', style: TextStyle(color: AppColors.textDark)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_open_rounded, color: AppColors.textMuted),
            tooltip: 'Lock Vault',
            onPressed: () {
              VaultService.instance.lock();
              setState(() {});
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _folders.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  itemCount: _folders.length,
                  itemBuilder: (context, index) => _folderTile(_folders[index], index),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createVaultFolder,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Vault Folder'),
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
              child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 18),
            const Text('Your Vault is empty', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            const Text(
              'Folders you create here are private and\nhidden from the main Folders list.',
              textAlign: TextAlign.center,
              style: AppTextStyles.subheading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _folderTile(FolderModel folder, int index) {
    final color = AppColors.accentFor(index);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => FolderDetailScreen(folder: folder)));
                  _load();
                },
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.folder_rounded, color: color, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(folder.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('${folder.photoCount} photos', style: AppTextStyles.subheading),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.photo_library_outlined, color: AppColors.textMuted),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GalleryScreen(folder: folder))),
            ),
            Container(
              decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CameraScreen(folder: folder))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
