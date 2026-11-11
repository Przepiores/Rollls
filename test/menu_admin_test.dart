import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ice_rolls/data/menu_data.dart' as bundled;
import 'package:ice_rolls/l10n/app_localizations.dart';
import 'package:ice_rolls/screens/admin/menu_admin_screen.dart';
import 'package:ice_rolls/screens/admin/menu_item_edit_screen.dart';
import 'package:ice_rolls/state.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('cena z pola tekstowego', () {
    expect(parsePrice('23'), 2300);
    expect(parsePrice('23,5'), 2350);
    expect(parsePrice(' 23.50 zł '), 2350);
    expect(parsePrice('0'), isNull);
    expect(parsePrice('abc'), isNull);
    expect(parsePrice('12,345'), isNull);
    expect(priceText(2350), '23,50');
    expect(priceText(2000), '20');
  });

  Future<ProviderContainer> open(WidgetTester tester) async {
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
          home: const MenuAdminScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<List<String>> visibleNames(WidgetTester tester, ProviderContainer c) async {
    final items = await tester.runAsync(() => c.read(backendProvider).menuItems().first);
    return [for (final i in items!) i.id];
  }

  testWidgets('ukrycie pozycji przenosi ją do ukrytych, a włączenie przywraca', (tester) async {
    final c = await open(tester);
    final first = bundled.menuItems.first.id;
    final firstName = bundled.menuItems.first.name.pl;
    expect(find.text('Ukryte (1)'), findsNothing);

    // Nad listą jest ramka z cenami, więc pierwsza pozycja bywa poniżej ekranu.
    await tester.scrollUntilVisible(find.text(firstName), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Ukryte (1)'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Ukryte (1)'), findsOneWidget);
    expect(await visibleNames(tester, c), isNot(contains(first)));

    await tester.scrollUntilVisible(find.text(firstName), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(find.text('Ukryte (1)'), findsNothing);
    expect(await visibleNames(tester, c), contains(first));
  });

  testWidgets('dodanie nowej pozycji z ceną', (tester) async {
    final c = await open(tester);
    await tester.tap(find.text('Dodaj pozycję'));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Zapisz'));
    await tester.scrollUntilVisible(find.text('Wpisz nazwę'), -300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Wpisz nazwę'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Wpisz cenę, np. 23 albo 23,50'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Wpisz cenę, np. 23 albo 23,50'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.widgetWithText(TextFormField, 'Nazwa (PL)'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Nazwa (PL)'), 'Lody pistacjowe');
    await tester.scrollUntilVisible(
      find.widgetWithText(TextFormField, 'Cena (zł)'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Cena (zł)'), '24,50');
    await tapVisible(tester, find.text('Zapisz'));

    await tester.scrollUntilVisible(find.text('Lody pistacjowe'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Lody pistacjowe'), findsOneWidget);
    final items = await tester.runAsync(() => c.read(backendProvider).menuItems().first);
    final added = items!.singleWhere((i) => i.name.pl == 'Lody pistacjowe');
    expect(added.prices.single.grosze, 2450);
    expect(added.name.en, 'Lody pistacjowe');
    expect(added.categoryId, bundled.categories.first.id);
  });

  testWidgets('zmiana ceny i usunięcie pozycji', (tester) async {
    final c = await open(tester);
    final first = bundled.menuItems.first;
    await tapVisible(tester, find.text(first.name.pl));

    await tester.scrollUntilVisible(
      find.widgetWithText(TextFormField, 'Cena (zł)').first,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Cena (zł)').first, '99');
    await tapVisible(tester, find.text('Zapisz'));
    var items = await tester.runAsync(() => c.read(backendProvider).menuItems().first);
    expect(items!.singleWhere((i) => i.id == first.id).prices.first.grosze, 9900);

    // Komunikat „Zapisano” zasłania dół ekranu, czekamy aż zniknie.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(first.name.pl));
    await tapVisible(tester, find.text('Usuń pozycję'));
    await tester.tap(find.widgetWithText(FilledButton, 'Usuń pozycję'));
    await tester.pumpAndSettle();
    items = await tester.runAsync(() => c.read(backendProvider).menuItems().first);
    expect(items!.where((i) => i.id == first.id), isEmpty);
    expect(find.text('Usunięto pozycję'), findsOneWidget);
  });
}
