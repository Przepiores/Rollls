import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../backend/backend.dart';
import '../../l10n/app_localizations.dart';
import '../../loyalty/stamp_claims.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Naklejka z kodem przy kasie: podgląd do wydruku, a dla właściciela wymiana.
///
/// Wymiana tworzy nową naklejkę i od razu unieważnia starą, np. gdy ktoś
/// zrobił zdjęcie kodu i skanuje go spoza lokalu.
class StickerScreen extends ConsumerStatefulWidget {
  const StickerScreen({super.key});

  /// Jak długo ważna jest nowa naklejka. Serwer przyjmuje najwyżej 3 lata.
  static const validFor = Duration(days: 730);

  @override
  ConsumerState<StickerScreen> createState() => _StickerScreenState();
}

class _StickerScreenState extends ConsumerState<StickerScreen> {
  late final Stream<List<StickerInfo>> _stickers = ref.read(backendProvider).stickers();
  final _codes = <String, Future<String>>{};
  bool _busy = false;

  Future<String> _codeFor(StickerInfo s) =>
      _codes[s.id] ??= ref.read(stampCodeServiceProvider).issueSticker(id: s.id, validUntil: s.validUntil);

  Future<void> _replace(StickerInfo? old) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (old != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.stickerReplace),
          content: Text(l.stickerReplaceConfirm),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l.stickerReplace)),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busy = true);
    try {
      final backend = ref.read(backendProvider);
      final id = 'lada-${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
      // Najpierw nowa, potem unieważnienie starej, żeby przy ladzie zawsze był działający kod.
      await backend.createSticker(id, DateTime.now().add(StickerScreen.validFor));
      if (old != null) await backend.revokeSticker(old.id);
      messenger.showSnackBar(SnackBar(content: Text(l.stickerReplaced)));
    } catch (e) {
      debugPrint('replaceSticker: $e');
      messenger.showSnackBar(SnackBar(content: Text(l.actionFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final isOwner = ref.watch(sessionProvider)?.isOwner ?? false;
    final dateFormat = DateFormat('d.MM.yyyy');

    return Scaffold(
      appBar: brandAppBar(context, l.counterSticker, color: RollColors.pink),
      body: StreamBuilder<List<StickerInfo>>(
        stream: _stickers,
        builder: (context, snap) {
          if (!snap.hasData) {
            return snap.hasError
                ? Center(child: Text(l.actionFailed))
                : const Center(child: CircularProgressIndicator());
          }
          final active = snap.data!.where((s) => s.active).firstOrNull;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(l.counterStickerHint(StampCodeService.dailyScanLimit), style: text.bodyMedium),
              const SizedBox(height: 20),
              if (active == null)
                Text(isOwner ? l.stickerNone : l.stickerOwnerOnly, textAlign: TextAlign.center, style: text.titleMedium)
              else ...[
                FutureBuilder<String>(
                  future: _codeFor(active),
                  builder: (context, code) => Center(
                    child: Container(
                      width: 292,
                      height: 292,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: RollColors.pink, width: 3),
                      ),
                      child: code.hasData
                          ? QrImageView(data: code.data!, backgroundColor: Colors.white)
                          : Center(child: code.hasError ? Text(l.actionFailed) : const CircularProgressIndicator()),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l.stickerValidUntil(dateFormat.format(active.validUntil.toLocal())),
                  textAlign: TextAlign.center,
                  style: text.titleMedium,
                ),
              ],
              if (isOwner) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _replace(active),
                  icon: Icon(active == null ? Icons.add : Icons.autorenew),
                  label: Text(active == null ? l.stickerCreate : l.stickerReplace),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
