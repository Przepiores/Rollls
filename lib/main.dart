import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load brand fonts before the first frame, so chips are not measured with a fallback font.
  GoogleFonts.fredoka(fontWeight: FontWeight.w600);
  GoogleFonts.nunito(fontWeight: FontWeight.w700);
  await GoogleFonts.pendingFonts().catchError((_) => const <void>[]);
  runApp(const ProviderScope(child: IceRollsApp()));
}
