import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/category_note.dart';
import '../../widgets/common.dart';

/// Edycja ramki z cenami nad listą kategorii, z podglądem na żywo.
class CategoryNoteEditScreen extends ConsumerStatefulWidget {
  const CategoryNoteEditScreen({super.key, required this.category});
  final MenuCategory category;

  @override
  ConsumerState<CategoryNoteEditScreen> createState() => _CategoryNoteEditScreenState();
}

class _CategoryNoteEditScreenState extends ConsumerState<CategoryNoteEditScreen> {
  late final LocalizedText? _old = widget.category.note;
  late final _pl = TextEditingController(text: _old?.pl ?? '')..addListener(_refresh);
  late final _en = TextEditingController(text: _old == null || _old.en == _old.pl ? '' : _old.en);
  bool _busy = false;

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _pl.dispose();
    _en.dispose();
    super.dispose();
  }

  Future<void> _save(LocalizedText? note) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(backendProvider).saveCategoryNote(widget.category.id, note);
      messenger.showSnackBar(SnackBar(content: Text(l.menuAdminSaved)));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('saveCategoryNote: $e');
      messenger.showSnackBar(SnackBar(content: Text(l.actionFailed)));
      if (mounted) setState(() => _busy = false);
    }
  }

  LocalizedText? _note() {
    final pl = _pl.text.trim();
    final en = _en.text.trim();
    if (pl.isEmpty && en.isEmpty) return null;
    return LocalizedText(pl.isEmpty ? en : pl, en.isEmpty ? pl : en);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final color = widget.category.color;
    final preview = _pl.text.trim();
    return Scaffold(
      appBar: brandAppBar(context, '${l.noteEditTitle} · ${widget.category.name.pl}', color: RollColors.yellow),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l.notePreview, style: text.titleLarge),
          const SizedBox(height: 8),
          if (preview.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(l.noteEmpty, style: text.bodyMedium),
            )
          else
            CategoryNote(text: preview, color: color),
          const SizedBox(height: 8),
          TextField(
            controller: _pl,
            decoration: InputDecoration(labelText: l.notePl, alignLabelWithHint: true),
            minLines: 4,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tint(context, RollColors.sky, light: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(l.noteHint, style: text.bodySmall),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _en,
            decoration: InputDecoration(labelText: l.noteEn, alignLabelWithHint: true),
            minLines: 3,
            maxLines: null,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : () => _save(_note()),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text(l.menuAdminSave),
          ),
          if (_old != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _save(null),
              style: OutlinedButton.styleFrom(foregroundColor: RollColors.red),
              icon: const Icon(Icons.delete_outline),
              label: Text(l.noteRemove),
            ),
          ],
        ],
      ),
    );
  }
}
