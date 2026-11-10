import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../backend/backend.dart';
import '../../l10n/app_localizations.dart';
import '../../loyalty/stamp_code.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/stamp_card.dart';

/// Obsługa skanuje kod z zakładki Pieczątki klienta, widzi jego kartę
/// i może dobić pieczątki albo wydać nagrodę za pełną kartę.
class CustomerScreen extends ConsumerStatefulWidget {
  const CustomerScreen({super.key, this.camera});

  /// Podgląd aparatu. Testy podmieniają go, bo w nich nie ma kamery.
  final Widget Function(void Function(String code) onCode)? camera;

  @override
  ConsumerState<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends ConsumerState<CustomerScreen> {
  MobileScannerController? _controller;
  String? _uid;
  Stream<Customer?>? _customer;
  int _count = 1;
  bool _busy = false;
  String? _lastRejected;

  MobileScannerController get _scanner =>
      _controller ??= MobileScannerController(formats: const [BarcodeFormat.qrCode]);

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  void _onCode(String raw) {
    if (_uid != null) return;
    final uid = ref.read(backendProvider).customerUidFromCode(raw);
    if (uid == null) {
      // Ten sam zły kod przed aparatem nie powinien zasypywać ekranu komunikatami.
      if (raw != _lastRejected) _toast(AppLocalizations.of(context).notCustomerCode);
      _lastRejected = raw;
      return;
    }
    _controller?.stop();
    setState(() {
      _uid = uid;
      _customer = ref.read(backendProvider).customer(uid);
      _count = 1;
    });
  }

  void _next() {
    setState(() {
      _uid = null;
      _customer = null;
      _lastRejected = null;
    });
    _controller?.start();
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await action();
      _toast(done);
    } catch (e) {
      debugPrint('customer action: $e');
      _toast(l.actionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _camera() => MobileScanner(
    controller: _scanner,
    onDetect: (capture) {
      final raw = capture.barcodes.map((b) => b.rawValue).nonNulls.firstOrNull;
      if (raw != null) _onCode(raw);
    },
    errorBuilder: (context, error) => ColoredBox(
      color: night,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppLocalizations.of(context).cameraError,
            textAlign: TextAlign.center,
            style: const TextStyle(color: paper),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final backend = ref.watch(backendProvider);

    return Scaffold(
      appBar: brandAppBar(context, l.adminCustomer, color: RollColors.sky),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_uid == null) ...[
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: night,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: RollColors.sky, width: 3),
                ),
                child: widget.camera?.call(_onCode) ?? _camera(),
              ),
            ),
            const SizedBox(height: 16),
            Text(l.scanCustomerHint, textAlign: TextAlign.center, style: text.titleMedium),
            if (!backend.isRemote) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _onCode(backend.customerCode(LocalBackend.demoUid)),
                icon: const Icon(Icons.science_outlined),
                label: Text(l.scanCustomerDemo),
              ),
            ],
          ] else
            StreamBuilder<Customer?>(
              stream: _customer,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final customer = snap.data;
                if (customer == null) {
                  return Text(
                    snap.hasError ? l.actionFailed : l.customerNotFound,
                    textAlign: TextAlign.center,
                    style: text.titleMedium,
                  );
                }
                return _CustomerCard(
                  customer: customer,
                  count: _count,
                  busy: _busy,
                  onCount: (n) => setState(() => _count = n),
                  onAdd: () => _run(() async {
                    await backend.addStamps(customer.uid, _count);
                    if (mounted) setState(() => _count = 1);
                  }, l.stampsAdded(_count)),
                  onRedeem: () => _run(() => backend.redeemReward(customer.uid), l.rewardRedeemed),
                );
              },
            ),
          if (_uid != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(onPressed: _next, icon: const Icon(Icons.qr_code_scanner), label: Text(l.scanAnother)),
          ],
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.count,
    required this.busy,
    required this.onCount,
    required this.onAdd,
    required this.onRedeem,
  });

  final Customer customer;
  final int count;
  final bool busy;
  final ValueChanged<int> onCount;
  final VoidCallback onAdd;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final card = customer.card;
    // Reguły bazy przyjmują 1–5 pieczątek naraz i najwyżej do pełnej karty.
    final maxCount = card.remaining < StampCode.maxStamps ? card.remaining : StampCode.maxStamps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(customer.name.isEmpty ? '—' : customer.name, style: text.headlineSmall),
        if (customer.email != null) Text(customer.email!, style: text.bodyMedium),
        const SizedBox(height: 14),
        StampCardView(card: card, compact: true),
        const SizedBox(height: 16),
        if (card.rewardReady)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: RollColors.lime,
              foregroundColor: ink,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            onPressed: busy ? null : onRedeem,
            icon: const Icon(Icons.icecream),
            label: Text(l.redeemReward),
          )
        else
          Row(
            children: [
              IconButton.outlined(
                onPressed: count > 1 ? () => onCount(count - 1) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 44,
                child: Text('$count', textAlign: TextAlign.center, style: text.headlineSmall),
              ),
              IconButton.outlined(
                onPressed: count < maxCount ? () => onCount(count + 1) : null,
                icon: const Icon(Icons.add),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(onPressed: busy ? null : onAdd, child: Text(l.addStamps)),
              ),
            ],
          ),
      ],
    );
  }
}
