import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../backend/backend.dart';
import '../l10n/app_localizations.dart';
import '../loyalty/stamp_claims.dart';
import '../loyalty/stamp_code.dart';
import '../widgets/common.dart';
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
    final backend = ref.read(backendProvider);
    final session = ref.watch(sessionProvider);
    final text = Theme.of(context).textTheme;

    final tools = [
      (Icons.restaurant_menu, l.panelMenu),
      (Icons.local_offer_outlined, l.panelPromos),
      (Icons.campaign_outlined, l.panelPush),
      (Icons.schedule, l.panelHours),
      (Icons.bar_chart, l.panelStats),
    ];

    return Scaffold(
      appBar: brandAppBar(context, l.shopPanel, color: RollColors.lime),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _CounterSticker(),
          const SizedBox(height: 28),
          const _IssueStampCode(),
          const SizedBox(height: 28),
          Text(l.scanCustomer, style: text.titleLarge),
          const SizedBox(height: 10),
          // Z Firebase klienta trzeba naprawdę zeskanować: to zrobi panel sklepu.
          if (backend.isRemote)
            Text(l.customerScanLater, style: text.bodyMedium)
          else if (!_scanned)
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
                onPressed: () async {
                  await backend.redeemReward(LocalBackend.demoUid);
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
                      onPressed: () async {
                        await backend.addStamps(LocalBackend.demoUid, _count);
                        _toast(l.stampsAdded(_count));
                        setState(() => _count = 1);
                      },
                      child: Text(l.addStamps),
                    ),
                  ),
                ],
              ),
          ],
          if (backend.isRemote && (session?.isOwner ?? false)) ...[
            const SizedBox(height: 28),
            const _UploadBundledData(),
          ],
          const SizedBox(height: 28),
          for (final (i, (icon, label)) in tools.indexed)
            Card(
              color: tint(context, RollColors.all[i % RollColors.all.length], light: 0.3),
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

/// Jednorazowy kod QR, który klient skanuje w aplikacji, żeby dostać pieczątki.
class _IssueStampCode extends ConsumerStatefulWidget {
  const _IssueStampCode();

  @override
  ConsumerState<_IssueStampCode> createState() => _IssueStampCodeState();
}

class _IssueStampCodeState extends ConsumerState<_IssueStampCode> {
  static const _validFor = Duration(minutes: 2);

  int _count = 1;
  String? _code;
  DateTime? _expiresAt;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _issue() async {
    final code = await ref.read(stampCodeServiceProvider).issue(stamps: _count, validFor: _validFor);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    setState(() {
      _code = code;
      _expiresAt = DateTime.now().add(_validFor);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final secondsLeft = _expiresAt == null ? 0 : _expiresAt!.difference(DateTime.now()).inSeconds.clamp(0, 9999);
    final expired = _code != null && secondsLeft == 0;
    if (expired) _ticker?.cancel();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.stampCodeTitle, style: text.titleLarge),
        const SizedBox(height: 10),
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
              onPressed: _count < StampCode.maxStamps ? () => setState(() => _count++) : null,
              icon: const Icon(Icons.add),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _issue,
                icon: const Icon(Icons.qr_code_2),
                label: Text(_code == null ? l.showStampCode : l.newStampCode),
              ),
            ),
          ],
        ),
        if (_code != null) ...[
          const SizedBox(height: 14),
          Center(
            child: Opacity(
              opacity: expired ? 0.2 : 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: RollColors.lime, width: 3),
                ),
                child: QrImageView(data: _code!, size: 200, backgroundColor: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            expired ? l.stampCodeExpired : l.stampCodeValid(secondsLeft),
            textAlign: TextAlign.center,
            style: text.bodyMedium,
          ),
        ],
      ],
    );
  }
}

/// Kod do wydrukowania i przyklejenia przy ladzie.
class _CounterSticker extends ConsumerWidget {
  const _CounterSticker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final code = ref.watch(counterStickerProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.counterSticker, style: text.titleLarge),
        const SizedBox(height: 4),
        Text(l.counterStickerHint(StampCodeService.dailyScanLimit), style: text.bodyMedium),
        const SizedBox(height: 12),
        if (code != null)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: RollColors.pink, width: 3),
              ),
              child: QrImageView(data: code, size: 200, backgroundColor: Colors.white),
            ),
          ),
      ],
    );
  }
}

/// Dla właściciela: pierwsze wgranie menu z aplikacji do pustej bazy.
class _UploadBundledData extends ConsumerStatefulWidget {
  const _UploadBundledData();

  @override
  ConsumerState<_UploadBundledData> createState() => _UploadBundledDataState();
}

class _UploadBundledDataState extends ConsumerState<_UploadBundledData> {
  var _busy = false;

  Future<void> _upload() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final count = await ref.read(backendProvider).uploadBundledData();
      messenger.showSnackBar(SnackBar(content: Text(l.uploadMenuDone(count))));
    } catch (e) {
      debugPrint('uploadBundledData: $e');
      messenger.showSnackBar(SnackBar(content: Text(l.actionFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.uploadMenuTitle, style: text.titleLarge),
        const SizedBox(height: 4),
        Text(l.uploadMenuHint, style: text.bodyMedium),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _upload,
          icon: const Icon(Icons.cloud_upload_outlined),
          label: Text(l.uploadMenuButton),
        ),
      ],
    );
  }
}
