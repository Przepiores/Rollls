import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/stamp_card.dart';

/// Panel sklepu. W prototypie działa nabijanie pieczątek, reszta to podgląd.
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  bool _scanned = false;
  int _count = 1;

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final card = ref.watch(stampCardProvider);
    final notifier = ref.read(stampCardProvider.notifier);
    final text = Theme.of(context).textTheme;

    final tools = [
      (Icons.restaurant_menu, l.panelMenu),
      (Icons.local_offer_outlined, l.panelPromos),
      (Icons.campaign_outlined, l.panelPush),
      (Icons.schedule, l.panelHours),
      (Icons.bar_chart, l.panelStats),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.shopPanel)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l.scanCustomer, style: text.titleLarge),
          const SizedBox(height: 10),
          if (!_scanned)
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
              ),
              child: Center(
                child: FilledButton.icon(
                  onPressed: () => setState(() => _scanned = true),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(l.simulateScan),
                ),
              ),
            )
          else ...[
            StampCardView(card: card, compact: true),
            const SizedBox(height: 14),
            if (card.rewardReady)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: RollColors.lime, foregroundColor: ink),
                onPressed: () {
                  notifier.redeem();
                  _toast(l.rewardRedeemed);
                },
                icon: const Icon(Icons.icecream),
                label: Text(l.redeemReward),
              )
            else
              Row(
                children: [
                  IconButton.outlined(
                    onPressed: _count > 1 ? () => setState(() => _count--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text('$_count', textAlign: TextAlign.center, style: text.headlineSmall),
                  ),
                  IconButton.outlined(
                    onPressed: _count < card.remaining ? () => setState(() => _count++) : null,
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        notifier.add(_count);
                        _toast(l.stampsAdded(_count));
                        setState(() => _count = 1);
                      },
                      child: Text(l.addStamps),
                    ),
                  ),
                ],
              ),
          ],
          const SizedBox(height: 28),
          for (final (icon, label) in tools)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(icon),
                title: Text(label, style: text.titleMedium),
                subtitle: Text(l.comingSoon),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
        ],
      ),
    );
  }
}
