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

/// Liczy, czy lokal jest teraz otwarty. Zakłada, że lokal zamyka się przed północą.
OpenStatus openStatus(List<DayHours?> hours, DateTime now) {
  final today = now.weekday - 1;
  final nowMin = now.hour * 60 + now.minute;
  final h = hours[today];
  if (h != null) {
    if (nowMin >= _minutes(h.open) && nowMin < _minutes(h.close)) return OpenNow(h.close);
    if (nowMin < _minutes(h.open)) return ClosedNow(opensAt: h.open, daysAhead: 0);
  }
  for (var i = 1; i <= 7; i++) {
    final next = hours[(today + i) % 7];
    if (next != null) return ClosedNow(opensAt: next.open, daysAhead: i);
  }
  return const ClosedNow(opensAt: TimeOfDay(hour: 0, minute: 0), daysAhead: 7);
}

String formatTime(TimeOfDay t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}';
