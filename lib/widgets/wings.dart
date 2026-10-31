import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Tęczowe skrzydła jak na ścianie lokalu, nieruchome.
class RainbowWings extends StatelessWidget {
  const RainbowWings({super.key, this.width = 300, this.height = 170, this.child});
  final double width;
  final double height;

  /// To, co siedzi między skrzydłami (np. logo).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: WingsPainter())),
          ?child,
        ],
      ),
    );
  }
}

class WingsPainter extends CustomPainter {
  WingsPainter({this.open = 1});

  /// 0–1, rozłożenie skrzydeł: 0 to pióra schowane za środkiem, 1 to pełne skrzydła.
  final double open;

  // Rzędy piór od zewnątrz do środka, jak na ścianie lokalu:
  // fiolet i błękit na końcach, przez zieleń, żółty i pomarańcz do różu przy środku.
  static const _rows = [
    Color(0xFF8B4FD8),
    Color(0xFF4F7BF0),
    Color(0xFF3FB8F0),
    Color(0xFF3CC77A),
    Color(0xFFF5D03B),
    Color(0xFFF7943A),
    Color(0xFFF2557A),
  ];

  static const _feathersPerRow = 15;

  // Wachlarz piór: od prawie pionowo w górę do prawie pionowo w dół (radiany, 0 = poziomo na zewnątrz).
  static const _fanTop = -1.35;
  static const _fanBottom = 1.45;

  // Obrys prawego skrzydła w polu od -1 do 1, środek w (0, 0), y rośnie w dół.
  // Skrzydło rozłożone w górę i na zewnątrz, a dolna krawędź zwęża się skosem do środka pod logo.
  // Kąty kolejnych punktów rosną, więc każdy promień ze środka trafia w obrys dokładnie raz.
  static const _outline = [
    Offset(0.10, -0.55),
    Offset(0.35, -0.80),
    Offset(0.65, -0.97),
    Offset(0.90, -1.00),
    Offset(1.00, -0.70),
    Offset(1.00, -0.30),
    Offset(0.92, 0.05),
    Offset(0.70, 0.35),
    Offset(0.45, 0.62),
    Offset(0.20, 0.88),
    Offset(0.06, 1.00),
  ];

  /// Odległość od środka do obrysu w kierunku [angle] (w polu od -1 do 1).
  static double _outlineRadius(double angle) {
    final dir = Offset(math.cos(angle), math.sin(angle));
    for (var i = 0; i < _outline.length - 1; i++) {
      final a = _outline[i];
      final b = _outline[i + 1];
      if (angle < a.direction || angle > b.direction) continue;
      // Przecięcie promienia ze środka z odcinkiem a–b.
      final e = b - a;
      final denom = dir.dx * e.dy - dir.dy * e.dx;
      if (denom.abs() < 1e-9) return a.distance;
      return (a.dx * e.dy - a.dy * e.dx) / denom;
    }
    return angle < _outline.first.direction ? _outline.first.distance : _outline.last.distance;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final origin = size.center(Offset.zero);
    // Obrys wpisany w pole widżetu, więc nic nie jest ucięte.
    final sx = size.width / 2 * 0.97;
    final sy = size.height / 2 * 0.97;
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.scale(side, 1);
      _wing(canvas, sx, sy);
      canvas.restore();
    }
  }

  void _wing(Canvas canvas, double sx, double sy) {
    final light = Paint()..style = PaintingStyle.fill;
    final shade = Paint()..style = PaintingStyle.fill;
    final spine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = Colors.white.withValues(alpha: 0.35);
    for (var row = 0; row < _rows.length; row++) {
      final color = _rows[row];
      final next = _rows[math.min(row + 1, _rows.length - 1)];
      final reach = 1 - row * 0.115;
      // Co drugi rząd przesunięty o pół pióra, żeby tylne pióra wystawały między przednimi.
      final stagger = row.isEven ? 0.0 : 0.5;
      final count = _feathersPerRow - (row.isEven ? 0 : 1);
      for (var f = 0; f < count; f++) {
        final t = (f + stagger) / (_feathersPerRow - 1);
        // Zewnętrzne rzędy rozkładają się pierwsze, górne pióra chwilę przed dolnymi.
        final delay = row * 0.05 + t * 0.1;
        final p = Curves.easeOutBack.transform(((open - delay) / (1 - 0.4)).clamp(0.0, 1.0));
        if (p <= 0) continue;
        final target = _fanTop + (_fanBottom - _fanTop) * t;
        // Złożone pióra leżą płasko lekko w górę, rozkładają się do wachlarza.
        // Sprężyste dobicie nie może przerzucić dolnych piór za środek.
        final angle = math.min(-0.2 + (target + 0.2) * p, _fanBottom);
        final dir = Offset(math.cos(angle), math.sin(angle));
        final normal = Offset(-dir.dy, dir.dx);
        // Długość z docelowego kierunku, żeby obracające się pióro nie wystawało poza obrys.
        // Kierunek w polu od -1 do 1 różni się od ekranowego, bo pole jest rozciągnięte.
        final unitAngle = math.atan2(math.sin(target) / sy, math.cos(target) / sx);
        final r = _outlineRadius(unitAngle);
        final edge = r * Offset(math.cos(unitAngle) * sx, math.sin(unitAngle) * sy).distance;
        final rootLen = edge * 0.3;
        final base = dir * rootLen;
        final len = (edge - rootLen) * reach * (0.2 + 0.8 * p);
        if (len <= 0) continue;
        final tip = dir * (rootLen + len);
        final w = math.max(len * 0.13, 2.5);
        // Kolor lekko przechodzi w kolejny rząd, tak jak na ścianie.
        final c = Color.lerp(color, next, ((f * 37) % 10) / 40)!;
        final c1 = base + dir * (len * 0.3);
        final c2 = base + dir * (len * 0.72);
        // Pióro jak zgięty papier: jasna i ciemniejsza połowa przy grzbiecie.
        final top = Path()
          ..moveTo(base.dx, base.dy)
          ..cubicTo(
            c1.dx - normal.dx * w,
            c1.dy - normal.dy * w,
            c2.dx - normal.dx * w * 0.8,
            c2.dy - normal.dy * w * 0.8,
            tip.dx,
            tip.dy,
          )
          ..close();
        final bottom = Path()
          ..moveTo(base.dx, base.dy)
          ..cubicTo(
            c1.dx + normal.dx * w,
            c1.dy + normal.dy * w,
            c2.dx + normal.dx * w * 0.8,
            c2.dy + normal.dy * w * 0.8,
            tip.dx,
            tip.dy,
          )
          ..close();
        final rect = Rect.fromPoints(base, tip);
        light.shader = LinearGradient(colors: [c, Color.lerp(c, Colors.white, 0.3)!]).createShader(rect);
        shade.shader = LinearGradient(colors: [Color.lerp(c, Colors.black, 0.22)!, Color.lerp(c, Colors.black, 0.08)!])
            .createShader(rect);
        canvas.drawPath(top, light);
        canvas.drawPath(bottom, shade);
        canvas.drawLine(base + dir * (len * 0.15), tip - dir * (len * 0.08), spine);
      }
    }
  }

  @override
  bool shouldRepaint(WingsPainter old) => old.open != open;
}
