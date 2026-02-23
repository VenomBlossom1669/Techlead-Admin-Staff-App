import 'dart:ui';
import 'package:flutter/cupertino.dart';

class CombinedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double curveHeight = 125;
    final Paint paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF003366), Color(0xFF0F52BA)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final Paint darkPaint = Paint()..color = const Color(0xFF002244);

    // Draw the gradient background for the top portion
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Now, we create a path for the curved section starting just above the login button
    Path path = Path();
    path.moveTo(0, size.height - curveHeight); // Start at the position just above the login button
    path.quadraticBezierTo(
        size.width / 2, size.height - curveHeight - 50, size.width, size.height - curveHeight); // Curve shape
    path.lineTo(size.width, size.height); // Bottom right corner
    path.lineTo(0, size.height); // Bottom left corner
    path.close();

    canvas.drawPath(path, darkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}