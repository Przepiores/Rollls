import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ice_rolls/backend/backend.dart';
import 'package:ice_rolls/backend/firebase_backend.dart';
import 'package:ice_rolls/l10n/app_localizations.dart';
import 'package:ice_rolls/screens/admin/admin_screen.dart';
import 'package:ice_rolls/screens/admin/customer_screen.dart';
import 'package:ice_rolls/screens/admin/sticker_screen.dart';
import 'package:ice_rolls/state.dart';

Widget _app(ProviderContainer container, Widget home) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    locale: const Locale('pl'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('kod klienta IRU1.<uid> daje uid, inne kody nie', () {
    expect(FirebaseBackend.uidFromCustomerCode('IRU1.abcDEF123'), 'abcDEF123');
    expect(FirebaseBackend.uidFromCustomerCode(' IRU1.abc \n'), 'abc');
    expect(FirebaseBackend.uidFromCustomerCode('IR1.abc.1.2.sig'), isNull);
    expect(FirebaseBackend.uidFromCustomerCode('IRU1.abc/../x'), isNull);
    expect(FirebaseBackend.uidFromCustomerCode('IRU1.'), isNull);

    final local = LocalBackend();
    expect(local.customerUidFromCode(local.customerCode('x')), LocalBackend.demoUid);
    expect(local.customerUidFromCode('IRU1.abc'), isNull);
  });

  testWidgets('bez konta obsługi panel pokazuje brak dostępu', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container, const AdminScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('tylko dla obsługi sklepu'), findsOneWidget);
    expect(find.text('Wydaj pieczątki'), findsNothing);
  });

  testWidgets('skan kodu klienta pokazuje kartę, dodaje pieczątki i wydaje nagrodę', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final backend = container.read(backendProvider);
    await backend.signInWithGoogle();
    late void Function(String) scan;

    await tester.pumpWidget(
      _app(
        container,
        CustomerScreen(
          camera: (onCode) {
            scan = onCode;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    scan('IR1.cos.innego');
    await tester.pumpAndSettle();
    expect(find.textContaining('To nie jest kod klienta'), findsOneWidget);

    scan(backend.customerCode(LocalBackend.demoUid));
    await tester.pumpAndSettle();
    expect(find.text('Klient demo'), findsOneWidget);

    // Karta demo ma 7 z 10 pieczątek: dobijamy 3 i wydajemy nagrodę.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.text('Dodaj pieczątki'));
    await tester.pumpAndSettle();
    expect(find.text('Dodano 3 pieczątki'), findsOneWidget);

    await tester.tap(find.text('Wydaj darmowego loda'));
    await tester.pumpAndSettle();
    expect(find.text('Nagroda wydana, karta zaczyna się od nowa'), findsOneWidget);
    final card = await tester.runAsync(() => backend.customer(LocalBackend.demoUid).first);
    expect(card!.card.stamps, 0);
    expect(card.card.rewardsRedeemed, 2);
  });

  testWidgets('właściciel wymienia naklejkę, a stara przestaje być aktywna', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final backend = container.read(backendProvider);
    await backend.signInWithGoogle();
    container.listen(sessionProvider, (_, _) {});

    await tester.pumpWidget(_app(container, const StickerScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Ważna do 1.01.2028'), findsOneWidget);

    await tester.tap(find.text('Wymień naklejkę'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Wymień naklejkę'));
    await tester.pumpAndSettle();

    final stickers = (await tester.runAsync(() => backend.stickers().first))!;
    expect(stickers.where((s) => s.active).map((s) => s.id), isNot(contains('lada-1')));
    expect(stickers.where((s) => s.active), hasLength(1));
    expect(find.text('Nowa naklejka gotowa. Stara już nie działa.'), findsOneWidget);
  });
}
