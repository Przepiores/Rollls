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

/// Klient widziany przez obsługę po zeskanowaniu jego kodu.
class Customer {
  const Customer({required this.uid, required this.name, this.email, required this.card});
  final String uid;
  final String name;
  final String? email;
  final StampCard card;
}

/// Pozycja menu widziana w panelu: także wyłączona, z miejscem na liście.
class AdminMenuItem {
  const AdminMenuItem({required this.item, required this.active, required this.sortOrder});
  final MenuItem item;
  final bool active;
  final int sortOrder;
}

/// Promocja widziana w panelu: także wyłączona albo poza terminem.
class AdminPromotion {
  const AdminPromotion({
    required this.promotion,
    required this.active,
    required this.sortOrder,
    this.startsAt,
    this.endsAt,
  });
  final Promotion promotion;
  final bool active;
  final int sortOrder;

  /// Od kiedy klienci ją widzą (null = od razu).
  final DateTime? startsAt;

  /// Od kiedy już jej nie widzą (null = bez końca).
  final DateTime? endsAt;

  /// Czy klient widzi ją w chwili [now].
  bool visibleAt(DateTime now) =>
      active && (startsAt == null || !now.isBefore(startsAt!)) && (endsAt == null || now.isBefore(endsAt!));
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

  /// Kody QR, które klient skanuje sam (paragon, naklejka przy ladzie).
  /// Null z Firebase na planie Spark: bez serwera nie da się bezpiecznie
  /// sprawdzić kodu, więc pieczątki dopisuje obsługa po zeskanowaniu kodu klienta.
  StampCodeService? get stampCodes;

  /// Treść kodu QR klienta, który obsługa skanuje przy odbiorze nagrody.
  String customerCode(String uid);

  /// Odwrotność [customerCode]: uid klienta albo null, gdy to nie jest kod klienta.
  String? customerUidFromCode(String raw);

  /// Dla obsługi: profil i karta klienta. Null, gdy konta nie ma.
  Stream<Customer?> customer(String uid);

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

  /// Dla panelu: wszystkie pozycje menu, także wyłączone, w kolejności z bazy.
  Stream<List<AdminMenuItem>> adminMenuItems();

  /// Nowy identyfikator dla dodawanej pozycji.
  String newMenuItemId();

  /// Zapisuje pozycję (nową albo zmienioną). Zdjęcie zostaje takie, jak w [item].
  Future<void> saveMenuItem(MenuItem item, {required bool active, required int sortOrder});

  /// Włącza albo ukrywa pozycję w menu klientów.
  Future<void> setMenuItemActive(String id, bool active);

  Future<void> deleteMenuItem(String id);

  /// Zmienia ramkę z informacją nad listą kategorii. Null usuwa ramkę.
  Future<void> saveCategoryNote(String categoryId, LocalizedText? note);

  /// Dla panelu: wszystkie promocje, także wyłączone i poza terminem.
  Stream<List<AdminPromotion>> adminPromotions();
  String newPromotionId();
  Future<void> savePromotion(AdminPromotion promotion);
  Future<void> deletePromotion(String id);

  /// Zapisuje godziny tygodnia i dni specjalne. Reszta danych lokalu bez zmian.
  Future<void> saveHours(List<DayHours?> hours, List<SpecialDay> specialDays);
}

/// Prototyp bez serwera: dane z plików w `lib/data`, konto demo w pamięci.
class LocalBackend implements Backend {
  LocalBackend({StampCodeService? stampCodes}) : stampCodes = stampCodes ?? LocalStampCodeService();

  static const demoUid = 'demo';

  @override
  final StampCodeService stampCodes;

  final _session = _Value<Session?>(null);
  final _categories = _Value(bundled.categories);
  final _promos = _Value([
    for (final (i, p) in bundled.promotions.indexed) AdminPromotion(promotion: p, active: true, sortOrder: i * 10),
  ]);
  final _shop = _Value(bundled.shop);
  final _card = _Value(const StampCard(stamps: 7, rewardsRedeemed: 1));
  final _menu = _Value([
    for (final (i, item) in bundled.menuItems.indexed) AdminMenuItem(item: item, active: true, sortOrder: i * 10),
  ]);
  var _nextId = 0;

  @override
  bool get isRemote => false;

  @override
  Stream<List<MenuCategory>> categories() => _categories.stream;
  @override
  Stream<List<MenuItem>> menuItems() => _menu.stream.map(
    (items) => [
      for (final i in items)
        if (i.active) i.item,
    ],
  );
  @override
  Stream<List<Promotion>> promotions() => _promos.stream.map(
    (all) => [
      for (final p in all)
        if (p.visibleAt(DateTime.now())) p.promotion,
    ],
  );
  @override
  Stream<Shop> shop() => _shop.stream;

  @override
  Stream<Session?> session() => _session.stream;
  @override
  Stream<StampCard> stampCard(String uid) => _card.stream;

  static const _demoCustomerCode = 'icerolls:demo-customer';

  @override
  String customerCode(String uid) => _demoCustomerCode;

  @override
  String? customerUidFromCode(String raw) => raw.trim() == _demoCustomerCode ? demoUid : null;

  @override
  Stream<Customer?> customer(String uid) => uid != demoUid
      ? Stream.value(null)
      : _card.stream.map((card) => Customer(uid: uid, name: 'Klient demo', email: 'klient@example.com', card: card));

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

  @override
  Stream<List<AdminMenuItem>> adminMenuItems() => _menu.stream;

  @override
  String newMenuItemId() => 'nowa-${++_nextId}';

  @override
  Future<void> saveMenuItem(MenuItem item, {required bool active, required int sortOrder}) async {
    final entry = AdminMenuItem(item: item, active: active, sortOrder: sortOrder);
    final list = [
      for (final i in _menu.value)
        if (i.item.id != item.id) i,
      entry,
    ];
    _menu.value = list..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<void> setMenuItemActive(String id, bool active) async => _menu.value = [
    for (final i in _menu.value)
      i.item.id == id ? AdminMenuItem(item: i.item, active: active, sortOrder: i.sortOrder) : i,
  ];

  @override
  Future<void> deleteMenuItem(String id) async => _menu.value = [
    for (final i in _menu.value)
      if (i.item.id != id) i,
  ];

  @override
  Future<void> saveCategoryNote(String categoryId, LocalizedText? note) async => _categories.value = [
    for (final c in _categories.value)
      c.id != categoryId
          ? c
          : MenuCategory(
              id: c.id,
              name: c.name,
              color: c.color,
              note: note,
              image: c.image,
              imageAlignment: c.imageAlignment,
            ),
  ];

  @override
  Stream<List<AdminPromotion>> adminPromotions() => _promos.stream;

  @override
  String newPromotionId() => 'promo-${++_nextId}';

  @override
  Future<void> savePromotion(AdminPromotion promotion) async {
    final list = [
      for (final p in _promos.value)
        if (p.promotion.id != promotion.promotion.id) p,
      promotion,
    ];
    _promos.value = list..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<void> deletePromotion(String id) async => _promos.value = [
    for (final p in _promos.value)
      if (p.promotion.id != id) p,
  ];

  @override
  Future<void> saveHours(List<DayHours?> hours, List<SpecialDay> specialDays) async =>
      _shop.value = _shop.value.copyWith(hours: hours, specialDays: specialDays);
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
