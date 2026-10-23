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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Image.asset('assets/images/logo.png', semanticLabel: 'Ice Rolls'),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.greeting(session != null ? ', ${session.name}' : ''), style: text.headlineMedium),
                      Text(l.tagline, style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(20, 14, 20, 0), child: OpenStatusPill()),
          SectionTitle(l.promotions),
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
            trailing: TextButton(onPressed: () => context.go('/stamps'), child: Text(l.tabStamps)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => context.go('/stamps'),
              child: session == null
                  ? Card(
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
            trailing: TextButton(onPressed: () => context.go('/menu'), child: Text(l.seeMenu)),
          ),
          for (final item in news)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Card(
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
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: promo.color, borderRadius: BorderRadius.circular(20)),
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
    );
  }
}
