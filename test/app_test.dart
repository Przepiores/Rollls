import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ice_rolls/app.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    // Skrzydła trzepoczą bez końca, więc w testach wyłączamy animacje jak w ustawieniach dostępności.
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const ProviderScope(child: IceRollsApp()));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, String text) async {
    final list = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(find.text(text), 200, scrollable: list);
    // Dociąga element nad dolny pasek nawigacji.
    await tester.drag(list, const Offset(0, -150));
    await tester.pumpAndSettle();
  }

  testWidgets('logowanie demo pokazuje kartę pieczątek i panel sklepu', (tester) async {
    await phone(tester);
    expect(find.text('Promocje'), findsOneWidget);

    await tester.tap(find.text('Pieczątki').last);
    await tester.pumpAndSettle();
    await scrollTo(tester, 'Kontynuuj z Google');
    await tester.tap(find.text('Kontynuuj z Google'));
    await tester.pumpAndSettle();
    expect(find.text('7 z 10 pieczątek'), findsOneWidget);
    expect(find.text('Zeskanuj kod na pieczątkę'), findsOneWidget);

    await tester.tap(find.text('Więcej'));
    await tester.pumpAndSettle();
    await scrollTo(tester, 'Panel sklepu');
    await tester.tap(find.text('Panel sklepu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Symuluj skan (prototyp)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dodaj pieczątki'));
    await tester.pumpAndSettle();
    expect(find.text('Dodano 1 pieczątkę'), findsOneWidget);
  });

  testWidgets('przełączenie na angielski', (tester) async {
    await phone(tester);
    await tester.tap(find.text('Więcej'));
    await tester.pumpAndSettle();
    await scrollTo(tester, 'EN');
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
  });
}
