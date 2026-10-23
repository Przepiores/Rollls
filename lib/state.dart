import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/models.dart';

/// Ustawienia i stan klienta. W prototypie trzymane w pamięci,
/// w wersji z Firebase przejdą do Firestore i Firebase Auth.

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('pl');
  void set(Locale locale) => state = locale;
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;
  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class Session {
  const Session({required this.name, required this.isStaff, this.marketingConsent = false});
  final String name;
  final bool isStaff;
  final bool marketingConsent;

  Session copyWith({bool? marketingConsent}) =>
      Session(name: name, isStaff: isStaff, marketingConsent: marketingConsent ?? this.marketingConsent);
}

class SessionNotifier extends Notifier<Session?> {
  @override
  Session? build() => null;

  /// Prototyp: każde logowanie daje konto właściciela, żeby dało się obejrzeć panel sklepu.
  void signInDemo() => state = const Session(name: 'Kris', isStaff: true);
  void signOut() => state = null;
  void setMarketingConsent(bool value) => state = state?.copyWith(marketingConsent: value);
}

final sessionProvider = NotifierProvider<SessionNotifier, Session?>(SessionNotifier.new);

class StampCardNotifier extends Notifier<StampCard> {
  @override
  StampCard build() => const StampCard(stamps: 7, rewardsRedeemed: 1);
  void add(int count) => state = state.addStamps(count);
  void redeem() => state = state.redeem();
}

final stampCardProvider = NotifierProvider<StampCardNotifier, StampCard>(StampCardNotifier.new);
