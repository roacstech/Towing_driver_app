import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const GoogleLogo({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _GoogleLogoPainter(color: color),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  final Color? color;

  _GoogleLogoPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // 24x24 reference grid
    final double scale = size.width / 24.0;
    // Optical center alignment
    final double dx = (size.width - 23.5 * scale) / 2;
    final double dy = (size.height - 24.0 * scale) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale, scale);

    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Red Top Segment
    final Path redPath = Path()
      ..moveTo(12, 5)
      ..cubicTo(13.8, 5, 15.4, 5.6, 16.7, 6.8)
      ..lineTo(20.2, 3.3)
      ..cubicTo(18.1, 1.3, 15.2, 0, 12, 0)
      ..cubicTo(7.4, 0, 3.4, 2.6, 1.4, 6.5)
      ..lineTo(5.5, 9.7)
      ..cubicTo(6.5, 7.1, 9, 5, 12, 5)
      ..close();
    paint.color = color ?? const Color(0xFFEA4335);
    canvas.drawPath(redPath, paint);

    // 2. Yellow Left Segment
    final Path yellowPath = Path()
      ..moveTo(5.5, 9.7)
      ..cubicTo(5.2, 10.4, 5, 11.2, 5, 12)
      ..cubicTo(5, 12.8, 5.2, 13.6, 5.5, 14.3)
      ..lineTo(1.4, 17.5)
      ..cubicTo(0.5, 15.8, 0, 14, 0, 12)
      ..cubicTo(0, 10, 0.5, 8.2, 1.4, 6.5)
      ..lineTo(5.5, 9.7)
      ..close();
    paint.color = color ?? const Color(0xFFFBBC05);
    canvas.drawPath(yellowPath, paint);

    // 3. Green Bottom Segment
    final Path greenPath = Path()
      ..moveTo(12, 19)
      ..cubicTo(9, 19, 6.5, 16.9, 5.5, 14.3)
      ..lineTo(1.4, 17.5)
      ..cubicTo(3.4, 21.4, 7.4, 24, 12, 24)
      ..cubicTo(15.2, 24, 18, 22.9, 20, 21)
      ..lineTo(16.1, 18)
      ..cubicTo(15, 18.7, 13.6, 19, 12, 19)
      ..close();
    paint.color = color ?? const Color(0xFF34A853);
    canvas.drawPath(greenPath, paint);

    // 4. Blue Right / Crossbar Segment
    final Path bluePath = Path()
      ..moveTo(23.5, 12.3)
      ..cubicTo(23.5, 11.5, 23.4, 10.8, 23.3, 10)
      ..lineTo(12, 10)
      ..lineTo(12, 14.6)
      ..lineTo(18.5, 14.6)
      ..cubicTo(18.2, 16.1, 17.4, 17.4, 16.1, 18.3)
      ..lineTo(20, 21.3)
      ..cubicTo(22.3, 19.2, 23.5, 16.1, 23.5, 12.3)
      ..close();
    paint.color = color ?? const Color(0xFF4285F4);
    canvas.drawPath(bluePath, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
