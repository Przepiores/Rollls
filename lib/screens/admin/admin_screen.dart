import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Panel sklepu: start z akcjami przy ladzie i lista następnych działów.
///
/// Widzi go tylko konto z rolą `owner` albo `staff`. Zapisy i tak sprawdzają
/// reguły Firestore i Cloud Functions, ten ekran tylko nie pokazuje narzędzi klientom.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    final backend = ref.watch(backendProvider);
    final text = Theme.of(context).textTheme;
    final isOwner = session?.isOwner ?? false;

    final later = [(Icons.bar_chart, l.panelStats)];

    return StaffOnly(
      child: Scaffold(
        appBar: brandAppBar(context, l.shopPanel, color: RollColors.lime),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AdminActionTile(
              icon: Icons.qr_code_scanner,
              color: RollColors.sky,
              title: l.adminCustomer,
              subtitle: l.adminCustomerHint,
              onTap: () => context.push('/admin/customer'),
            ),
            if (isOwner)
              AdminActionTile(
                icon: Icons.restaurant_menu,
                color: RollColors.yellow,
                title: l.panelMenu,
                subtitle: l.adminMenuHint,
                onTap: () => context.push('/admin/menu'),
              ),
            if (isOwner)
              AdminActionTile(
                icon: Icons.local_offer_outlined,
                color: RollColors.pink,
                title: l.panelPromos,
                subtitle: l.adminPromosHint,
                onTap: () => context.push('/admin/promotions'),
              ),
            if (isOwner)
              AdminActionTile(
                icon: Icons.schedule,
                color: RollColors.purple,
                title: l.panelHours,
                subtitle: l.adminHoursHint,
                onTap: () => context.push('/admin/hours'),
              ),
            if (backend.isRemote && isOwner) ...[const SizedBox(height: 20), const _UploadBundledData()],
            const SizedBox(height: 28),
            Text(l.adminLater, style: text.titleLarge),
            const SizedBox(height: 10),
            for (final (i, (icon, label)) in later.indexed)
              Card(
                color: tint(context, RollColors.all[(i + 3) % RollColors.all.length], light: 0.3),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(icon),
                  title: Text(label, style: text.titleMedium),
                  subtitle: Text(l.adminComingSoon),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Duży kafelek akcji na starcie panelu, wygodny do kliknięcia kciukiem przy ladzie.
class AdminActionTile extends StatelessWidget {
  const AdminActionTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      color: tint(context, color, light: 0.35),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Row(
            children: [
              CircleAvatar(radius: 28, backgroundColor: color, foregroundColor: ink, child: Icon(icon, size: 30)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleLarge),
                    const SizedBox(height: 2),
                    Text(subtitle, style: text.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pokazuje [child] tylko obsłudze sklepu. Pozostałym mówi, że to nie dla nich.
class StaffOnly extends ConsumerWidget {
  const StaffOnly({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session?.isStaff ?? false) return child;
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: brandAppBar(context, l.shopPanel, color: RollColors.lime),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 16),
              Text(l.adminNoAccess, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
              if (session == null) ...[
                const SizedBox(height: 20),
                FilledButton(onPressed: () => context.push('/login'), child: Text(l.loginEmail)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dla właściciela: pierwsze wgranie menu z aplikacji do pustej bazy.
class _UploadBundledData extends ConsumerStatefulWidget {
  const _UploadBundledData();

  @override
  ConsumerState<_UploadBundledData> createState() => _UploadBundledDataState();
}

class _UploadBundledDataState extends ConsumerState<_UploadBundledData> {
  var _busy = false;

  Future<void> _upload() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final count = await ref.read(backendProvider).uploadBundledData();
      messenger.showSnackBar(SnackBar(content: Text(l.uploadMenuDone(count))));
    } catch (e) {
      debugPrint('uploadBundledData: $e');
      messenger.showSnackBar(SnackBar(content: Text(l.actionFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.uploadMenuTitle, style: text.titleLarge),
        const SizedBox(height: 4),
        Text(l.uploadMenuHint, style: text.bodyMedium),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _upload,
          icon: const Icon(Icons.cloud_upload_outlined),
          label: Text(l.uploadMenuButton),
        ),
      ],
    );
  }
}
