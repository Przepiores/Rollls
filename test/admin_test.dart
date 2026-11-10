import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ice_rolls/backend/backend.dart';
import 'package:ice_rolls/l10n/app_localizations.dart';
import 'package:ice_rolls/screens/admin/admin_screen.dart';
import 'package:ice_rolls/screens/admin/customer_screen.dart';
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

  test('kod klienta z wersji demo daje uid, inne kody nie', () {
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
}
