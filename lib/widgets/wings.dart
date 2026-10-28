import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Tęczowe skrzydła jak na ścianie lokalu, z delikatnym trzepotem.
class RainbowWings extends StatefulWidget {
  const RainbowWings({super.key, this.width = 300, this.height = 170, this.child});
  final double width;
  final double height;

  /// To, co siedzi między skrzydłami (np. logo).
  final Widget? child;

  @override
  State<RainbowWings> createState() => _RainbowWingsState();
}

class _RainbowWingsState extends State<RainbowWings> with SingleTickerProviderStateMixin {
  late final AnimationController _flap = AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    reduce ? _flap.stop() : _flap.repeat(reverse: true);
  }

  @override
  void dispose() {
    _flap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _flap,
              builder: (_, _) => CustomPaint(painter: WingsPainter(flap: Curves.easeInOut.transform(_flap.value))),
            ),
          ),
          ?widget.child,
        ],
      ),
    );
  }
}

class WingsPainter extends CustomPainter {
  WingsPainter({this.flap = 0.5, this.open = 1});

  /// 0–1, pozycja trzepotu.
  final double flap;

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

  static const _feathersPerRow = 12;

  // Wachlarz piór: od prawie pionowo w górę do skosu w dół (radiany, 0 = poziomo na zewnątrz).
  static const _fanTop = -1.2;
  static const _fanBottom = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = size.center(Offset.zero);
    // Końce piór leżą na elipsie wpisanej w pole widżetu, więc nic nie jest ucięte.
    final rx = size.width / 2 * 0.98;
    final ry = size.height / 2 * 0.98;
    final tilt = (flap - 0.5) * 0.12;
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.scale(side, 1);
      canvas.rotate(-tilt);
      _wing(canvas, rx, ry);
      canvas.restore();
    }
  }

  void _wing(Canvas canvas, double rx, double ry) {
    final light = Paint()..style = PaintingStyle.fill;
    final shade = Paint()..style = PaintingStyle.fill;
    final spine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = Colors.white.withValues(alpha: 0.35);
    final rootLen = rx * 0.1;
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
        final angle = -0.2 + (target + 0.2) * p;
        final dir = Offset(math.cos(angle), math.sin(angle));
        final normal = Offset(-dir.dy, dir.dx);
        final edge = 1 / math.sqrt(math.pow(dir.dx / rx, 2) + math.pow(dir.dy / ry, 2));
        final base = dir * rootLen;
        // Najdłuższe pióra idą skosem w górę, dolne są krótsze, jak w prawdziwym skrzydle.
        final shape = 1 - 0.4 * math.pow((target + 0.55) / 1.55, 2);
        final len = (edge * shape - rootLen) * reach * (0.2 + 0.8 * p);
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
  bool shouldRepaint(WingsPainter old) => old.flap != flap || old.open != open;
}
