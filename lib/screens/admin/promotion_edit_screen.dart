import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/backend.dart';
import '../../data/models.dart';
import '../../data/opening_hours.dart';
import '../../l10n/app_localizations.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../home_screen.dart';

/// Zdjęcia z aplikacji do wyboru. Na planie Spark nie wgrywamy nowych plików.
const promoPhotos = [
  'assets/images/lody_tajskie.jpg',
  'assets/images/freak_shake.jpg',
  'assets/images/classic_shake.jpg',
  'assets/images/gofry_babelkowe.jpg',
  'assets/images/gofr_babelkowy.jpg',
  'assets/images/gofry_belgijskie_kawa.jpg',
  'assets/images/gofr_wisniowy.jpg',
  'assets/images/herbata.jpg',
];

/// Formularz nowej albo istniejącej promocji, z podglądem karty.
class PromotionEditScreen extends ConsumerStatefulWidget {
  const PromotionEditScreen({super.key, this.entry, required this.newSortOrder});

  /// Null dla nowej promocji.
  final AdminPromotion? entry;
  final int newSortOrder;

  @override
  ConsumerState<PromotionEditScreen> createState() => _PromotionEditScreenState();
}

class _PromotionEditScreenState extends ConsumerState<PromotionEditScreen> {
  final _form = GlobalKey<FormState>();
  late final Promotion? _old = widget.entry?.promotion;
  late final _titlePl = _controller(_old?.title.pl);
  late final _titleEn = _controller(_old == null || _old.title.en == _old.title.pl ? null : _old.title.en);
  late final _bodyPl = _controller(_old?.body.pl);
  late final _bodyEn = _controller(_old == null || _old.body.en == _old.body.pl ? null : _old.body.en);
  late Color _color = _old?.color ?? RollColors.pink;
  late String? _image = _old?.image;
  late bool _active = widget.entry?.active ?? true;
  late DateTime? _from = widget.entry?.startsAt;

  /// Ostatni dzień, w którym promocja jest widoczna. W bazie zapisujemy początek dnia następnego.
  late DateTime? _until = widget.entry?.endsAt?.subtract(const Duration(days: 1));
  bool _busy = false;

  TextEditingController _controller(String? text) => TextEditingController(text: text ?? '')..addListener(_refresh);
  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in [_titlePl, _titleEn, _bodyPl, _bodyEn]) {
      c.dispose();
    }
    super.dispose();
  }

  static LocalizedText _text(TextEditingController pl, TextEditingController en) {
    final p = pl.text.trim();
    final e = en.text.trim();
    return LocalizedText(p, e.isEmpty ? p : e);
  }

  Promotion _promotion(String id) =>
      Promotion(id: id, title: _text(_titlePl, _titleEn), body: _text(_bodyPl, _bodyEn), color: _color, image: _image);

  bool get _datesOk => _from == null || _until == null || !_until!.isBefore(_from!);

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<DateTime?> _pickDate(DateTime? initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return;
    if (!_datesOk) return _toast(l.promoBadDates);
    final backend = ref.read(backendProvider);
    final until = _until;
    final entry = AdminPromotion(
      promotion: _promotion(_old?.id ?? backend.newPromotionId()),
      active: _active,
      sortOrder: widget.entry?.sortOrder ?? widget.newSortOrder,
      startsAt: _from,
      endsAt: until == null ? null : DateTime(until.year, until.month, until.day + 1),
    );
    setState(() => _busy = true);
    try {
      await backend.savePromotion(entry);
      if (!mounted) return;
      _toast(l.menuAdminSaved);
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('savePromotion: $e');
      _toast(l.actionFailed);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.promoDelete),
        content: Text(l.promoDeleteConfirm(_old!.title.pl)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: RollColors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.promoDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(backendProvider).deletePromotion(_old!.id);
      if (!mounted) return;
      _toast(l.promoDeleted);
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('deletePromotion: $e');
      _toast(l.actionFailed);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = ref.watch(localeProvider);
    const gap = SizedBox(height: 12);
    String? required(String? v) => (v ?? '').trim().isEmpty ? l.promoRequired : null;

    return Scaffold(
      appBar: brandAppBar(context, _old == null ? l.promoNew : l.promoEdit, color: RollColors.pink),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: SizedBox(
                height: 280,
                child: PromoCard(promo: _promotion('preview'), locale: locale),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.promoVisible),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            TextFormField(
              controller: _titlePl,
              decoration: InputDecoration(labelText: l.promoTitlePl),
              textCapitalization: TextCapitalization.sentences,
              validator: required,
            ),
            gap,
            TextFormField(
              controller: _bodyPl,
              decoration: InputDecoration(labelText: l.promoBodyPl),
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              validator: required,
            ),
            gap,
            TextFormField(
              controller: _titleEn,
              decoration: InputDecoration(labelText: l.promoTitleEn),
            ),
            gap,
            TextFormField(
              controller: _bodyEn,
              decoration: InputDecoration(labelText: l.promoBodyEn),
              maxLines: null,
            ),
            const SizedBox(height: 20),
            Text(l.promoColor, style: text.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                for (final c in RollColors.all)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: c == _color ? ink : Colors.transparent,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: c,
                        child: c == _color ? const Icon(Icons.check, color: ink, size: 18) : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(l.promoPhoto, style: text.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 76,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final img in [null, ...promoPhotos])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _image = img),
                        child: Container(
                          width: 76,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: img == _image ? ink : Colors.transparent, width: 3),
                            color: tint(context, _color, light: 0.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: img == null
                              ? Center(
                                  child: Text(l.promoNoPhoto, textAlign: TextAlign.center, style: text.bodySmall),
                                )
                              : BrandImage(img, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DateTile(
              label: l.promoFrom,
              value: _from,
              empty: l.promoNoDate,
              onPick: () async {
                final d = await _pickDate(_from);
                if (d != null) setState(() => _from = d);
              },
              onClear: () => setState(() => _from = null),
            ),
            _DateTile(
              label: l.promoUntil,
              value: _until,
              empty: l.promoNoDate,
              onPick: () async {
                final d = await _pickDate(_until ?? _from);
                if (d != null) setState(() => _until = d);
              },
              onClear: () => setState(() => _until = null),
            ),
            if (!_datesOk) Text(l.promoBadDates, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(l.menuAdminSave),
            ),
            if (_old != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _delete,
                style: OutlinedButton.styleFrom(foregroundColor: RollColors.red),
                icon: const Icon(Icons.delete_forever_outlined),
                label: Text(l.promoDelete),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.empty,
    required this.onPick,
    required this.onClear,
  });
  final String label;
  final DateTime? value;
  final String empty;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.event),
    title: Text(label),
    subtitle: Text(value == null ? empty : '${shortDate(value!)}.${value!.year}'),
    onTap: onPick,
    trailing: value == null ? null : IconButton(icon: const Icon(Icons.close), onPressed: onClear),
  );
}
