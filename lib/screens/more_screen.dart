import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/opening_hours.dart';
import '../data/shop_data.dart';
import '../l10n/app_localizations.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  Future<void> _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final text = Theme.of(context).textTheme;
    final days = l.days.split(',');
    final today = DateTime.now().weekday - 1;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SectionTitle(l.aboutShop, color: RollColors.sky),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              color: tint(context, RollColors.sky, light: 0.3),
              shape: outlinedCard(RollColors.sky),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shop.name, style: text.titleLarge),
                    Text('${shop.street}, ${shop.city}', style: text.bodyLarge),
                    const SizedBox(height: 10),
                    const OpenStatusPill(),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => _open(
                        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(shop.mapsQuery)}',
                      ),
                      icon: const Icon(Icons.directions),
                      label: Text(l.navigate),
                    ),
                    const SizedBox(height: 18),
                    Text(l.openingHours, style: text.titleMedium),
                    const SizedBox(height: 6),
                    for (var i = 0; i < 7; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                        decoration: i == today
                            ? BoxDecoration(color: RollColors.yellow, borderRadius: BorderRadius.circular(10))
                            : null,
                        child: DefaultTextStyle.merge(
                          style: TextStyle(
                            fontWeight: i == today ? FontWeight.w800 : FontWeight.w500,
                            color: i == today ? ink : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(days[i])),
                              Text(
                                shop.hours[i] == null
                                    ? '–'
                                    : '${formatTime(shop.hours[i]!.open)} – ${formatTime(shop.hours[i]!.close)}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    Text(l.followUs, style: text.titleMedium),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          backgroundColor: tint(context, RollColors.pink, light: 0.35),
                          avatar: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Instagram'),
                          onPressed: () => _open(shop.instagram),
                        ),
                        ActionChip(
                          backgroundColor: tint(context, RollColors.pink, light: 0.35),
                          avatar: const Icon(Icons.facebook, size: 18),
                          label: const Text('Facebook'),
                          onPressed: () => _open(shop.facebook),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SectionTitle(l.settings, color: RollColors.purple),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l.language),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pl', label: Text('PL')),
                ButtonSegment(value: 'en', label: Text('EN')),
              ],
              selected: {locale.languageCode},
              showSelectedIcon: false,
              onSelectionChanged: (s) => ref.read(localeProvider.notifier).set(Locale(s.first)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: Text(l.theme),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              underline: const SizedBox(),
              onChanged: (m) => ref.read(themeModeProvider.notifier).set(m!),
              items: [
                DropdownMenuItem(value: ThemeMode.system, child: Text(l.themeSystem)),
                DropdownMenuItem(value: ThemeMode.light, child: Text(l.themeLight)),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(l.themeDark)),
              ],
            ),
          ),
          if (session != null) ...[
            SectionTitle(l.account, color: RollColors.lime),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: Text(l.marketingConsent),
              value: session.marketingConsent,
              onChanged: ref.read(sessionProvider.notifier).setMarketingConsent,
            ),
            if (session.isStaff)
              ListTile(
                leading: const Icon(Icons.storefront),
                title: Text(l.shopPanel),
                subtitle: Text(l.shopPanelHint),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/admin'),
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l.logout),
              onTap: ref.read(sessionProvider.notifier).signOut,
            ),
          ],
        ],
      ),
    );
  }
}
