import 'package:flutter/material.dart';

import 'models.dart';

sealed class OpenStatus {
  const OpenStatus();
}

class OpenNow extends OpenStatus {
  const OpenNow(this.closesAt);
  final TimeOfDay closesAt;
}

class ClosedNow extends OpenStatus {
  const ClosedNow({required this.opensAt, required this.daysAhead});
  final TimeOfDay opensAt;

  /// 0 = dziś, 1 = jutro, itd.
  final int daysAhead;
}

int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

/// Godziny w danym dniu: dzień specjalny wygrywa ze zwykłym tygodniem. Null = zamknięte.
DayHours? hoursOn(List<DayHours?> hours, DateTime day, {List<SpecialDay> special = const []}) {
  for (final s in special) {
    if (s.isOn(day)) return s.hours;
  }
  return hours[day.weekday - 1];
}

/// Liczy, czy lokal jest teraz otwarty. Zakłada, że lokal zamyka się przed północą.
OpenStatus openStatus(List<DayHours?> hours, DateTime now, {List<SpecialDay> special = const []}) {
  final nowMin = now.hour * 60 + now.minute;
  final h = hoursOn(hours, now, special: special);
  if (h != null) {
    if (nowMin >= _minutes(h.open) && nowMin < _minutes(h.close)) return OpenNow(h.close);
    if (nowMin < _minutes(h.open)) return ClosedNow(opensAt: h.open, daysAhead: 0);
  }
  // Szukamy dalej niż tydzień, bo dni specjalne mogą zamknąć lokal na dłużej.
  for (var i = 1; i <= 31; i++) {
    final next = hoursOn(hours, DateTime(now.year, now.month, now.day + i), special: special);
    if (next != null) return ClosedNow(opensAt: next.open, daysAhead: i);
  }
  return const ClosedNow(opensAt: TimeOfDay(hour: 0, minute: 0), daysAhead: 7);
}

/// Dni specjalne od dziś na [days] dni naprzód.
List<SpecialDay> upcomingSpecialDays(List<SpecialDay> special, DateTime now, {int days = 30}) {
  final today = DateTime(now.year, now.month, now.day);
  final until = today.add(Duration(days: days));
  return [
    for (final s in special)
      if (!s.date.isBefore(today) && s.date.isBefore(until)) s,
  ]..sort((a, b) => a.date.compareTo(b.date));
}

String formatTime(TimeOfDay t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

/// Krótka data, np. „24.12”.
String shortDate(DateTime d) => '${d.day}.${d.month.toString().padLeft(2, '0')}';
