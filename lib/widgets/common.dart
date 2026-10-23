import 'package:flutter/material.dart';

import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'swirl.dart';

class BadgeChip extends StatelessWidget {
  const BadgeChip(this.badge, {super.key});
  final MenuBadge badge;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (label, color) = switch (badge) {
      MenuBadge.isNew => (l.badgeNew, RollColors.lime),
      MenuBadge.bestseller => (l.badgeBestseller, RollColors.yellow),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
      child: Text(
        label,
        style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }
}

/// Zdjęcie produktu albo kolorowa spiralka, gdy zdjęcia jeszcze nie ma.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.item, required this.color, this.radius = 16});
  final MenuItem item;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: item.image != null
          ? Image.asset(item.image!, fit: BoxFit.cover)
          : ColoredBox(
              color: color.withValues(alpha: 0.18),
              child: LayoutBuilder(
                builder: (_, c) => Center(
                  child: Swirl(color: color, size: c.biggest.shortestSide * 0.55),
                ),
              ),
            ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 12, 10),
    child: Row(
      children: [
        Expanded(child: Text(text, style: Theme.of(context).textTheme.titleLarge)),
        ?trailing,
      ],
    ),
  );
}
