import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'backend/firebase_backend.dart';
import 'backend/firebase_config.dart';
import 'state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load brand fonts before the first frame, so chips are not measured with a fallback font.
  GoogleFonts.fredoka(fontWeight: FontWeight.w600);
  GoogleFonts.nunito(fontWeight: FontWeight.w700);
  // Bez sieci albo przy zablokowanym serwerze czcionek nie czekamy w nieskończoność.
  await GoogleFonts.pendingFonts().timeout(const Duration(seconds: 5)).catchError((_) => const <void>[]);

  final overrides = [if (await _initFirebase()) backendProvider.overrideWithValue(FirebaseBackend())];
  runApp(ProviderScope(overrides: overrides, child: const IceRollsApp()));
}

/// Łączy z Firebase, jeśli aplikacja ma konfigurację. Bez niej albo po błędzie
/// aplikacja działa dalej na danych wbudowanych (tryb prototypu).
Future<bool> _initFirebase() async {
  if (!FirebaseConfig.isConfigured) return false;
  try {
    // Na webie Firebase dociąga skrypty z www.gstatic.com. Gdy są zablokowane
    // (np. przez bloker reklam), inicjalizacja nigdy się nie kończy, a ekran
    // zostawał biały. Po limicie czasu przechodzimy na dane wbudowane.
    await Firebase.initializeApp(options: FirebaseConfig.currentOptions).timeout(const Duration(seconds: 12));
    // Menu i karta pieczątek działają też bez sieci, z pamięci podręcznej.
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    return true;
  } catch (e) {
    debugPrint('Firebase: $e');
    return false;
  }
}
