import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/opening_hours.dart';
import '../../l10n/app_localizations.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

const _defaultHours = DayHours(TimeOfDay(hour: 11, minute: 0), TimeOfDay(hour: 21, minute: 30));

int _min(TimeOfDay t) => t.hour * 60 + t.minute;
bool _valid(DayHours? h) => h == null || _min(h.close) > _min(h.open);

/// Panel: godziny otwarcia w zwykłym tygodniu i dni specjalne (święta, krótsze dni).
class HoursAdminScreen extends ConsumerStatefulWidget {
  const HoursAdminScreen({super.key});

  @override
  ConsumerState<HoursAdminScreen> createState() => _HoursAdminScreenState();
}

class _HoursAdminScreenState extends ConsumerState<HoursAdminScreen> {
  // Godziny bierzemy prosto z bazy, a nie z danych wbudowanych: po wejściu
  // prosto w ten adres zapis domyślnych godzin nadpisałby prawdziwe.
  List<DayHours?>? _week;

  /// Minione dni specjalne nie są już potrzebne, więc ich nie pokazujemy i nie zapisujemy.
  List<SpecialDay> _special = [];
  bool _busy = false;
  Object? _loadError;

  StreamSubscription<Shop>? _sub;

  @override
  void initState() {
    super.initState();
    // Pierwsza wartość wypełnia formularz, kolejne już go nie ruszają.
    _sub = ref
        .read(backendProvider)
        .shop()
        .listen(
          (shop) {
            _sub?.cancel();
            if (!mounted || _week != null) return;
            setState(() {
              _week = [...shop.hours];
              _special = upcomingSpecialDays(shop.specialDays, DateTime.now(), days: 3650);
            });
          },
          onError: (Object e) {
            debugPrint('shop: $e');
            if (mounted) setState(() => _loadError = e);
          },
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  bool get _allValid => _week!.every(_valid) && _special.every((s) => _valid(s.hours));

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _addSpecial() async {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;
    if (_special.any((s) => s.isOn(date))) return _toast(l.hoursDuplicate);
    setState(() {
      _special
        ..add(SpecialDay(date))
        ..sort((a, b) => a.date.compareTo(b.date));
    });
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!_allValid) return _toast(l.hoursBadRange);
    setState(() => _busy = true);
    try {
      await ref.read(backendProvider).saveHours(_week!, _special);
      if (!mounted) return;
      _toast(l.menuAdminSaved);
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('saveHours: $e');
      _toast(l.actionFailed);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final days = l.days.split(',');
    final week = _week;

    return Scaffold(
      appBar: brandAppBar(context, l.panelHours, color: RollColors.sky),
      body: week == null
          ? Center(child: _loadError != null ? Text(l.actionFailed) : const CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(l.hoursWeek, style: text.titleLarge),
                const SizedBox(height: 8),
                for (var i = 0; i < 7; i++)
                  HoursRow(
                    key: ValueKey('week-$i'),
                    label: days[i],
                    hours: week[i],
                    onChanged: (h) => setState(() => week[i] = h),
                  ),
                const SizedBox(height: 24),
                Text(l.hoursSpecial, style: text.titleLarge),
                const SizedBox(height: 4),
                Text(l.hoursSpecialHint, style: text.bodyMedium),
                const SizedBox(height: 8),
                for (final (i, s) in _special.indexed)
                  HoursRow(
                    key: ValueKey('special-${s.key}'),
                    label: '${shortDate(s.date)} · ${days[s.date.weekday - 1]}',
                    hours: s.hours,
                    onChanged: (h) => setState(() => _special[i] = SpecialDay(s.date, h)),
                    onRemove: () => setState(() => _special.removeAt(i)),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addSpecial,
                    icon: const Icon(Icons.add),
                    label: Text(l.hoursAddSpecial),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(l.menuAdminSave),
                ),
              ],
            ),
    );
  }
}

/// Jeden dzień: przełącznik otwarte/zamknięte i godziny od–do.
class HoursRow extends StatelessWidget {
  const HoursRow({super.key, required this.label, required this.hours, required this.onChanged, this.onRemove});
  final String label;
  final DayHours? hours;
  final ValueChanged<DayHours?> onChanged;
  final VoidCallback? onRemove;

  Future<TimeOfDay?> _pick(BuildContext context, TimeOfDay initial) => showTimePicker(
    context: context,
    initialTime: initial,
    builder: (context, child) =>
        MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final h = hours;
    final bad = !_valid(h);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
                if (h == null) Text(l.hoursClosed, style: Theme.of(context).textTheme.bodyMedium),
                Switch(value: h != null, onChanged: (open) => onChanged(open ? _defaultHours : null)),
                if (onRemove != null) IconButton(icon: const Icon(Icons.delete_outline), onPressed: onRemove),
              ],
            ),
            if (h != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, right: 8),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        final t = await _pick(context, h.open);
                        if (t != null) onChanged(DayHours(t, h.close));
                      },
                      child: Text(formatTime(h.open)),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('–')),
                    OutlinedButton(
                      onPressed: () async {
                        final t = await _pick(context, h.close);
                        if (t != null) onChanged(DayHours(h.open, t));
                      },
                      child: Text(formatTime(h.close)),
                    ),
                    if (bad) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(l.hoursBadRange, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
