import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backend/backend.dart';
import 'data/menu_data.dart' as bundled;
import 'data/models.dart';
import 'data/shop_data.dart' as bundled;
import 'loyalty/stamp_claims.dart';

export 'backend/backend.dart' show Session;

/// Ustawienia i stan klienta. Dane idą z [Backend]: lokalnie w prototypie,
/// z Firebase, gdy aplikacja ma konfigurację (patrz `main.dart`).

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('pl');
  void set(Locale locale) => state = locale;
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;
  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Podmieniany w `main.dart` na `FirebaseBackend`, gdy jest konfiguracja Firebase.
final backendProvider = Provider<Backend>((ref) => LocalBackend());

// Menu, promocje i lokal. Zanim baza odpowie (albo gdy jest pusta lub bez sieci),
// pokazujemy dane wbudowane w aplikację, żeby ekran nigdy nie był pusty.

final _categoriesStream = StreamProvider<List<MenuCategory>>((ref) => ref.watch(backendProvider).categories());
final _menuItemsStream = StreamProvider<List<MenuItem>>((ref) => ref.watch(backendProvider).menuItems());
final _promotionsStream = StreamProvider<List<Promotion>>((ref) => ref.watch(backendProvider).promotions());
final _shopStream = StreamProvider<Shop>((ref) => ref.watch(backendProvider).shop());

List<T> _orBundled<T>(AsyncValue<List<T>> v, List<T> fallback) {
  final list = v.value;
  return list == null || list.isEmpty ? fallback : list;
}

final categoriesProvider = Provider<List<MenuCategory>>(
  (ref) => _orBundled(ref.watch(_categoriesStream), bundled.categories),
);
final menuItemsProvider = Provider<List<MenuItem>>((ref) => _orBundled(ref.watch(_menuItemsStream), bundled.menuItems));

/// Promocje mogą być celowo puste (wszystkie wyłączone), więc tu nie ma
/// zastępstwa, gdy baza odpowiedziała pustą listą.
final promotionsProvider = Provider<List<Promotion>>((ref) => ref.watch(_promotionsStream).value ?? bundled.promotions);
final shopProvider = Provider<Shop>((ref) => ref.watch(_shopStream).value ?? bundled.shop);

final _sessionStream = StreamProvider<Session?>((ref) => ref.watch(backendProvider).session());

/// Zalogowany użytkownik albo null.
final sessionProvider = Provider<Session?>((ref) => ref.watch(_sessionStream).value);

final _stampCardStream = StreamProvider<StampCard>((ref) {
  final uid = ref.watch(sessionProvider.select((s) => s?.uid));
  if (uid == null) return Stream.value(const StampCard());
  return ref.watch(backendProvider).stampCard(uid);
});

/// Karta pieczątek zalogowanego klienta.
final stampCardProvider = Provider<StampCard>((ref) => ref.watch(_stampCardStream).value ?? const StampCard());

/// Null, gdy klient nie skanuje kodów sam (Firebase na planie Spark).
final stampCodeServiceProvider = Provider<StampCodeService?>((ref) => ref.watch(backendProvider).stampCodes);

/// Ile skanów kodu zostało dziś zalogowanemu klientowi.
final scansLeftTodayProvider = FutureProvider<int>((ref) async {
  final uid = ref.watch(sessionProvider.select((s) => s?.uid));
  final service = ref.watch(stampCodeServiceProvider);
  if (uid == null || service == null) return StampCodeService.dailyScanLimit;
  return service.scansLeftToday(uid);
});

/// Kod z naklejki przy ladzie. Prototyp: jedna naklejka ważna do końca 2027 r.
final counterStickerProvider = FutureProvider<String>(
  (ref) => ref.watch(stampCodeServiceProvider)!.issueSticker(id: 'lada-1', validUntil: DateTime.utc(2028)),
);
