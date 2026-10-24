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
  WingsPainter({this.flap = 0.5});

  /// 0–1, pozycja trzepotu.
  final double flap;

  // Od zewnątrz do środka, jak pióra na ścianie lokalu.
  static const _layers = [
    Color(0xFF8A2A9B),
    Color(0xFF2F6FE0),
    Color(0xFF2BAE66),
    Color(0xFFF7C923),
    Color(0xFFF39237),
    Color(0xFFE8332A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final origin = size.center(Offset.zero);
    // Pióra mieszczą się w polu widżetu, żeby nic nie było ucięte.
    final maxLen = math.min(size.width / 2 * 0.98, size.height / 2 / 0.74);
    final tilt = (flap - 0.5) * 0.12;
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.scale(side, 1);
      canvas.rotate(-tilt);
      _wing(canvas, maxLen);
      canvas.restore();
    }
  }

  void _wing(Canvas canvas, double maxLen) {
    const feathers = 7;
    for (var layer = 0; layer < _layers.length; layer++) {
      final color = _layers[layer];
      final len = maxLen * (1 - layer * 0.13);
      final stagger = layer.isEven ? 0.0 : 0.5;
      final paint = Paint()..style = PaintingStyle.fill;
      for (var f = 0; f < feathers; f++) {
        final t = (f + stagger) / (feathers - 0.5);
        // Pióra rozkładają się od skosu w górę do lekkiego opadu.
        final angle = -0.8 + t * 1.5;
        final dir = Offset(math.cos(angle), math.sin(angle));
        final normal = Offset(-dir.dy, dir.dx);
        final base = dir * (maxLen * 0.14);
        final featherLen = len * (1 - (t - 0.35).abs() * 0.35);
        final tip = dir * featherLen;
        final mid = Offset.lerp(base, tip, 0.62)!;
        final w = featherLen * 0.19;
        final path = Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(mid.dx + normal.dx * w, mid.dy + normal.dy * w, tip.dx, tip.dy)
          ..quadraticBezierTo(mid.dx - normal.dx * w, mid.dy - normal.dy * w, base.dx, base.dy)
          ..close();
        paint.shader = LinearGradient(colors: [Color.lerp(color, Colors.white, 0.25)!, color])
            .createShader(Rect.fromPoints(base, tip));
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(WingsPainter old) => old.flap != flap;
}
