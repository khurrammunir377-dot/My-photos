import 'package:flutter/material.dart';

enum AnnotateTool { pen, arrow, rectangle, circle, text }

class AnnotateShape {
  final AnnotateTool tool;
  final Color color;
  final double strokeWidth;
  final List<Offset> points; // freehand path points, or [start, end] for arrow/rect/circle
  final String? text;
  final Offset? textPosition;

  AnnotateShape({
    required this.tool,
    required this.color,
    required this.strokeWidth,
    this.points = const [],
    this.text,
    this.textPosition,
  });
}
