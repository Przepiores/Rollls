import 'package:flutter/material.dart';

import '../theme.dart';

/// Jedna część notatki kategorii po rozbiciu zwykłego tekstu.
sealed class NoteBlock {
  const NoteBlock();
}

/// Ceny w kafelkach, np. „1 składnik · 20 zł”. [label] to np. „Studenci”.
class PriceBlock extends NoteBlock {
  const PriceBlock(this.prices, {this.label});
  final String? label;
  final List<(String name, String price)> prices;
}

/// Lista dodatków pod nagłówkiem z ceną, np. „Dodatki po 4 zł”.
class TagBlock extends NoteBlock {
  const TagBlock(this.heading, this.tags);
  final String heading;
  final List<String> tags;
}

/// Zwykły opis.
class TextBlock extends NoteBlock {
  const TextBlock(this.text);
  final String text;
}

final _sentenceBreak = RegExp(r'(?<=\.)\s+(?=[A-ZĄĆĘŁŃÓŚŹŻ0-9])');
final _label = RegExp(r'^([^:]{1,30}):\s*(.+)$');
final _itemBreak = RegExp(r',\s+|\s+·\s+');
const _amount = r'\+?\d+(?:[,.]\d{1,2})?\s*zł';
final _nameThenPrice = RegExp('^(.*?)\\s*($_amount)\$');
final _priceThenName = RegExp('^($_amount)\\s+(.+)\$');
final _hasPrice = RegExp(_amount);

String _clean(String s) => s.trim().replaceAll(RegExp(r'\.$'), '').trim();

(String, String)? _price(String item) {
  final a = _nameThenPrice.firstMatch(item);
  if (a != null) return (a.group(1)!.trim(), a.group(2)!);
  final b = _priceThenName.firstMatch(item);
  if (b != null) return (b.group(2)!.trim(), b.group(1)!);
  return null;
}

/// Rozbija notatkę na ceny, listy dodatków i opis.
///
/// Notatki to zwykły tekst (także te z bazy), więc formatowanie wynika
/// z samej treści: linie, zdania, „Etykieta: a, b, c” i kwoty w zł.
List<NoteBlock> parseNote(String note) {
  final blocks = <NoteBlock>[];
  void add(NoteBlock b) {
    final last = blocks.lastOrNull;
    // Sąsiednie ceny bez etykiety i sąsiednie zdania łączymy w jeden blok.
    if (b is PriceBlock && b.label == null && last is PriceBlock && last.label == null) {
      blocks[blocks.length - 1] = PriceBlock([...last.prices, ...b.prices]);
    } else if (b is TextBlock && last is TextBlock) {
      blocks[blocks.length - 1] = TextBlock('${last.text} ${b.text}');
    } else {
      blocks.add(b);
    }
  }

  for (final line in note.split('\n')) {
    for (final raw in line.trim().split(_sentenceBreak)) {
      final sentence = raw.trim();
      if (sentence.isEmpty) continue;
      final m = _label.firstMatch(_clean(sentence));
      final label = m?.group(1)?.trim();
      final items = _clean(m?.group(2) ?? sentence).split(_itemBreak).map(_clean).where((s) => s.isNotEmpty).toList();
      final prices = items.map(_price).toList();
      if (prices.isNotEmpty && prices.every((p) => p != null)) {
        add(PriceBlock([for (final p in prices) p!], label: label));
      } else if (label != null && _hasPrice.hasMatch(label) && items.length > 1) {
        add(TagBlock(label, items));
      } else {
        add(TextBlock(sentence));
      }
    }
  }
  return blocks;
}

/// Ramka z informacją nad listą pozycji kategorii.
class CategoryNote extends StatelessWidget {
  const CategoryNote({super.key, required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final blocks = parseNote(text);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint(context, color, light: 0.35, dark: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, b) in blocks.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            switch (b) {
              PriceBlock() => _Prices(block: b, color: color),
              TagBlock() => _Tags(block: b, color: color),
              TextBlock() => _Text(text: b.text),
            },
          ],
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
  );
}

class _Prices extends StatelessWidget {
  const _Prices({required this.block, required this.color});
  final PriceBlock block;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final surface = Theme.of(context).colorScheme.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.label != null) _Heading(block.label!),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (name, price) in block.prices)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (name.isNotEmpty) Text(name, style: text.bodySmall),
                    Text(price, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Tags extends StatelessWidget {
  const _Tags({required this.block, required this.color});
  final TagBlock block;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(block.heading),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final tag in block.tags)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.6)),
                ),
                child: Text(tag, style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      ],
    );
  }
}

class _Text extends StatelessWidget {
  const _Text({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(padding: EdgeInsets.only(top: 1), child: Icon(Icons.info_outline_rounded, size: 18)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
    ],
  );
}
