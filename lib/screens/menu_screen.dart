import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../data/sample_data.dart';
import '../l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final cat = categories.firstWhere((c) => c.id == _category);
    final items = menuItems.where((i) => i.categoryId == _category).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l.tabMenu)),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? ink : Theme.of(context).colorScheme.onSurface,
                  ),
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
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MenuTile(
                      item: item,
                      color: cat.color,
                      locale: locale,
                      expanded: _expanded == item.id,
                      onTap: () => setState(() => _expanded = _expanded == item.id ? null : item.id),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l.sampleData, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
          ),
        ],
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
                    SizedBox.square(
                      dimension: 76,
                      child: ProductImage(item: item, color: color, radius: 14),
                    ),
                    const SizedBox(width: 14),
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
                  const SizedBox(height: 12),
                  if (item.image != null)
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: ProductImage(item: item, color: color),
                    ),
                  const SizedBox(height: 10),
                  Text(item.description.of(locale), style: text.bodyMedium),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
