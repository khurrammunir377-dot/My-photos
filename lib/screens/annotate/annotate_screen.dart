import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../models/annotate_shape.dart';
import '../../services/folder_service.dart';
import '../../services/photo_service.dart';
import '../../utils/annotate_painter.dart';
import '../../utils/constants.dart';

class AnnotateScreen extends StatefulWidget {
  final String imagePath;
  const AnnotateScreen({super.key, required this.imagePath});

  @override
  State<AnnotateScreen> createState() => _AnnotateScreenState();
}

class _AnnotateScreenState extends State<AnnotateScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  final List<AnnotateShape> _shapes = [];
  AnnotateShape? _inProgress;

  AnnotateTool _tool = AnnotateTool.pen;
  Color _color = Colors.red;
  double _strokeWidth = 5;
  bool _saving = false;

  static const _colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple, Colors.white, Colors.black];

  void _onPanStart(DragStartDetails details) {
    if (_tool == AnnotateTool.text) return;
    setState(() {
      _inProgress = AnnotateShape(
        tool: _tool,
        color: _color,
        strokeWidth: _strokeWidth,
        points: [details.localPosition],
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_inProgress == null) return;
    setState(() {
      if (_tool == AnnotateTool.pen) {
        _inProgress = AnnotateShape(
          tool: _tool,
          color: _color,
          strokeWidth: _strokeWidth,
          points: [..._inProgress!.points, details.localPosition],
        );
      } else {
        // arrow/rect/circle only need start+end
        _inProgress = AnnotateShape(
          tool: _tool,
          color: _color,
          strokeWidth: _strokeWidth,
          points: [_inProgress!.points.first, details.localPosition],
        );
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_inProgress == null) return;
    setState(() {
      _shapes.add(_inProgress!);
      _inProgress = null;
    });
  }

  Future<void> _onTapForText(TapUpDetails details) async {
    if (_tool != AnnotateTool.text) return;
    final text = await showDialog<String>(
      context: context,
      builder: (context) => _TextInputDialog(),
    );
    if (text != null && text.trim().isNotEmpty) {
      setState(() {
        _shapes.add(AnnotateShape(
          tool: AnnotateTool.text,
          color: _color,
          strokeWidth: _strokeWidth,
          text: text.trim(),
          textPosition: details.localPosition,
        ));
      });
    }
  }

  void _undo() {
    if (_shapes.isEmpty) return;
    setState(() => _shapes.removeLast());
  }

  void _clearAll() {
    setState(() => _shapes.clear());
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Could not render image');
      final bytes = byteData.buffer.asUint8List();

      final tempPath = '${Directory.systemTemp.path}/annotated_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(tempPath).writeAsBytes(bytes);

      final folder = await FolderService().getOrCreateSystemFolder('Annotated');
      await PhotoService().savePhotoToAlbum(tempPath, folder.albumName);
      if (folder.id != null) await FolderService().incrementPhotoCount(folder.id!);
      await File(tempPath).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to "Annotated" folder')),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Annotate', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white),
            onPressed: _shapes.isEmpty ? null : _undo,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _shapes.isEmpty ? null : _clearAll,
          ),
          IconButton(
            icon: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check, color: Colors.white),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: RepaintBoundary(
                key: _repaintKey,
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  onTapUp: _onTapForText,
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      Image.file(File(widget.imagePath)),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: AnnotatePainter(shapes: _shapes, inProgress: _inProgress),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _toolbar(),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _colors.map((c) => _colorSwatch(c)).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _toolButton(AnnotateTool.pen, Icons.edit_outlined),
              _toolButton(AnnotateTool.arrow, Icons.north_east_rounded),
              _toolButton(AnnotateTool.rectangle, Icons.crop_square_rounded),
              _toolButton(AnnotateTool.circle, Icons.circle_outlined),
              _toolButton(AnnotateTool.text, Icons.text_fields_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorSwatch(Color color) {
    final selected = color == _color;
    return GestureDetector(
      onTap: () => setState(() => _color = color),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 2.5),
        ),
      ),
    );
  }

  Widget _toolButton(AnnotateTool tool, IconData icon) {
    final selected = tool == _tool;
    return GestureDetector(
      onTap: () => setState(() => _tool = tool),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _TextInputDialog extends StatefulWidget {
  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add text'),
      content: TextField(controller: _controller, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, _controller.text), child: const Text('Add')),
      ],
    );
  }
}
