import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ice_rolls/l10n/app_localizations.dart';
import 'package:ice_rolls/screens/scan_screen.dart';
import 'package:ice_rolls/state.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('skan kodu dodaje pieczątkę, a po dwóch skanach działa limit', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(sessionProvider.notifier).signInDemo();
    final service = container.read(stampCodeServiceProvider);
    late void Function(String) scan;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('pl'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ScanScreen(
                    camera: (onCode) {
                      scan = onCode;
                      return const SizedBox.expand();
                    },
                  ),
                ),
              ),
              child: const Text('otwórz'),
            ),
          ),
        ),
      ),
    );

    Future<void> open() async {
      await tester.tap(find.text('otwórz'));
      await tester.pumpAndSettle();
    }

    await open();
    expect(find.text('Dziś zostały jeszcze 2 skany'), findsOneWidget);
    scan(await service.issue(stamps: 2, validFor: const Duration(minutes: 2)));
    await tester.pumpAndSettle();
    expect(find.text('Dodano 2 pieczątki'), findsOneWidget);
    expect(container.read(stampCardProvider).stamps, 9);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('otwórz'), findsOneWidget);

    await open();
    await tester.tap(find.text('Zeskanuj przykładowy kod (prototyp)'));
    await tester.pumpAndSettle();
    expect(find.text('Dodano 1 pieczątkę'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    container.read(stampCardProvider.notifier).redeem();
    await open();
    expect(find.text('Na dziś wykorzystano wszystkie skany'), findsOneWidget);
    scan('IR1.zly.1.0.kod');
    await tester.pumpAndSettle();
    expect(find.text('To nie jest kod Ice Rolls albo jest uszkodzony'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    scan(await service.issue(stamps: 1, validFor: const Duration(minutes: 2)));
    await tester.pumpAndSettle();
    expect(find.text('Dziś zeskanowano już 2 kody. Wróć jutro!'), findsOneWidget);
  });
}
