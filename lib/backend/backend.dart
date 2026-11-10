import 'dart:async';

import '../data/menu_data.dart' as bundled;
import '../data/models.dart';
import '../data/shop_data.dart' as bundled;
import '../loyalty/stamp_claims.dart';

/// Zalogowany użytkownik.
class Session {
  const Session({required this.uid, required this.name, this.email, this.role, this.marketingConsent = false});

  final String uid;
  final String name;
  final String? email;

  /// `owner`, `staff` albo null dla klienta. W Firebase to custom claim `role`.
  final String? role;
  final bool marketingConsent;

  bool get isStaff => role == 'staff' || role == 'owner';
  bool get isOwner => role == 'owner';

  Session copyWith({bool? marketingConsent}) => Session(
    uid: uid,
    name: name,
    email: email,
    role: role,
    marketingConsent: marketingConsent ?? this.marketingConsent,
  );
}

/// Błąd logowania pokazywany klientowi.
enum AuthError { invalidCredentials, emailInUse, weakPassword, invalidEmail, cancelled, network, unknown }

class AuthException implements Exception {
  const AuthException(this.error);
  final AuthError error;
  @override
  String toString() => 'AuthException($error)';
}

/// Źródło danych aplikacji: menu, promocje, konta i pieczątki.
///
/// [LocalBackend] działa bez internetu na danych z `lib/data`.
/// `FirebaseBackend` czyta to samo z Firestore, gdy aplikacja ma konfigurację Firebase.
abstract interface class Backend {
  /// True, gdy dane idą z Firebase.
  bool get isRemote;

  Stream<List<MenuCategory>> categories();
  Stream<List<MenuItem>> menuItems();
  Stream<List<Promotion>> promotions();
  Stream<Shop> shop();

  Stream<Session?> session();
  Stream<StampCard> stampCard(String uid);
  StampCodeService get stampCodes;

  /// Treść kodu QR klienta, który obsługa skanuje przy odbiorze nagrody.
  String customerCode(String uid);

  Future<void> signInWithEmail(String email, String password);
  Future<void> registerWithEmail({required String name, required String email, required String password});
  Future<void> sendPasswordReset(String email);
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<void> setMarketingConsent(bool value);

  /// Dla obsługi: ręczne nabicie pieczątek i odbiór nagrody na koncie klienta.
  Future<void> addStamps(String uid, int count);
  Future<void> redeemReward(String uid);

  /// Dla właściciela: wgrywa menu, promocje i dane lokalu z aplikacji do bazy.
  /// Nadpisuje dokumenty o tych samych id, innych nie rusza.
  Future<int> uploadBundledData();
}

/// Prototyp bez serwera: dane z plików w `lib/data`, konto demo w pamięci.
class LocalBackend implements Backend {
  LocalBackend({StampCodeService? stampCodes}) : stampCodes = stampCodes ?? LocalStampCodeService();

  static const demoUid = 'demo';

  @override
  final StampCodeService stampCodes;

  final _session = _Value<Session?>(null);
  final _card = _Value(const StampCard(stamps: 7, rewardsRedeemed: 1));

  @override
  bool get isRemote => false;

  @override
  Stream<List<MenuCategory>> categories() => Stream.value(bundled.categories);
  @override
  Stream<List<MenuItem>> menuItems() => Stream.value(bundled.menuItems);
  @override
  Stream<List<Promotion>> promotions() => Stream.value(bundled.promotions);
  @override
  Stream<Shop> shop() => Stream.value(bundled.shop);

  @override
  Stream<Session?> session() => _session.stream;
  @override
  Stream<StampCard> stampCard(String uid) => _card.stream;

  @override
  String customerCode(String uid) => 'icerolls:demo-customer';

  /// Prototyp: każde logowanie daje konto właściciela, żeby dało się obejrzeć panel sklepu.
  void _signInDemo() => _session.value = const Session(uid: demoUid, name: 'Kris', role: 'owner');

  @override
  Future<void> signInWithEmail(String email, String password) async => _signInDemo();
  @override
  Future<void> registerWithEmail({required String name, required String email, required String password}) async =>
      _signInDemo();
  @override
  Future<void> sendPasswordReset(String email) async {}
  @override
  Future<void> signInWithGoogle() async => _signInDemo();
  @override
  Future<void> signOut() async => _session.value = null;
  @override
  Future<void> setMarketingConsent(bool value) async =>
      _session.value = _session.value?.copyWith(marketingConsent: value);

  @override
  Future<void> addStamps(String uid, int count) async => _card.value = _card.value.addStamps(count);
  @override
  Future<void> redeemReward(String uid) async => _card.value = _card.value.redeem();

  @override
  Future<int> uploadBundledData() async => 0;
}

/// Wartość, której strumień od razu oddaje bieżący stan, a potem każdą zmianę.
class _Value<T> {
  _Value(this._value);
  T _value;
  final _changes = StreamController<T>.broadcast(sync: true);

  T get value => _value;
  set value(T v) {
    _value = v;
    _changes.add(v);
  }

  Stream<T> get stream {
    late final StreamController<T> out;
    StreamSubscription<T>? sub;
    out = StreamController<T>(
      onListen: () {
        out.add(_value);
        sub = _changes.stream.listen(out.add);
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }
}
