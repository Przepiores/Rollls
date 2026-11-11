import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/backend.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Zamienia „23”, „23,5” albo „23.50 zł” na grosze. Null, gdy to nie jest cena.
int? parsePrice(String raw) {
  final cleaned = raw.trim().toLowerCase().replaceAll('zł', '').replaceAll(' ', '').replaceAll(',', '.');
  if (!RegExp(r'^\d{1,4}(\.\d{1,2})?$').hasMatch(cleaned)) return null;
  final grosze = (double.parse(cleaned) * 100).round();
  return grosze > 0 ? grosze : null;
}

/// Grosze z powrotem na tekst do pola, np. 2350 → „23,50”.
String priceText(int grosze) {
  final zl = grosze ~/ 100;
  final gr = grosze % 100;
  return gr == 0 ? '$zl' : '$zl,${gr.toString().padLeft(2, '0')}';
}

/// Formularz nowej albo istniejącej pozycji menu. Zdjęcie i grupa
/// zostają bez zmian, bo na planie Spark nie wgrywamy plików z panelu.
class MenuItemEditScreen extends ConsumerStatefulWidget {
  const MenuItemEditScreen({super.key, this.entry, required this.categoryId, required this.newSortOrder});

  /// Null dla nowej pozycji.
  final AdminMenuItem? entry;
  final String categoryId;

  /// Miejsce na liście dla nowej pozycji (na końcu).
  final int newSortOrder;

  @override
  ConsumerState<MenuItemEditScreen> createState() => _MenuItemEditScreenState();
}

class _PriceFields {
  _PriceFields([Price? p])
    : labelPl = TextEditingController(text: p?.label?.pl ?? ''),
      labelEn = TextEditingController(text: p?.label == null || p!.label!.en == p.label!.pl ? '' : p.label!.en),
      price = TextEditingController(text: p == null ? '' : priceText(p.grosze));

  final TextEditingController labelPl;
  final TextEditingController labelEn;
  final TextEditingController price;

  void dispose() {
    labelPl.dispose();
    labelEn.dispose();
    price.dispose();
  }
}

class _MenuItemEditScreenState extends ConsumerState<MenuItemEditScreen> {
  final _form = GlobalKey<FormState>();
  late final MenuItem? _old = widget.entry?.item;
  late final _namePl = TextEditingController(text: _old?.name.pl ?? '');
  late final _nameEn = TextEditingController(text: _old == null || _old.name.en == _old.name.pl ? '' : _old.name.en);
  late final _descPl = TextEditingController(text: _old?.description?.pl ?? '');
  late final _descEn = TextEditingController(
    text: _old?.description == null || _old!.description!.en == _old.description!.pl ? '' : _old.description!.en,
  );
  late final List<_PriceFields> _prices = [
    for (final p in _old?.prices ?? const <Price>[]) _PriceFields(p),
    if (_old == null || _old.prices.isEmpty) _PriceFields(),
  ];
  late String _categoryId = widget.categoryId;
  late final Set<MenuBadge> _badges = {...?_old?.badges};
  late bool _active = widget.entry?.active ?? true;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_namePl, _nameEn, _descPl, _descEn]) {
      c.dispose();
    }
    for (final p in _prices) {
      p.dispose();
    }
    super.dispose();
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  /// Tekst PL/EN. Pusty angielski bierze polski, żeby klient po angielsku nie zobaczył pustki.
  static LocalizedText? _text(TextEditingController pl, TextEditingController en) {
    final p = pl.text.trim();
    final e = en.text.trim();
    if (p.isEmpty && e.isEmpty) return null;
    return LocalizedText(p.isEmpty ? e : p, e.isEmpty ? p : e);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    final backend = ref.read(backendProvider);
    final item = MenuItem(
      id: _old?.id ?? backend.newMenuItemId(),
      categoryId: _categoryId,
      name: _text(_namePl, _nameEn)!,
      description: _text(_descPl, _descEn),
      group: _old?.group,
      image: _old?.image,
      badges: {..._badges},
      prices: [for (final p in _prices) Price(parsePrice(p.price.text)!, _text(p.labelPl, p.labelEn))],
    );
    setState(() => _busy = true);
    try {
      await backend.saveMenuItem(item, active: _active, sortOrder: widget.entry?.sortOrder ?? widget.newSortOrder);
      if (!mounted) return;
      _toast(l.menuAdminSaved);
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('saveMenuItem: $e');
      _toast(l.actionFailed);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.menuAdminDelete),
        content: Text(l.menuAdminDeleteConfirm(_old!.name.pl)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: RollColors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.menuAdminDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(backendProvider).deleteMenuItem(_old!.id);
      if (!mounted) return;
      _toast(l.menuAdminDeleted);
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('deleteMenuItem: $e');
      _toast(l.actionFailed);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final categories = ref.watch(categoriesProvider);
    const gap = SizedBox(height: 12);

    return Scaffold(
      appBar: brandAppBar(context, _old == null ? l.menuAdminNew : l.menuAdminEdit, color: RollColors.yellow),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.menuAdminVisible),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            DropdownButtonFormField<String>(
              initialValue: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
              decoration: InputDecoration(labelText: l.menuAdminCategory),
              items: [for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name.pl))],
              onChanged: (v) => setState(() => _categoryId = v ?? _categoryId),
            ),
            gap,
            TextFormField(
              controller: _namePl,
              decoration: InputDecoration(labelText: l.menuAdminNamePl),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v ?? '').trim().isEmpty ? l.menuAdminRequired : null,
            ),
            gap,
            TextFormField(
              controller: _nameEn,
              decoration: InputDecoration(labelText: l.menuAdminNameEn),
            ),
            gap,
            TextFormField(
              controller: _descPl,
              decoration: InputDecoration(labelText: l.menuAdminDescPl),
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
            ),
            gap,
            TextFormField(
              controller: _descEn,
              decoration: InputDecoration(labelText: l.menuAdminDescEn),
              maxLines: null,
            ),
            const SizedBox(height: 24),
            Text(l.menuAdminPrices, style: text.titleLarge),
            const SizedBox(height: 8),
            for (final (i, p) in _prices.indexed)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 6, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('price-$i'),
                              controller: p.price,
                              decoration: InputDecoration(labelText: l.menuAdminPrice, suffixText: 'zł'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) => parsePrice(v ?? '') == null ? l.menuAdminBadPrice : null,
                            ),
                          ),
                          IconButton(
                            tooltip: l.menuAdminRemovePrice,
                            onPressed: _prices.length > 1 ? () => setState(() => _prices.removeAt(i).dispose()) : null,
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: p.labelPl,
                                decoration: InputDecoration(labelText: l.menuAdminVariantPl),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: p.labelEn,
                                decoration: InputDecoration(labelText: l.menuAdminVariantEn),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _prices.add(_PriceFields())),
                icon: const Icon(Icons.add),
                label: Text(l.menuAdminAddPrice),
              ),
            ),
            const SizedBox(height: 16),
            Text(l.menuAdminBadges, style: text.titleLarge),
            Wrap(
              spacing: 8,
              children: [
                for (final (badge, label) in [(MenuBadge.isNew, l.badgeNew), (MenuBadge.bestseller, l.badgeBestseller)])
                  FilterChip(
                    label: Text(label),
                    selected: _badges.contains(badge),
                    onSelected: (v) => setState(() => v ? _badges.add(badge) : _badges.remove(badge)),
                  ),
              ],
            ),
            const SizedBox(height: 28),
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
                label: Text(l.menuAdminDelete),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
