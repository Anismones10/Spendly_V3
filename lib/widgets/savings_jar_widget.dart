import 'package:flutter/material.dart';
import 'dart:math' as math;

class SavingsJarWidget extends StatelessWidget {
  final double totalSaved;
  const SavingsJarWidget({super.key, required this.totalSaved});

  @override
  Widget build(BuildContext context) {
    // Represent fill level - scales with savings
    final fill = (totalSaved / 10000).clamp(0.0, 1.0);

    return SizedBox(
      width: 180,
      height: 200,
      child: CustomPaint(
        painter: _JarPainter(fill: fill),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('💰', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

class _JarPainter extends CustomPainter {
  final double fill;
  _JarPainter({required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Jar body
    final jarPaint = Paint()
      ..color = const Color(0xFF90CAF9).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF42A5F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final jarPath = Path()
      ..moveTo(w * 0.2, h * 0.15)
      ..lineTo(w * 0.1, h * 0.25)
      ..lineTo(w * 0.1, h * 0.85)
      ..quadraticBezierTo(w * 0.1, h * 0.95, w * 0.2, h * 0.95)
      ..lineTo(w * 0.8, h * 0.95)
      ..quadraticBezierTo(w * 0.9, h * 0.95, w * 0.9, h * 0.85)
      ..lineTo(w * 0.9, h * 0.25)
      ..lineTo(w * 0.8, h * 0.15)
      ..close();

    canvas.drawPath(jarPath, jarPaint);

    // Fill
    if (fill > 0) {
      final fillTop = h * 0.95 - (h * 0.7 * fill);
      final fillPaint = Paint()
        ..color = const Color(0xFF4CAF50).withOpacity(0.6)
        ..style = PaintingStyle.fill;

      final fillPath = Path()
        ..moveTo(w * 0.1, fillTop)
        ..lineTo(w * 0.9, fillTop)
        ..lineTo(w * 0.9, h * 0.85)
        ..quadraticBezierTo(w * 0.9, h * 0.95, w * 0.8, h * 0.95)
        ..lineTo(w * 0.2, h * 0.95)
        ..quadraticBezierTo(w * 0.1, h * 0.95, w * 0.1, h * 0.85)
        ..close();

      // Clip to jar
      canvas.save();
      canvas.clipPath(jarPath);
      canvas.drawPath(fillPath, fillPaint);
      canvas.restore();

      // Wave on top of fill
      final wavePaint = Paint()
        ..color = const Color(0xFF4CAF50).withOpacity(0.4)
        ..style = PaintingStyle.fill;

      final wavePath = Path();
      wavePath.moveTo(w * 0.1, fillTop);
      for (double x = w * 0.1; x <= w * 0.9; x += 5) {
        final y = fillTop + math.sin((x / w * 2 * math.pi)) * 4;
        wavePath.lineTo(x, y);
      }
      wavePath.lineTo(w * 0.9, fillTop - 8);
      wavePath.lineTo(w * 0.1, fillTop - 8);
      wavePath.close();

      canvas.save();
      canvas.clipPath(jarPath);
      canvas.drawPath(wavePath, wavePaint);
      canvas.restore();
    }

    canvas.drawPath(jarPath, borderPaint);

    // Jar lid/top
    final lidPaint = Paint()
      ..color = const Color(0xFF42A5F5)
      ..style = PaintingStyle.fill;

    final lidPath = Path()
      ..moveTo(w * 0.18, h * 0.08)
      ..lineTo(w * 0.82, h * 0.08)
      ..lineTo(w * 0.8, h * 0.16)
      ..lineTo(w * 0.2, h * 0.16)
      ..close();

    canvas.drawPath(lidPath, lidPaint);

    // Coin slot on lid
    final slotPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.45, h * 0.08),
      Offset(w * 0.55, h * 0.08),
      slotPaint,
    );
  }

  @override
  bool shouldRepaint(_JarPainter old) => old.fill != fill;
}
