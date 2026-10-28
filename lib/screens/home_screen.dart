import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../data/opening_hours.dart';
import '../data/menu_data.dart';
import '../data/shop_data.dart';
import '../l10n/app_localizations.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/checker.dart';
import '../widgets/common.dart';
import '../widgets/stamp_card.dart';
import '../widgets/swirl.dart';
import '../widgets/wings.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final session = ref.watch(sessionProvider);
    final card = ref.watch(stampCardProvider);
    final news = menuItems.where((i) => i.badges.contains(MenuBadge.isNew)).toList();
    final text = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const CheckerBand(),
          const RainbowStripe(),
          _GlassHero(greeting: l.greeting(session != null ? ', ${session.name}' : ''), tagline: l.tagline),
          SectionTitle(l.promotions, color: RollColors.lime),
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: promotions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _PromoCard(promo: promotions[i], locale: locale),
            ),
          ),
          SectionTitle(
            l.yourCard,
            color: RollColors.yellow,
            trailing: TextButton(onPressed: () => context.go('/stamps'), child: Text(l.tabStamps)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => context.go('/stamps'),
              child: session == null
                  ? Card(
                      color: tint(context, RollColors.yellow, light: 0.45, dark: 0.35),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(Icons.loyalty, size: 32),
                        title: Text(l.loginForStamps, style: text.titleMedium),
                        subtitle: Text(l.loginForStampsBody),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StampCardView(card: card, compact: true),
                        const SizedBox(height: 8),
                        Text(
                          card.rewardReady ? l.rewardReady : l.stampsToReward(card.remaining),
                          style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
            ),
          ),
          SectionTitle(
            l.news,
            color: RollColors.sky,
            trailing: TextButton(onPressed: () => context.go('/menu'), child: Text(l.seeMenu)),
          ),
          for (final item in news)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Card(
                color: tint(context, categories.firstWhere((c) => c.id == item.categoryId).color),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: SizedBox.square(
                    dimension: 56,
                    child: ProductImage(
                      item: item,
                      color: categories.firstWhere((c) => c.id == item.categoryId).color,
                      radius: 12,
                    ),
                  ),
                  title: Text(item.name.of(locale), style: text.titleMedium),
                  subtitle: Text(item.priceLabel),
                  trailing: const BadgeChip(MenuBadge.isNew),
                  onTap: () => context.go('/menu'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Nagłówek jak tafla szkła: rozmyte kolorowe rolki pod półprzezroczystą kartą.
class _GlassHero extends StatelessWidget {
  const _GlassHero({required this.greeting, required this.tagline});
  final String greeting;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = Theme.of(context).textTheme;
    final fg = dark ? Colors.white : ink;

    Widget blob(Color c, double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)]),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Stack(
        children: [
          // Kolorowe tło, które prześwituje przez szkło.
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: dark
                              ? const [Color(0xFF4A1F66), Color(0xFF2B1A45)]
                              : const [Color(0xFFFFD6EA), Color(0xFFE6D6FF)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(left: -30, top: -40, child: blob(neonPink, 170)),
                  Positioned(right: -20, top: -30, child: blob(RollColors.yellow, 140)),
                  Positioned(right: 60, bottom: -60, child: blob(RollColors.sky, 160)),
                  Positioned(left: 90, bottom: -50, child: blob(RollColors.lime, 120)),
                  const Positioned(right: 12, top: 10, child: Swirl(color: RollColors.purple, size: 56)),
                  const Positioned(left: 12, bottom: 10, child: Swirl(color: RollColors.pink, size: 40)),
                ],
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: dark ? 0.16 : 0.38),
                      Colors.white.withValues(alpha: dark ? 0.04 : 0.12),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: dark ? 0.3 : 0.8), width: 1.5),
                ),
                child: Column(
                  children: [
                    RainbowWings(
                      child: Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: neonGlow(Colors.white, blur: 12),
                        ),
                        child: ClipOval(child: Image.asset('assets/images/logo.png', semanticLabel: 'Ice Rolls')),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      greeting,
                      textAlign: TextAlign.center,
                      style: text.headlineMedium?.copyWith(color: fg),
                    ),
                    Text(
                      tagline,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: fg, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 12),
                    const OpenStatusPill(alignment: Alignment.center),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OpenStatusPill extends StatelessWidget {
  const OpenStatusPill({super.key, this.alignment = Alignment.centerLeft});
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final status = openStatus(shop.hours, DateTime.now());
    final (label, color) = switch (status) {
      OpenNow(:final closesAt) => (l.openUntil(formatTime(closesAt)), RollColors.lime),
      ClosedNow(:final opensAt, :final daysAhead) => (
        l.closedOpensAt(switch (daysAhead) {
          0 => l.today,
          1 => l.tomorrow,
          _ => l.days.split(',')[(DateTime.now().weekday - 1 + daysAhead) % 7],
        }, formatTime(opensAt)),
        RollColors.red,
      ),
    };
    return Align(
      alignment: alignment,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(99)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: neonGlow(color, blur: 6)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700, color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo, required this.locale});
  final Promotion promo;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fg = promo.image == null ? ink : Colors.white;
    return Container(
      width: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [promo.color, Color.lerp(promo.color, Colors.white, 0.45)!],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: promo.color, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (promo.image == null)
            Positioned(right: -18, bottom: -18, child: Swirl(color: Colors.white.withValues(alpha: 0.7), size: 90))
          else ...[
            Positioned.fill(child: Image.asset(promo.image!, fit: BoxFit.cover)),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x331C1030), Color(0xE61C1030)],
                    stops: [0.2, 0.75],
                  ),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: promo.image == null ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                Text(
                  promo.title.of(locale),
                  style: text.titleMedium?.copyWith(color: fg),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  promo.body.of(locale),
                  style: text.bodyMedium?.copyWith(color: fg),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
