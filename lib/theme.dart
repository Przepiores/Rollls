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

/// Lawendowe tło jak ściany lokalu i głęboki fiolet na tryb ciemny.
const lavender = Color(0xFFF6EEFF);
const lavenderDeep = Color(0xFFEBDDFF);
const night = Color(0xFF1C1030);
const nightCard = Color(0xFF2B1A45);
const neonPink = Color(0xFFFF4FA3);

const rainbow = LinearGradient(colors: RollColors.all);

const heroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [neonPink, RollColors.purple],
);

/// Neonowa poświata jak napis na ścianie lokalu.
List<BoxShadow> neonGlow(Color color, {double blur = 18}) => [
  BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: blur, spreadRadius: 1),
];

/// Pastelowy odcień koloru rolki, czytelny w obu motywach.
Color tint(BuildContext context, Color color, {double light = 0.22, double dark = 0.28}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Color.alphaBlend(color.withValues(alpha: isDark ? dark : light), isDark ? nightCard : paper);
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: RollColors.purple, brightness: brightness).copyWith(
    primary: dark ? neonPink : RollColors.purple,
    onPrimary: paper,
    secondary: RollColors.purple,
    surface: dark ? night : lavender,
    onSurface: dark ? const Color(0xFFF4F0FA) : ink,
    surfaceContainerHighest: dark ? nightCard : paper,
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
      backgroundColor: dark ? nightCard : lavenderDeep,
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
        side: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
  );
}
