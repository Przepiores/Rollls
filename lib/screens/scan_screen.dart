import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/app_localizations.dart';
import '../loyalty/stamp_claims.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Skaner kodu QR z paragonu albo z lady. Za poprawny kod dodaje pieczątki.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, this.camera});

  /// Podgląd aparatu. Testy podmieniają go, bo w nich nie ma kamery.
  final Widget Function(void Function(String code) onCode)? camera;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);

  /// Blokuje kolejne skany, dopóki klient nie zamknie wyniku poprzedniego.
  bool _busy = false;
  bool _checking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _claim(String raw) async {
    final session = ref.read(sessionProvider);
    if (_busy || session == null) return;
    setState(() => _busy = _checking = true);
    final card = ref.read(stampCardProvider);
    final result = await ref
        .read(stampCodeServiceProvider)
        .claim(raw, userId: session.name, stampsMissing: card.remaining);
    if (result.status == ClaimStatus.added) {
      ref.read(stampCardProvider.notifier).add(result.stamps);
    }
    ref.invalidate(scansLeftTodayProvider);
    if (!mounted) return;
    setState(() => _checking = false);
    await _showResult(result);
    if (!mounted) return;
    if (result.status == ClaimStatus.added) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
    }
  }

  /// Prototyp: skanuje kod z naklejki przy ladzie bez użycia aparatu.
  Future<void> _demoScan() async => _claim(await ref.read(counterStickerProvider.future));

  Future<void> _showResult(ClaimResult result) {
    final l = AppLocalizations.of(context);
    final ok = result.status == ClaimStatus.added;
    final message = switch (result.status) {
      ClaimStatus.added => l.stampsAdded(result.stamps),
      ClaimStatus.invalid => l.claimInvalid,
      ClaimStatus.expired => l.claimExpired,
      ClaimStatus.alreadyUsed => l.claimUsed,
      ClaimStatus.dailyLimit => l.claimDailyLimit(StampCodeService.dailyScanLimit),
      ClaimStatus.cardFull => l.claimCardFull,
    };
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          ok ? Icons.check_circle : Icons.error_outline,
          size: 48,
          color: ok ? RollColors.lime : RollColors.red,
        ),
        title: Text(message, textAlign: TextAlign.center),
        content: ok ? Text(l.scansLeftToday(result.scansLeftToday), textAlign: TextAlign.center) : null,
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.ok))],
      ),
    );
  }

  Widget _camera() => MobileScanner(
    controller: _controller,
    onDetect: (capture) {
      final raw = capture.barcodes.map((b) => b.rawValue).nonNulls.firstOrNull;
      if (raw != null) _claim(raw);
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
    final scansLeft = ref.watch(scansLeftTodayProvider).value;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: brandAppBar(context, l.scanStampCode, color: RollColors.sky),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: night,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: RollColors.purple, width: 3),
                boxShadow: neonGlow(neonPink),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.camera?.call(_claim) ?? _camera(),
                  const Padding(padding: EdgeInsets.all(40), child: _Frame()),
                  if (_checking) const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l.scanHint, textAlign: TextAlign.center, style: text.titleMedium),
          const SizedBox(height: 6),
          if (scansLeft != null) Text(l.scansLeftToday(scansLeft), textAlign: TextAlign.center, style: text.bodyMedium),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _busy ? null : _demoScan,
            icon: const Icon(Icons.science_outlined),
            label: Text(l.scanDemo),
          ),
        ],
      ),
    );
  }
}

/// Ramka celownika w rogach podglądu.
class _Frame extends StatelessWidget {
  const _Frame();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: paper.withValues(alpha: 0.85), width: 3),
    ),
  );
}
