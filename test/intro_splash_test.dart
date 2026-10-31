import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ice_rolls/app.dart';
import 'package:ice_rolls/widgets/intro_splash.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('animacja startowa znika po rozłożeniu skrzydeł', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(child: IceRollsApp()));
    expect(find.byType(IntroSplash), findsOneWidget);
    // Animacja czeka na logo, najwyżej półtorej sekundy.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byType(IntroSplash), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();
    expect(find.byType(IntroSplash), findsNothing);
  });

  testWidgets('przy wyłączonych animacjach od razu pokazuje aplikację', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const ProviderScope(child: IceRollsApp()));
    await tester.pump();
    await tester.pump();
    expect(find.byType(IntroSplash), findsNothing);
  });
}
