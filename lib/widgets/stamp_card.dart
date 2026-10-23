import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme.dart';
import 'checker.dart';
import 'swirl.dart';

/// Karta 10 pieczątek. Zebrane pola pokazują kolorowe rolki z logo.
class StampCardView extends StatelessWidget {
  const StampCardView({super.key, required this.card, this.compact = false});
  final StampCard card;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Tęczowa ramka z pastelowym wnętrzem.
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        gradient: rainbow,
        borderRadius: BorderRadius.circular(26),
        boxShadow: neonGlow(RollColors.pink, blur: 16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark ? const [nightCard, Color(0xFF3A1E4F)] : const [paper, Color(0xFFFFE3F1)],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const CheckerBand(height: 12, cell: 12),
            Padding(
              padding: EdgeInsets.all(compact ? 14 : 18),
              child: GridView.count(
                crossAxisCount: 5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: compact ? 8 : 12,
                crossAxisSpacing: compact ? 8 : 12,
                children: [for (var i = 0; i < StampCard.goal; i++) _Slot(index: i, filled: i < card.stamps)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.index, required this.filled});
  final int index;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isReward = index == StampCard.goal - 1;
    final color = RollColors.all[index % RollColors.all.length];
    return Semantics(
      label: filled ? 'Pieczątka ${index + 1}' : 'Puste pole ${index + 1}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled
              ? scheme.surface
              : isReward
              ? RollColors.yellow.withValues(alpha: 0.35)
              : color.withValues(alpha: 0.1),
          border: Border.all(
            color: filled ? color : color.withValues(alpha: 0.55),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Center(
          child: filled
              ? TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => Swirl(color: color, size: 30, progress: v),
                )
              : isReward
              ? Icon(Icons.icecream, color: scheme.onSurface.withValues(alpha: 0.7))
              : null,
        ),
      ),
    );
  }
}
