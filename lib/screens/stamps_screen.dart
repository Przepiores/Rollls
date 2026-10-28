import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../widgets/common.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/stamp_card.dart';
import '../widgets/wings.dart';

class StampsScreen extends ConsumerWidget {
  const StampsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    return Scaffold(
      appBar: brandAppBar(context, l.tabStamps, color: RollColors.yellow),
      body: session == null ? const _SignIn() : const _Card(),
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final card = ref.watch(stampCardProvider);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        StampCardView(card: card),
        const SizedBox(height: 14),
        if (card.rewardReady)
          Center(
            child: RainbowWings(
              width: 260,
              height: 150,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: RollColors.yellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: ink, width: 2),
                  boxShadow: neonGlow(RollColors.yellow),
                ),
                child: const Icon(Icons.icecream, color: ink, size: 30),
              ),
            ),
          ),
        Text(
          card.rewardReady ? l.rewardReady : l.stampsToReward(card.remaining),
          style: text.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
          textAlign: TextAlign.center,
        ),
        Text(l.stampsProgress(card.stamps, 10), textAlign: TextAlign.center, style: text.bodyMedium),
        const SizedBox(height: 22),
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: card.rewardReady ? RollColors.lime : RollColors.purple, width: 3),
              boxShadow: neonGlow(card.rewardReady ? RollColors.lime : neonPink),
            ),
            // W wersji z Firebase kod zawiera krótkotrwały token, a nie samo id klienta.
            child: QrImageView(data: 'icerolls:demo-customer', size: 190, backgroundColor: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        Text(card.rewardReady ? l.rewardHint : l.showCode, textAlign: TextAlign.center, style: text.bodyMedium),
        const SizedBox(height: 24),
        Text(l.rewardsHistory, style: text.titleMedium),
        const SizedBox(height: 6),
        if (card.rewardsRedeemed == 0)
          Text(l.noRewardsYet)
        else
          for (var i = 0; i < card.rewardsRedeemed; i++)
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.icecream), title: Text(l.freeIceCream)),
      ],
    );
  }
}

class _SignIn extends ConsumerWidget {
  const _SignIn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final signIn = ref.read(sessionProvider.notifier).signInDemo;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Opacity(
          opacity: 0.35,
          child: IgnorePointer(child: StampCardView(card: StampCard())),
        ),
        const SizedBox(height: 24),
        Text(l.loginForStamps, style: text.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(l.loginForStampsBody, style: text.bodyLarge, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: signIn,
          icon: const Icon(Icons.g_mobiledata, size: 28),
          label: Text(l.loginGoogle),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: signIn, icon: const Icon(Icons.apple), label: Text(l.loginApple)),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: signIn, icon: const Icon(Icons.mail_outline), label: Text(l.loginEmail)),
        const SizedBox(height: 14),
        Text(l.demoLoginNote, textAlign: TextAlign.center, style: text.bodySmall),
      ],
    );
  }
}
