import 'package:flutter/material.dart';

/// Custom painter widget that renders Google's official 4-color "G" logo vector.
class GoogleLogoIcon extends StatelessWidget {
  final double size;

  const GoogleLogoIcon({super.key, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48.0;
    canvas.scale(scale, scale);

    // Red path (top arc)
    final redPath = Path()
      ..moveTo(24, 9.5)
      ..cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1)
      ..relativeLineTo(6.85, -6.85)
      ..cubicTo(35.9, 2.38, 30.47, 0, 24, 0)
      ..cubicTo(14.66, 0, 6.51, 5.38, 2.56, 13.22)
      ..relativeLineTo(7.98, 6.19)
      ..cubicTo(12.43, 13.72, 17.74, 9.5, 24, 9.5);

    // Blue path (right bar + top right)
    final bluePath = Path()
      ..moveTo(46.98, 24.55)
      ..cubicTo(46.98, 22.98, 46.83, 21.42, 46.54, 20.0)
      ..lineTo(24, 20.0)
      ..relativeLineTo(0, 9.02)
      ..relativeLineTo(12.94, 0)
      ..cubicTo(36.36, 31.98, 34.68, 34.5, 32.16, 36.2)
      ..relativeLineTo(7.73, 6.0)
      ..cubicTo(44.4, 38.02, 46.98, 31.84, 46.98, 24.55);

    // Yellow path (left arc)
    final yellowPath = Path()
      ..moveTo(10.53, 28.59)
      ..cubicTo(10.05, 27.14, 9.77, 25.6, 9.77, 24.0)
      ..cubicTo(9.77, 22.4, 10.05, 20.86, 10.53, 19.41)
      ..relativeLineTo(-7.98, -6.19)
      ..cubicTo(0.92, 16.46, 0, 20.12, 0, 24.0)
      ..cubicTo(0, 27.88, 0.92, 31.54, 2.56, 34.78)
      ..relativeLineTo(7.97, -6.19);

    // Green path (bottom arc)
    final greenPath = Path()
      ..moveTo(24, 48)
      ..cubicTo(30.48, 48, 35.93, 45.87, 39.89, 42.19)
      ..relativeLineTo(-7.73, -6.0)
      ..cubicTo(30.01, 37.64, 27.24, 38.5, 24, 38.5)
      ..cubicTo(17.74, 38.5, 12.43, 34.28, 10.53, 28.59)
      ..relativeLineTo(-7.98, 6.19)
      ..cubicTo(6.51, 42.62, 14.66, 48, 24, 48);

    canvas.drawPath(
      redPath,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
    canvas.drawPath(
      bluePath,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
    canvas.drawPath(
      yellowPath,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
    canvas.drawPath(
      greenPath,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
