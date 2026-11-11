import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/backend.dart';
import '../../data/opening_hours.dart';
import '../../l10n/app_localizations.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'promotion_edit_screen.dart';

/// Panel: lista promocji z karuzeli na stronie głównej, z włącznikiem i terminem.
class PromotionsAdminScreen extends ConsumerStatefulWidget {
  const PromotionsAdminScreen({super.key});

  @override
  ConsumerState<PromotionsAdminScreen> createState() => _PromotionsAdminScreenState();
}

class _PromotionsAdminScreenState extends ConsumerState<PromotionsAdminScreen> {
  late final Stream<List<AdminPromotion>> _promos = ref.read(backendProvider).adminPromotions();

  Future<void> _setActive(AdminPromotion p, bool active) async {
    try {
      await ref
          .read(backendProvider)
          .savePromotion(
            AdminPromotion(
              promotion: p.promotion,
              active: active,
              sortOrder: p.sortOrder,
              startsAt: p.startsAt,
              endsAt: p.endsAt,
            ),
          );
    } catch (e) {
      debugPrint('savePromotion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).actionFailed)));
      }
    }
  }

  void _open(List<AdminPromotion> all, [AdminPromotion? entry]) {
    final next = all.isEmpty ? 0 : all.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 10;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PromotionEditScreen(entry: entry, newSortOrder: next),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return StreamBuilder<List<AdminPromotion>>(
      stream: _promos,
      builder: (context, snap) {
        final all = snap.data ?? const <AdminPromotion>[];
        return Scaffold(
          appBar: brandAppBar(context, l.panelPromos, color: RollColors.pink),
          floatingActionButton: snap.hasData
              ? FloatingActionButton.extended(
                  onPressed: () => _open(all),
                  icon: const Icon(Icons.add),
                  label: Text(l.promoAdd),
                )
              : null,
          body: !snap.hasData
              ? Center(child: snap.hasError ? Text(l.actionFailed) : const CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                  children: [
                    if (all.isEmpty) Text(l.promoEmpty, style: text.titleMedium),
                    for (final p in all)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () => _open(all, p),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: p.promotion.image == null
                                  ? ColoredBox(color: p.promotion.color)
                                  : BrandImage(p.promotion.image!, fit: BoxFit.cover),
                            ),
                          ),
                          title: Text(p.promotion.title.pl),
                          subtitle: Text(promoStatus(l, p, DateTime.now())),
                          trailing: Switch(value: p.active, onChanged: (v) => _setActive(p, v)),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

/// Krótki stan promocji dla listy w panelu.
String promoStatus(AppLocalizations l, AdminPromotion p, DateTime now) {
  if (!p.active) return l.promoHiddenStatus;
  if (p.endsAt != null && !now.isBefore(p.endsAt!)) return l.promoEnded;
  if (p.startsAt != null && now.isBefore(p.startsAt!)) return l.promoScheduled(shortDate(p.startsAt!));
  // Koniec jest zapisany jako początek następnego dnia, a klientowi pokazujemy ostatni dzień.
  if (p.endsAt != null) return l.promoUntilStatus(shortDate(p.endsAt!.subtract(const Duration(days: 1))));
  return l.promoShown;
}
