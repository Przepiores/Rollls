import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ice_rolls/app.dart';
import 'package:ice_rolls/widgets/branch_transition.dart';
import 'package:ice_rolls/widgets/intro_splash.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('zakładki przenikają się zamiast skakać, nagłówek zostaje na miejscu', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(child: IceRollsApp()));
    // Pomijamy animację startową dotknięciem, jak użytkownik.
    await tester.tap(find.byType(IntroSplash));
    await tester.pumpAndSettle();

    final headerTop = tester.getTopLeft(find.text('Ice Rolls').first);
    await tester.tap(find.text('Menu').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final fades = tester
        .widgetList<FadeTransition>(
          find.descendant(of: find.byType(BranchTransition), matching: find.byType(FadeTransition)),
        )
        .map((f) => f.opacity.value)
        .where((v) => v > 0 && v < 1);
    expect(fades, isNotEmpty, reason: 'w połowie przejścia jakaś zakładka jest półprzezroczysta');

    await tester.pump(const Duration(seconds: 1));
    expect(tester.getTopLeft(find.text('Menu').first).dy, headerTop.dy);
  });
}
