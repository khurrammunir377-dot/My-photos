import 'dart:math';
import 'package:flutter/material.dart';
import '../models/annotate_shape.dart';

class AnnotatePainter extends CustomPainter {
  final List<AnnotateShape> shapes;
  final AnnotateShape? inProgress;

  AnnotatePainter({required this.shapes, this.inProgress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final shape in shapes) {
      _paintShape(canvas, shape);
    }
    if (inProgress != null) _paintShape(canvas, inProgress!);
  }

  void _paintShape(Canvas canvas, AnnotateShape shape) {
    final paint = Paint()
      ..color = shape.color
      ..strokeWidth = shape.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (shape.tool) {
      case AnnotateTool.pen:
        if (shape.points.length < 2) return;
        final path = Path()..moveTo(shape.points.first.dx, shape.points.first.dy);
        for (final p in shape.points.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, paint);
        break;

      case AnnotateTool.arrow:
        if (shape.points.length < 2) return;
        final start = shape.points.first;
        final end = shape.points.last;
        canvas.drawLine(start, end, paint);
        final angle = atan2(end.dy - start.dy, end.dx - start.dx);
        const arrowLength = 18.0;
        const arrowAngle = 0.5;
        final p1 = Offset(
          end.dx - arrowLength * cos(angle - arrowAngle),
          end.dy - arrowLength * sin(angle - arrowAngle),
        );
        final p2 = Offset(
          end.dx - arrowLength * cos(angle + arrowAngle),
          end.dy - arrowLength * sin(angle + arrowAngle),
        );
        canvas.drawLine(end, p1, paint);
        canvas.drawLine(end, p2, paint);
        break;

      case AnnotateTool.rectangle:
        if (shape.points.length < 2) return;
        canvas.drawRect(Rect.fromPoints(shape.points.first, shape.points.last), paint);
        break;

      case AnnotateTool.circle:
        if (shape.points.length < 2) return;
        final rect = Rect.fromPoints(shape.points.first, shape.points.last);
        canvas.drawOval(rect, paint);
        break;

      case AnnotateTool.text:
        if (shape.text == null || shape.textPosition == null) return;
        final textPainter = TextPainter(
          text: TextSpan(
            text: shape.text,
            style: TextStyle(color: shape.color, fontSize: shape.strokeWidth * 8, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, shape.textPosition!);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant AnnotatePainter oldDelegate) {
    return oldDelegate.shapes.length != shapes.length || oldDelegate.inProgress != inProgress;
  }
}
