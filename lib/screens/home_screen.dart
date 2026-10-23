import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../data/opening_hours.dart';
import '../data/sample_data.dart';
import '../l10n/app_localizations.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/checker.dart';
import '../widgets/common.dart';
import '../widgets/stamp_card.dart';
import '../widgets/swirl.dart';

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
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              gradient: heroGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: neonGlow(neonPink, blur: 24),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(right: -6, top: -10, child: Swirl(color: RollColors.yellow, size: 54)),
                const Positioned(right: -4, bottom: -12, child: Swirl(color: RollColors.lime, size: 34)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: neonGlow(Colors.white, blur: 12),
                          ),
                          child: Image.asset('assets/images/logo.png', semanticLabel: 'Ice Rolls'),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.greeting(session != null ? ', ${session.name}' : ''),
                                style: text.headlineMedium?.copyWith(color: Colors.white),
                              ),
                              Text(
                                l.tagline,
                                style: text.bodyMedium?.copyWith(color: Colors.white, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const OpenStatusPill(),
                  ],
                ),
              ],
            ),
          ),
          SectionTitle(l.promotions, color: RollColors.lime),
          SizedBox(
            height: 136,
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

class OpenStatusPill extends StatelessWidget {
  const OpenStatusPill({super.key});

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
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: ink, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(color: ink, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800, color: ink),
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
    return Container(
      width: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [promo.color, Color.lerp(promo.color, Colors.white, 0.45)!],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ink, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(right: -18, bottom: -18, child: Swirl(color: Colors.white.withValues(alpha: 0.7), size: 90)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.title.of(locale),
                  style: text.titleMedium?.copyWith(color: ink),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    promo.body.of(locale),
                    style: text.bodyMedium?.copyWith(color: ink),
                    overflow: TextOverflow.fade,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
