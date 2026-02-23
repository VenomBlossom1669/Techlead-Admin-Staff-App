import 'dart:ui';

import 'package:flutter/material.dart';

class BorderAnimationPainter extends CustomPainter {
  final double progress;

  BorderAnimationPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.tealAccent,
          Colors.tealAccent,
          Colors.tealAccent,
        ],
        stops: [progress - 0.2, progress, progress + 0.2],
        tileMode: TileMode.mirror,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(15),
    );

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
