import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../data/menu_data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String _category = categories.first.id;
  String? _expanded;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final cat = categories.firstWhere((c) => c.id == _category);
    final items = menuItems.where((i) => i.categoryId == _category).toList();

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = categories[i];
                final selected = c.id == _category;
                return ChoiceChip(
                  label: Text(c.name.of(locale)),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: c.color,
                  backgroundColor: tint(context, c.color, light: 0.3, dark: 0.3),
                  labelStyle: Theme.of(context).chipTheme.labelStyle
                      ?.copyWith(color: selected ? ink : Theme.of(context).colorScheme.onSurface),
                  side: BorderSide(color: c.color, width: 2),
                  onSelected: (_) => setState(() {
                    _category = c.id;
                    _expanded = null;
                  }),
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (cat.image != null) _CategoryBanner(category: cat, locale: locale),
                if (cat.note != null) _CategoryNote(text: cat.note!.of(locale), color: cat.color),
                for (final entry in _grouped(items))
                  if (entry.$1 == null)
                    for (final item in entry.$2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MenuTile(
                          item: item,
                          color: cat.color,
                          locale: locale,
                          expanded: _expanded == item.id,
                          onTap: () => setState(() => _expanded = _expanded == item.id ? null : item.id),
                        ),
                      )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GroupCard(title: entry.$1!.of(locale), items: entry.$2, color: cat.color, locale: locale),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Splits items into consecutive runs sharing the same group (null = standalone tiles).
List<(LocalizedText?, List<MenuItem>)> _grouped(List<MenuItem> items) {
  final out = <(LocalizedText?, List<MenuItem>)>[];
  for (final item in items) {
    if (out.isNotEmpty && out.last.$1?.pl == item.group?.pl) {
      out.last.$2.add(item);
    } else {
      out.add((item.group, [item]));
    }
  }
  return out;
}

class _CategoryBanner extends StatelessWidget {
  const _CategoryBanner({required this.category, required this.locale});
  final MenuCategory category;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Prawie kwadratowy kadr, żeby zdjęcie było dobrze widać.
      height: (MediaQuery.sizeOf(context).width * 0.8).clamp(200.0, 420.0),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: category.color, width: 3),
        boxShadow: neonGlow(category.color),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(category.image!, fit: BoxFit.cover, alignment: category.imageAlignment),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xB31C1030)],
                stops: [0.45, 1],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Text(
              category.name.of(locale),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryNote extends StatelessWidget {
  const _CategoryNote({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint(context, color, light: 0.35, dark: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.title, required this.items, required this.color, required this.locale});
  final String title;
  final List<MenuItem> items;
  final Color color;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      color: tint(context, color),
      shape: outlinedCard(color),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.titleMedium),
            const SizedBox(height: 4),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name.of(locale), style: text.bodyLarge),
                          if (item.description != null) Text(item.description!.of(locale), style: text.bodySmall),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(item.priceLabel, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.item,
    required this.color,
    required this.locale,
    required this.expanded,
    required this.onTap,
  });
  final MenuItem item;
  final Color color;
  final Locale locale;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      color: tint(context, color),
      shape: outlinedCard(color),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.badges.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Wrap(spacing: 6, children: [for (final b in item.badges) BadgeChip(b)]),
                            ),
                          Text(item.name.of(locale), style: text.titleMedium),
                          Text(item.priceLabel, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(Icons.expand_more),
                    ),
                  ],
                ),
                if (expanded) ...[
                  const SizedBox(height: 8),
                  if (item.description != null) Text(item.description!.of(locale), style: text.bodyMedium),
                  for (final line in item.priceDetails(locale))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(line, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
