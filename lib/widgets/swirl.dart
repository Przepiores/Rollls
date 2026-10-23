import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Spiralka jak rolki lodów w logo. Używana jako pieczątka i zastępcze zdjęcie.
class Swirl extends StatelessWidget {
  const Swirl({super.key, required this.color, this.size = 40, this.progress = 1});
  final Color color;
  final double size;

  /// 0–1, do animacji rysowania.
  final double progress;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _SwirlPainter(color, progress)),
  );
}

class _SwirlPainter extends CustomPainter {
  _SwirlPainter(this.color, this.progress);
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.shortestSide / 2 * 0.9;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.shortestSide * 0.09;
    const turns = 2.6;
    final path = Path();
    final steps = (120 * progress).round();
    for (var i = 0; i <= steps; i++) {
      final t = i / 120;
      final a = t * turns * 2 * math.pi;
      final r = maxR * t;
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SwirlPainter old) => old.color != color || old.progress != progress;
}
