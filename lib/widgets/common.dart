import 'package:flutter/material.dart';

import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'checker.dart';
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

/// Tęczowy pasek w kolorach sześciu rolek z logo.
class RainbowStripe extends StatelessWidget {
  const RainbowStripe({super.key, this.height = 6});
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: const BoxDecoration(gradient: rainbow),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.color = RollColors.pink});
  final String text;
  final Widget? trailing;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 12, 10),
    child: Row(
      children: [
        Swirl(color: color, size: 22),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.titleLarge)),
        ?trailing,
      ],
    ),
  );
}

/// Ramka kart z treścią, ta sama na wszystkich ekranach (kolor rolki, 2 px, promień 20).
/// Zdjęcia (banery, promocje) mają grubszą ramkę 3 px z neonową poświatą i promień 24.
RoundedRectangleBorder outlinedCard(Color color) => RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(20),
  side: BorderSide(color: color, width: 2),
);

/// Pasek tytułu z kolorową spiralką i tęczowym paskiem pod spodem.
PreferredSizeWidget brandAppBar(BuildContext context, String title, {Color color = RollColors.pink}) => AppBar(
  title: Row(
    children: [
      Swirl(color: color, size: 26),
      const SizedBox(width: 10),
      Flexible(child: Text(title)),
    ],
  ),
  bottom: const PreferredSize(preferredSize: Size.fromHeight(4), child: RainbowStripe(height: 4)),
);

/// Wspólny nagłówek zakładek: szachownica, tytuł z kolorową spiralką i logo,
/// tęczowy pasek. Stoi nad treścią zakładek, więc przy przełączaniu nic nie skacze,
/// zmienia się tylko tytuł i kolor spiralki.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.title, required this.color});
  final String title;
  final Color color;

  static const _duration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CheckerBand(height: 12, cell: 12),
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: color),
                      duration: _duration,
                      builder: (_, c, _) => Swirl(color: c ?? color, size: 26),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: _duration,
                        // Stary tytuł znika, zanim pojawi się nowy, żeby się nie nakładały.
                        switchInCurve: const Interval(0.4, 1, curve: Curves.easeOut),
                        switchOutCurve: const Interval(0.6, 1, curve: Curves.easeIn),
                        layoutBuilder: (current, previous) =>
                            Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
                        child: Text(
                          title,
                          key: ValueKey(title),
                          style: theme.appBarTheme.titleTextStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: neonGlow(color, blur: 8),
                      ),
                      child: Image.asset('assets/images/logo_emblem.png', semanticLabel: 'Ice Rolls'),
                    ),
                  ],
                ),
              ),
            ),
            const RainbowStripe(height: 4),
          ],
        ),
      ),
    );
  }
}
