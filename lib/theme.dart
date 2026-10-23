import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kolory sześciu rolek z logo Ice Rolls.
abstract final class RollColors {
  static const lime = Color(0xFFB5D334);
  static const red = Color(0xFFE8332A);
  static const pink = Color(0xFFF07AA6);
  static const purple = Color(0xFF8A2A9B);
  static const yellow = Color(0xFFF7C923);
  static const sky = Color(0xFF8EC8E8);

  static const all = [lime, red, pink, purple, yellow, sky];
}

const ink = Color(0xFF15121C);
const paper = Color(0xFFFFFFFF);
const night = Color(0xFF16131D);
const nightCard = Color(0xFF231F2C);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: RollColors.purple, brightness: brightness).copyWith(
    primary: dark ? RollColors.pink : ink,
    onPrimary: dark ? ink : paper,
    secondary: RollColors.purple,
    surface: dark ? night : paper,
    onSurface: dark ? const Color(0xFFF4F0FA) : ink,
    surfaceContainerHighest: dark ? nightCard : const Color(0xFFF6F3FA),
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
  final body = GoogleFonts.nunitoTextTheme(base.textTheme);
  final display = GoogleFonts.fredokaTextTheme(base.textTheme);

  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: body
        .copyWith(
          displaySmall: display.displaySmall?.copyWith(fontWeight: FontWeight.w700),
          headlineMedium: display.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          headlineSmall: display.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          titleMedium: display.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w600, color: scheme.onSurface),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: RollColors.yellow,
      labelTextStyle: WidgetStatePropertyAll(GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 12)),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? ink : scheme.onSurface),
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerHighest,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    chipTheme: base.chipTheme.copyWith(
      labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
      shape: const StadiumBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 15),
        side: BorderSide(color: scheme.onSurface, width: 1.5),
      ),
    ),
  );
}
