import 'package:flutter/material.dart';

import '../data/models.dart';

/// Zamiana modeli na mapy Firestore i z powrotem.
///
/// Model danych w bazie (te same nazwy pól w regułach
/// i w panelu sklepu):
///
/// * `categories/{id}`: name{pl,en}, note{pl,en}?, color (ARGB int), image?,
///   imageAlignX, imageAlignY (-1..1, kadrowanie banera), sortOrder, active
/// * `menuItems/{id}`: categoryId, name, description?, group?,
///   prices [{grosze, label?}], badges ["isNew", "bestseller"], image?,
///   sortOrder, active
/// * `promotions/{id}`: title, body, color, image?, sortOrder, active,
///   startsAt?, endsAt?
/// * `shop/settings`: name, street, city, mapsQuery, instagram, facebook,
///   hours [7 x {open: "11:00", close: "21:30"} albo null],
///   specialHours {"2026-12-24": {open, close} albo null = zamknięte}
/// * `users/{uid}`: displayName, email, marketingConsent, createdAt,
///   stamps, rewardsRedeemed (pieczątki zmienia tylko admin, patrz firestore.rules)
///
/// Obrazy to ścieżka do zasobu w aplikacji (`assets/images/...`) albo adres
/// https, gdy właściciel wgra zdjęcie przez panel.
abstract final class Codec {
  static Map<String, String> text(LocalizedText t) => {'pl': t.pl, 'en': t.en};

  static LocalizedText? textOrNull(Object? raw) {
    if (raw is! Map) return null;
    final pl = raw['pl'];
    if (pl is! String) return null;
    final en = raw['en'];
    return LocalizedText(pl, en is String && en.isNotEmpty ? en : pl);
  }

  static LocalizedText textOf(Object? raw) => textOrNull(raw) ?? const LocalizedText('', '');

  static int _int(Object? raw, [int fallback = 0]) => raw is num ? raw.toInt() : fallback;
  static String? _str(Object? raw) => raw is String && raw.isNotEmpty ? raw : null;
  static bool _active(Map<String, dynamic> d) => d['active'] != false;

  // Kategorie

  static Map<String, dynamic> category(MenuCategory c, int sortOrder) => {
    'name': text(c.name),
    'note': c.note == null ? null : text(c.note!),
    'color': c.color.toARGB32(),
    'image': c.image,
    'imageAlignX': c.imageAlignment.x,
    'imageAlignY': c.imageAlignment.y,
    'sortOrder': sortOrder,
    'active': true,
  };

  static MenuCategory? categoryFrom(String id, Map<String, dynamic> d) {
    if (!_active(d)) return null;
    return MenuCategory(
      id: id,
      name: textOf(d['name']),
      note: textOrNull(d['note']),
      color: Color(_int(d['color'], 0xFFFF8FC7)),
      image: _str(d['image']),
      imageAlignment: Alignment(
        (d['imageAlignX'] as num?)?.toDouble() ?? 0,
        (d['imageAlignY'] as num?)?.toDouble() ?? 0,
      ),
    );
  }

  // Pozycje menu

  static Map<String, dynamic> menuItem(MenuItem i, int sortOrder, {bool active = true}) => {
    'categoryId': i.categoryId,
    'name': text(i.name),
    'description': i.description == null ? null : text(i.description!),
    'group': i.group == null ? null : text(i.group!),
    'prices': [
      for (final p in i.prices) {'grosze': p.grosze, 'label': p.label == null ? null : text(p.label!)},
    ],
    'badges': [for (final b in i.badges) b.name],
    'image': i.image,
    'sortOrder': sortOrder,
    'active': active,
  };

  /// Pozycja dla klienta: null, gdy jest wyłączona.
  static MenuItem? menuItemFrom(String id, Map<String, dynamic> d) => _active(d) ? anyMenuItemFrom(id, d) : null;

  /// Pozycja bez względu na to, czy jest włączona (dla panelu).
  static bool isActive(Map<String, dynamic> d) => _active(d);
  static int sortOrderOf(Map<String, dynamic> d) => _int(d['sortOrder'], 1 << 30);

  static MenuItem anyMenuItemFrom(String id, Map<String, dynamic> d) {
    final prices = [
      for (final p in (d['prices'] as List? ?? const []))
        if (p is Map) Price(_int(p['grosze']), textOrNull(p['label'])),
    ];
    final badgeNames = {for (final b in (d['badges'] as List? ?? const [])) b};
    return MenuItem(
      id: id,
      categoryId: _str(d['categoryId']) ?? '',
      name: textOf(d['name']),
      description: textOrNull(d['description']),
      group: textOrNull(d['group']),
      prices: prices,
      image: _str(d['image']),
      badges: {
        for (final b in MenuBadge.values)
          if (badgeNames.contains(b.name)) b,
      },
    );
  }

