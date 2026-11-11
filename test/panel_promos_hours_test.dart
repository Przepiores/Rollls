import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ice_rolls/backend/backend.dart';
import 'package:ice_rolls/backend/codec.dart';
import 'package:ice_rolls/data/models.dart';
import 'package:ice_rolls/data/opening_hours.dart';
import 'package:ice_rolls/data/shop_data.dart' as bundled;
import 'package:ice_rolls/l10n/app_localizations.dart';
import 'package:ice_rolls/screens/admin/category_note_edit_screen.dart';
import 'package:ice_rolls/screens/admin/hours_admin_screen.dart';
import 'package:ice_rolls/screens/admin/promotion_edit_screen.dart';
import 'package:ice_rolls/screens/admin/promotions_admin_screen.dart';
import 'package:ice_rolls/state.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // 2026-12-21 to poniedziałek.
  final christmasEve = DateTime(2026, 12, 24);

  group('dni specjalne', () {
    test('zamknięty dzień specjalny przesuwa otwarcie na kolejny dzień', () {
      final s = openStatus(bundled.shop.hours, DateTime(2026, 12, 24, 15), special: [SpecialDay(christmasEve)]);
      expect(s, isA<ClosedNow>());
      expect((s as ClosedNow).daysAhead, 1);
    });

    test('krótszy dzień specjalny ma swoje godziny', () {
      const short = DayHours(TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 14, minute: 0));
      final special = [SpecialDay(christmasEve, short)];
      expect(openStatus(bundled.shop.hours, DateTime(2026, 12, 24, 15), special: special), isA<ClosedNow>());
      final open = openStatus(bundled.shop.hours, DateTime(2026, 12, 24, 12), special: special) as OpenNow;
      expect(formatTime(open.closesAt), '14:00');
    });

    test('codec zapisuje i czyta dni specjalne', () {
      const short = DayHours(TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 14, minute: 0));
      final shop = bundled.shop.copyWith(
        specialDays: [SpecialDay(christmasEve), SpecialDay(DateTime(2026, 12, 31), short)],
      );
      final map = Codec.shop(shop);
      expect(map['specialHours'], {
        '2026-12-24': null,
        '2026-12-31': {'open': '10:00', 'close': '14:00'},
      });
      final back = Codec.shopFrom(map, bundled.shop);
      expect(back.specialDays.map((d) => d.key), ['2026-12-24', '2026-12-31']);
      expect(back.specialDays.first.hours, isNull);
      expect(formatTime(back.specialDays.last.hours!.close), '14:00');
    });

    test('lista nadchodzących pomija minione dni', () {
      final list = upcomingSpecialDays([
        SpecialDay(DateTime(2026, 12, 1)),
        SpecialDay(christmasEve),
      ], DateTime(2026, 12, 10));
      expect(list.map((d) => d.key), ['2026-12-24']);
    });
  });

  test('status promocji w panelu', () {
    final l = lookupAppLocalizations(const Locale('pl'));
    const promo = Promotion(id: 'x', title: LocalizedText('A', 'A'), body: LocalizedText('B', 'B'), color: Colors.pink);
    final now = DateTime(2026, 12, 10, 12);
    AdminPromotion p({bool active = true, DateTime? from, DateTime? to}) =>
        AdminPromotion(promotion: promo, active: active, sortOrder: 0, startsAt: from, endsAt: to);
    expect(promoStatus(l, p(), now), 'Widoczna teraz');
    expect(promoStatus(l, p(active: false), now), 'Wyłączona');
    expect(promoStatus(l, p(from: DateTime(2026, 12, 20)), now), 'Pokaże się 20.12');
    expect(promoStatus(l, p(to: DateTime(2026, 12, 25)), now), 'Widoczna do 24.12');
    expect(promoStatus(l, p(to: DateTime(2026, 12, 1)), now), 'Zakończona');
    expect(p(to: DateTime(2026, 12, 1)).visibleAt(now), isFalse);
  });

  Future<ProviderContainer> open(WidgetTester tester, Widget Function(ProviderContainer c) screen) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(backendProvider).signInWithGoogle();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('pl'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen(container))),
                  child: const Text('start'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('edycja ramki z cenami zapisuje notatkę kategorii', (tester) async {
    final c = await open(tester, (c) => CategoryNoteEditScreen(category: c.read(categoriesProvider).first));
    await tester.enterText(find.byType(TextField).first, 'Mała 10 zł, Duża 15 zł');
    await tester.pumpAndSettle();
    expect(find.text('Duża'), findsOneWidget, reason: 'podgląd pokazuje kafelki');
    await tapVisible(tester, find.text('Zapisz'));

    final categories = await tester.runAsync(() => c.read(backendProvider).categories().first);
    expect(categories!.first.note!.pl, 'Mała 10 zł, Duża 15 zł');
    expect(categories.first.note!.en, startsWith('1\u00a0ingredient'), reason: 'angielska wersja zostaje');
  });

  testWidgets('nowa promocja trafia do klientów, wyłączona znika', (tester) async {
    final c = await open(tester, (_) => const PromotionsAdminScreen());
    await tester.tap(find.text('Dodaj promocję'));
    await tester.pumpAndSettle();
    expect(find.byType(PromotionEditScreen), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Tytuł (PL)'), 'Happy hour');
    await tester.enterText(find.widgetWithText(TextFormField, 'Opis (PL)'), '-20% od 18:00');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Zapisz'));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    Future<List<String>> visible() async => [
      for (final p in (await tester.runAsync(() => c.read(backendProvider).promotions().first))!) p.title.pl,
    ];
    expect(await visible(), contains('Happy hour'));

    await tester.scrollUntilVisible(find.text('Happy hour'), 300, scrollable: find.byType(Scrollable).first);
    final tile = find.ancestor(of: find.text('Happy hour'), matching: find.byType(ListTile));
    await tester.tap(find.descendant(of: tile, matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(await visible(), isNot(contains('Happy hour')));
  });

  testWidgets('godziny: zamknięta niedziela', (tester) async {
    final c = await open(tester, (_) => const HoursAdminScreen());
    final sunday = find.descendant(of: find.byKey(const ValueKey('week-6')), matching: find.byType(Switch));
    await tapVisible(tester, sunday);
    await tapVisible(tester, find.text('Zapisz'));

    final shop = await tester.runAsync(() => c.read(backendProvider).shop().first);
    expect(shop!.hours[6], isNull);
    expect(shop.hours[0], isNotNull);
  });

  testWidgets('godziny: zamknięcie przed otwarciem blokuje zapis', (tester) async {
    final c = await open(tester, (_) => const HoursAdminScreen());
    final backend = c.read(backendProvider) as LocalBackend;
    // Zły zakres wstawiamy przez backend, a ekran otwieramy od nowa.
    await backend.saveHours([
      const DayHours(TimeOfDay(hour: 20, minute: 0), TimeOfDay(hour: 10, minute: 0)),
      ...bundled.shop.hours.skip(1),
    ], const []);
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(HoursAdminScreen))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();
    expect(find.text('Zamknięcie musi być po otwarciu'), findsWidgets);
    await tapVisible(tester, find.text('Zapisz'));
    expect(find.byType(HoursAdminScreen), findsOneWidget);
  });
}
