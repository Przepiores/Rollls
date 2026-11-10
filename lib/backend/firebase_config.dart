import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Publiczna konfiguracja klienta Firebase (to nie są sekrety: te same
/// wartości widzi każdy, kto otworzy stronę PWA). Dostęp do danych chronią
/// reguły w `firestore.rules`.
///
/// Wartości z konsoli Firebase: Ustawienia projektu → Ogólne → Twoje aplikacje.
/// Dopóki [projectId] jest pusty, aplikacja działa na danych lokalnych
/// (tryb prototypu), więc buildy APK i PWA nie psują się bez Firebase.
abstract final class FirebaseConfig {
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const messagingSenderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');

  /// Ustaw `--dart-define=BACKEND=local`, żeby wymusić dane lokalne mimo konfiguracji.
  static const _forceLocal = String.fromEnvironment('BACKEND') == 'local';

  static bool get isConfigured => !_forceLocal && projectId.isNotEmpty && apiKey.isNotEmpty && currentOptions != null;

  static FirebaseOptions? get currentOptions {
    final appId = kIsWeb
        ? webAppId
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => androidAppId,
            TargetPlatform.iOS => iosAppId,
            _ => '',
          };
    if (appId.isEmpty) return null;
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: '$projectId.firebaseapp.com',
      storageBucket: '$projectId.firebasestorage.app',
      iosBundleId: 'pl.icerolls.iceRolls',
    );
  }
}
