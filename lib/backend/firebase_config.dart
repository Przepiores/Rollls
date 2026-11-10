import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Publiczna konfiguracja klienta Firebase (to nie są sekrety: te same
/// wartości widzi każdy, kto otworzy stronę PWA). Dostęp do danych chronią
/// reguły w `firestore.rules`.
///
/// Wartości z konsoli Firebase (projekt ice-rolls-c550f): Ustawienia projektu →
/// Ogólne → Twoje aplikacje. Można je nadpisać przez `--dart-define`.
/// `--dart-define=BACKEND=local` wymusza dane lokalne (tryb prototypu).
abstract final class FirebaseConfig {
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'ice-rolls-c550f');
  static const apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyBvOwM2mFt9AqshFw29Bmzps6ResmjMeFg',
  );
  static const messagingSenderId = String.fromEnvironment('FIREBASE_SENDER_ID', defaultValue: '456967690668');
  static const webAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '1:456967690668:web:da69df9758145baf69c209',
  );
  static const androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '1:456967690668:android:ae2976bedc80882369c209',
  );
  static const iosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
    defaultValue: '1:456967690668:ios:b0c8b3d5bf84f9d069c209',
  );

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
