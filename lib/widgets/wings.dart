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

  static const _feathersPerRow = 15;

  // Wachlarz piór: od prawie pionowo w górę do pionowo w dół (radiany, 0 = poziomo na zewnątrz).
  static const _fanTop = -1.42;
  static const _fanBottom = 1.5;

  // Oba skrzydła razem tworzą serce: szerokie u góry, zwężone w szpic na dole.
  // Krzywa serca x = 16 sin³t, y = -(13 cos t - 5 cos 2t - 2 cos 3t - cos 4t), środek w (0, 0):
  // wcięcie u góry na y = -5, czubki łuków na y ≈ -12, szpic na y = 17.
  static const _heartHalfWidth = 16.0;
  static const _heartTop = 12.0;
  static const _heartBottom = 17.0;

  /// Odległość od środka do krawędzi prawej połówki serca, próbkowana co kąt (od -π/2 do π/2).
  static final List<double> _heartRadius = _buildHeartRadius();

  static List<double> _buildHeartRadius() {
    const samples = 181;
    final radius = List<double>.filled(samples, 0);
    for (var i = 0; i <= 2000; i++) {
      final t = math.pi * i / 2000;
      final x = 16 * math.pow(math.sin(t), 3);
      final y = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t));
      final angle = math.atan2(y, x);
      final k = ((angle + math.pi / 2) / math.pi * (samples - 1)).round().clamp(0, samples - 1);
      radius[k] = math.max(radius[k], math.sqrt(x * x + y * y));
    }
    // Uzupełnij kąty, w które nie trafiła żadna próbka.
    for (var k = 1; k < samples; k++) {
      if (radius[k] == 0) radius[k] = radius[k - 1];
    }
    return radius;
  }

  /// Krawędź serca w kierunku [dir], w jednostkach krzywej, rozciągnięta o skale [sx], [sy].
  static double _heartEdge(Offset dir, double sx, double sy) {
    // Kąt na niezniekształconej krzywej, w którym leży ten kierunek po rozciągnięciu.
    final angle = math.atan2(dir.dy / sy, dir.dx / sx);
    final k = ((angle + math.pi / 2) / math.pi * (_heartRadius.length - 1)).clamp(0.0, _heartRadius.length - 1.0);
    final lo = k.floor();
    final hi = math.min(lo + 1, _heartRadius.length - 1);
    final r = _heartRadius[lo] + (_heartRadius[hi] - _heartRadius[lo]) * (k - lo);
    return r * math.sqrt(math.pow(math.cos(angle) * sx, 2) + math.pow(math.sin(angle) * sy, 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Serce wpisane w pole widżetu, więc nic nie jest ucięte; najwyżej lekko poszerzone.
    final sy = size.height * 0.97 / (_heartTop + _heartBottom);
    // Środek krzywej jest trochę poniżej środka pola, bo szpic na dole sięga dalej niż łuki u góry.
    final origin = size.center(Offset(0, -(_heartBottom - _heartTop) / 2 * sy));
    final sx = math.min(size.width / 2 * 0.97 / _heartHalfWidth, sy * 1.5);
    final tilt = (flap - 0.5) * 0.1;
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.scale(side, 1);
      canvas.rotate(-tilt);
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
        // Sprężyste dobicie nie może przerzucić dolnych piór za szpic serca.
        final angle = math.min(-0.2 + (target + 0.2) * p, _fanBottom);
        final dir = Offset(math.cos(angle), math.sin(angle));
        final normal = Offset(-dir.dy, dir.dx);
        // Długość z docelowego kierunku, żeby obracające się pióro nie wystawało poza serce.
        final edge = _heartEdge(Offset(math.cos(target), math.sin(target)), sx, sy);
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
  bool shouldRepaint(WingsPainter old) => old.flap != flap || old.open != open;
}
