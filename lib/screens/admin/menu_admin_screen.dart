import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/backend.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/category_note.dart';
import 'category_note_edit_screen.dart';
import 'menu_item_edit_screen.dart';

/// Panel: lista pozycji menu w wybranej kategorii, przełącznik widoczności
/// i osobna lista ukrytych pozycji, bo klienci w ogóle ich nie widzą.
class MenuAdminScreen extends ConsumerStatefulWidget {
  const MenuAdminScreen({super.key});

  @override
  ConsumerState<MenuAdminScreen> createState() => _MenuAdminScreenState();
}

class _MenuAdminScreenState extends ConsumerState<MenuAdminScreen> {
  late final Stream<List<AdminMenuItem>> _items = ref.read(backendProvider).adminMenuItems();
  String? _categoryId;

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _setActive(AdminMenuItem entry, bool active) async {
    try {
      await ref.read(backendProvider).setMenuItemActive(entry.item.id, active);
    } catch (e) {
      debugPrint('setMenuItemActive: $e');
      if (mounted) _toast(AppLocalizations.of(context).actionFailed);
    }
  }

  void _open(List<AdminMenuItem> all, {AdminMenuItem? entry, required String categoryId}) {
    final nextSortOrder = all.isEmpty ? 0 : all.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 10;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MenuItemEditScreen(entry: entry, categoryId: categoryId, newSortOrder: nextSortOrder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final categories = ref.watch(categoriesProvider);
    final remote = ref.watch(backendProvider).isRemote;
    final categoryId = _categoryId ?? categories.firstOrNull?.id ?? '';
    final category = categories.where((c) => c.id == categoryId).firstOrNull;
    final names = {for (final c in categories) c.id: c.name.pl};

    return StreamBuilder<List<AdminMenuItem>>(
      stream: _items,
      builder: (context, snap) {
        final all = snap.data ?? const <AdminMenuItem>[];
        final visible = [
          for (final e in all)
            if (e.active && e.item.categoryId == categoryId) e,
        ];
        final hidden = [
          for (final e in all)
            if (!e.active) e,
        ];
        return Scaffold(
          appBar: brandAppBar(context, l.panelMenu, color: RollColors.yellow),
          floatingActionButton: snap.hasData && categoryId.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () => _open(all, categoryId: categoryId),
                  icon: const Icon(Icons.add),
                  label: Text(l.menuAdminAdd),
                )
              : null,
          body: !snap.hasData
              ? Center(child: snap.hasError ? Text(l.actionFailed) : const CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                  children: [
                    if (remote && all.isEmpty)
                      Text(l.menuAdminEmptyDb, style: text.titleMedium)
                    else ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final c in categories)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(c.name.pl),
                                  selected: c.id == categoryId,
                                  selectedColor: tint(context, c.color, light: 0.6),
                                  onSelected: (_) => setState(() => _categoryId = c.id),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (category != null) ...[
                        Text(category.name.pl, style: text.titleLarge),
                        const SizedBox(height: 8),
                        if (category.note != null) CategoryNote(text: category.note!.pl, color: category.color),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(
                              context,
                            ).push(MaterialPageRoute<void>(builder: (_) => CategoryNoteEditScreen(category: category))),
                            icon: const Icon(Icons.edit_note),
                            label: Text(l.noteEditButton),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      for (final e in visible)
                        _ItemTile(
                          entry: e,
                          onTap: () => _open(all, entry: e, categoryId: e.item.categoryId),
                          onActive: (v) => _setActive(e, v),
                        ),
                      if (hidden.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(l.menuAdminHidden(hidden.length), style: text.titleLarge),
                        const SizedBox(height: 4),
                        Text(l.menuAdminHiddenHint, style: text.bodyMedium),
                        const SizedBox(height: 8),
                        for (final e in hidden)
                          _ItemTile(
                            entry: e,
                            categoryName: names[e.item.categoryId],
                            onTap: () => _open(all, entry: e, categoryId: e.item.categoryId),
                            onActive: (v) => _setActive(e, v),
                          ),
                      ],
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.entry, required this.onTap, required this.onActive, this.categoryName});

  final AdminMenuItem entry;
  final VoidCallback onTap;
  final ValueChanged<bool> onActive;

  /// Przy ukrytych pozycjach: z której kategorii pochodzą.
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final MenuItem item = entry.item;
    final subtitle = [
      ?categoryName,
      if (item.group != null) item.group!.pl,
      if (item.prices.isNotEmpty) item.priceLabel,
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(item.name.pl, style: entry.active ? null : TextStyle(color: Theme.of(context).disabledColor)),
        subtitle: Text(subtitle),
        trailing: Switch(value: entry.active, onChanged: onActive),
      ),
    );
  }
}
