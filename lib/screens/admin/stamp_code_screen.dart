import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../loyalty/stamp_code.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Jednorazowy kod QR, który klient skanuje w aplikacji, żeby dostać pieczątki.
/// Kod podpisuje serwer, ważny jest 2 minuty i działa tylko raz.
class StampCodeScreen extends ConsumerStatefulWidget {
  const StampCodeScreen({super.key});

  @override
  ConsumerState<StampCodeScreen> createState() => _StampCodeScreenState();
}

class _StampCodeScreenState extends ConsumerState<StampCodeScreen> {
  static const _validFor = Duration(minutes: 2);

  int _count = 1;
  String? _code;
  DateTime? _expiresAt;
  Timer? _ticker;
  bool _busy = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _issue() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final code = await ref.read(stampCodeServiceProvider).issue(stamps: _count, validFor: _validFor);
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
      setState(() {
        _code = code;
        _expiresAt = DateTime.now().add(_validFor);
      });
    } catch (e) {
      debugPrint('issueStampCode: $e');
      messenger.showSnackBar(SnackBar(content: Text(l.actionFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final secondsLeft = _expiresAt == null ? 0 : _expiresAt!.difference(DateTime.now()).inSeconds.clamp(0, 9999);
    final expired = _code != null && secondsLeft == 0;
    if (expired) _ticker?.cancel();
    return Scaffold(
      appBar: brandAppBar(context, l.adminIssueStamps, color: RollColors.lime),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l.stampCodeTitle, style: text.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton.outlined(
                onPressed: _count > 1 ? () => setState(() => _count--) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 48,
                child: Text('$_count', textAlign: TextAlign.center, style: text.headlineMedium),
              ),
              IconButton.outlined(
                onPressed: _count < StampCode.maxStamps ? () => setState(() => _count++) : null,
                icon: const Icon(Icons.add),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _issue,
                  icon: const Icon(Icons.qr_code_2),
                  label: Text(_code == null ? l.showStampCode : l.newStampCode),
                ),
              ),
            ],
          ),
          if (_code != null) ...[
            const SizedBox(height: 24),
            Center(
              child: Opacity(
                opacity: expired ? 0.2 : 1,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: RollColors.lime, width: 3),
                  ),
                  child: QrImageView(data: _code!, size: 260, backgroundColor: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              expired ? l.stampCodeExpired : l.stampCodeValid(secondsLeft),
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
          ],
        ],
      ),
    );
  }
}
