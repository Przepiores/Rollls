import 'package:flutter/material.dart';

/// Czarno-biała szachownica jak na opakowaniach i podłodze lokalu.
class CheckerBand extends StatelessWidget {
  const CheckerBand({super.key, this.height = 14, this.cell = 14});
  final double height;
  final double cell;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: CheckerPainter(
          cell: cell,
          a: dark ? const Color(0xFFF4F0FA) : const Color(0xFF15121C),
          b: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}

class CheckerPainter extends CustomPainter {
  CheckerPainter({required this.cell, required this.a, required this.b});
  final double cell;
  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    final pa = Paint()..color = a;
    canvas.drawRect(Offset.zero & size, Paint()..color = b);
    final cols = (size.width / cell).ceil();
    final rows = (size.height / cell).ceil();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if ((r + c).isEven) canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell, cell), pa);
      }
    }
  }

  @override
  bool shouldRepaint(CheckerPainter old) => old.a != a || old.b != b || old.cell != cell;
}