  // Promocje

  /// [startsAt] i [endsAt] Firestore zapisuje jako Timestamp.
  static Map<String, dynamic> promotion(
    Promotion p,
    int sortOrder, {
    bool active = true,
    DateTime? startsAt,
    DateTime? endsAt,
  }) => {
    'title': text(p.title),
    'body': text(p.body),
    'color': p.color.toARGB32(),
    'image': p.image,
    'sortOrder': sortOrder,
    'active': active,
    'startsAt': startsAt,
    'endsAt': endsAt,
  };

  /// Promocja bez względu na termin i włącznik (dla panelu).
  static Promotion anyPromotionFrom(String id, Map<String, dynamic> d) => Promotion(
    id: id,
    title: textOf(d['title']),
    body: textOf(d['body']),
    color: Color(_int(d['color'], 0xFFC6F432)),
    image: _str(d['image']),
  );

  /// Zwraca null dla wyłączonej promocji albo poza jej terminem.
  /// [startsAt] i [endsAt] to czasy już zamienione z Timestamp.
  static Promotion? promotionFrom(
    String id,
    Map<String, dynamic> d, {
    required DateTime now,
    DateTime? startsAt,
    DateTime? endsAt,
  }) {
    if (!_active(d)) return null;
    if (startsAt != null && now.isBefore(startsAt)) return null;
    if (endsAt != null && !now.isBefore(endsAt)) return null;
    return anyPromotionFrom(id, d);
  }

  // Lokal

  static String _time(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static TimeOfDay? _timeFrom(Object? raw) {
    if (raw is! String) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]), m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  static Map<String, dynamic> shop(Shop s) => {
    'name': s.name,
    'street': s.street,
    'city': s.city,
    'mapsQuery': s.mapsQuery,
    'instagram': s.instagram,
    'facebook': s.facebook,
    'hours': [
      for (final h in s.hours) h == null ? null : {'open': _time(h.open), 'close': _time(h.close)},
    ],
    'specialHours': specialHours(s.specialDays),
  };

  static Map<String, dynamic>? _dayHours(DayHours? h) =>
      h == null ? null : {'open': _time(h.open), 'close': _time(h.close)};

  static DayHours? _dayHoursFrom(Object? h) {
    if (h is! Map) return null;
    final open = _timeFrom(h['open']), close = _timeFrom(h['close']);
    return open == null || close == null ? null : DayHours(open, close);
  }

  static List<Map<String, dynamic>?> weekHours(List<DayHours?> hours) => [for (final h in hours) _dayHours(h)];

  /// Dni specjalne: {"2026-12-24": {open, close}} albo null, gdy zamknięte.
  static Map<String, dynamic> specialHours(List<SpecialDay> days) => {for (final d in days) d.key: _dayHours(d.hours)};

  static List<SpecialDay> specialDaysFrom(Object? raw) {
    if (raw is! Map) return const [];
    final out = <SpecialDay>[];
    for (final MapEntry(:key, :value) in raw.entries) {
      final date = key is String ? DateTime.tryParse(key) : null;
      if (date != null) out.add(SpecialDay(date, _dayHoursFrom(value)));
    }
    return out..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Brakujące pola biorą się z [fallback], żeby niepełny dokument nie psuł ekranu.
  static Shop shopFrom(Map<String, dynamic> d, Shop fallback) {
    final rawHours = d['hours'];
    List<DayHours?> hours = fallback.hours;
    if (rawHours is List && rawHours.length == 7) {
      hours = [for (final h in rawHours) _dayHoursFrom(h)];
    }
    return Shop(
      name: _str(d['name']) ?? fallback.name,
      street: _str(d['street']) ?? fallback.street,
      city: _str(d['city']) ?? fallback.city,
      mapsQuery: _str(d['mapsQuery']) ?? fallback.mapsQuery,
      instagram: _str(d['instagram']) ?? fallback.instagram,
      facebook: _str(d['facebook']) ?? fallback.facebook,
      hours: hours,
      specialDays: specialDaysFrom(d['specialHours']),
    );
  }

  // Karta pieczątek

  static StampCard stampCardFrom(Map<String, dynamic>? d) =>
      StampCard(stamps: _int(d?['stamps']).clamp(0, StampCard.goal), rewardsRedeemed: _int(d?['rewardsRedeemed']));

  /// Sortuje dokumenty po `sortOrder`, a przy remisie po id.
  static int bySortOrder(Map<String, dynamic> a, String aId, Map<String, dynamic> b, String bId) {
    final c = _int(a['sortOrder'], 1 << 30).compareTo(_int(b['sortOrder'], 1 << 30));
    return c != 0 ? c : aId.compareTo(bId);
  }
}
