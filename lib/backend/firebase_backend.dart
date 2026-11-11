import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/menu_data.dart' as bundled;
import '../data/models.dart';
import '../data/shop_data.dart' as bundled;
import '../loyalty/stamp_claims.dart';
import 'backend.dart';
import 'codec.dart';

/// Dane z Firestore i konta z Firebase Auth, na darmowym planie Spark (bez Cloud Functions).
///
/// Bezpieczeństwo trzymają reguły w `firestore.rules`: pieczątki dopisuje tylko
/// konto z kolekcji `admins` (dokument o id równym e-mailowi, dodany w konsoli).
class FirebaseBackend implements Backend {
  FirebaseBackend({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Klient nie skanuje sam kodów: bez serwera nie da się ich bezpiecznie sprawdzić.
  @override
  StampCodeService? get stampCodes => null;

  @override
  bool get isRemote => true;

  /// Dokumenty kolekcji posortowane po `sortOrder`.
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _sorted(String collection) =>
      _db.collection(collection).snapshots().map((snap) {
        final docs = snap.docs.toList()..sort((a, b) => Codec.bySortOrder(a.data(), a.id, b.data(), b.id));
        return docs;
      });

  @override
  Stream<List<MenuCategory>> categories() =>
      _sorted('categories').map((docs) => [for (final d in docs) ?Codec.categoryFrom(d.id, d.data())]);

  @override
  Stream<List<MenuItem>> menuItems() =>
      _sorted('menuItems').map((docs) => [for (final d in docs) ?Codec.menuItemFrom(d.id, d.data())]);

  @override
  Stream<List<Promotion>> promotions() => _sorted('promotions').map((docs) {
    final now = DateTime.now();
    DateTime? time(Object? raw) => raw is Timestamp ? raw.toDate() : null;
    return [
      for (final d in docs)
        ?Codec.promotionFrom(
          d.id,
          d.data(),
          now: now,
          startsAt: time(d.data()['startsAt']),
          endsAt: time(d.data()['endsAt']),
        ),
    ];
  });

  @override
  Stream<Shop> shop() => _db
      .doc('shop/settings')
      .snapshots()
      .map((s) => s.exists ? Codec.shopFrom(s.data()!, bundled.shop) : bundled.shop);

  @override
  Stream<Session?> session() {
    late final StreamController<Session?> out;
    StreamSubscription<User?>? authSub;
    final docSubs = <StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>[];

    Future<void> cancelDocs() async {
      for (final sub in docSubs) {
        await sub.cancel();
      }
      docSubs.clear();
    }

    out = StreamController<Session?>(
      onListen: () {
        authSub = _auth.authStateChanges().listen((user) async {
          await cancelDocs();
          if (user == null) {
            out.add(null);
            return;
          }
          Map<String, dynamic>? profile;
          String? role;
          void emit() => out.add(
            Session(
              uid: user.uid,
              name: (profile?['displayName'] as String?) ?? user.displayName ?? user.email?.split('@').first ?? '',
              email: user.email,
              role: role,
              marketingConsent: profile?['marketingConsent'] == true,
            ),
          );
          emit();
          docSubs.add(
            _db.doc('users/${user.uid}').snapshots().listen((s) {
              profile = s.data();
              emit();
            }, onError: (Object _) {}),
          );
          // Rola z kolekcji admins. Reguły i tak sprawdzają ją przy każdym zapisie,
          // tu decyduje tylko o tym, czy pokazać panel sklepu.
          final email = user.email?.toLowerCase();
          if (email != null && user.emailVerified) {
            docSubs.add(
              _db.doc('admins/$email').snapshots().listen((s) {
                final r = s.data()?['role'];
                role = r == 'owner' || r == 'staff' ? r as String : null;
                emit();
              }, onError: (Object _) {}),
            );
          }
        }, onError: out.addError);
      },
      onCancel: () async {
        await authSub?.cancel();
        await cancelDocs();
      },
    );
    return out.stream;
  }

  @override
  Stream<StampCard> stampCard(String uid) =>
      _db.doc('users/$uid').snapshots().map((s) => Codec.stampCardFrom(s.data()));

  @override
  String customerCode(String uid) => 'IRU1.$uid';

  static final _customerCodePattern = RegExp(r'^IRU1\.([A-Za-z0-9]{1,128})$');

  @override
  String? customerUidFromCode(String raw) => _customerCodePattern.firstMatch(raw.trim())?.group(1);

  @override
  Stream<Customer?> customer(String uid) => _db.doc('users/$uid').snapshots().map((s) {
    final d = s.data();
    if (d == null) return null;
    return Customer(
      uid: uid,
      name: (d['displayName'] as String?) ?? '',
      email: d['email'] as String?,
      card: Codec.stampCardFrom(d),
    );
  });

  /// Tworzy profil przy pierwszym logowaniu.
  Future<void> _afterSignIn(User user, {String? name}) async {
    final ref = _db.doc('users/${user.uid}');
    try {
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'displayName': name ?? user.displayName ?? user.email?.split('@').first ?? '',
          'email': user.email,
          'marketingConsent': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Profil użytkownika: $e');
    }
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on FirebaseAuthException catch (e) {
      throw AuthException(switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' ||
        'invalid-login-credentials' => AuthError.invalidCredentials,
        'email-already-in-use' => AuthError.emailInUse,
        'weak-password' => AuthError.weakPassword,
        'invalid-email' => AuthError.invalidEmail,
        'popup-closed-by-user' || 'cancelled-popup-request' || 'web-context-canceled' => AuthError.cancelled,
        'network-request-failed' => AuthError.network,
        _ => AuthError.unknown,
      });
    }
  }

  @override
  Future<void> signInWithEmail(String email, String password) => _guard(() async {
    final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    await _afterSignIn(cred.user!);
  });

  @override
  Future<void> registerWithEmail({required String name, required String email, required String password}) =>
      _guard(() async {
        final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
        final user = cred.user!;
        await user.updateDisplayName(name.trim());
        await _afterSignIn(user, name: name.trim());
        try {
          await user.sendEmailVerification();
        } catch (_) {}
      });

  @override
  Future<void> sendPasswordReset(String email) => _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signInWithGoogle() => _guard(() async {
    final provider = GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'});
    final cred = kIsWeb ? await _auth.signInWithPopup(provider) : await _auth.signInWithProvider(provider);
    await _afterSignIn(cred.user!);
  });

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> setMarketingConsent(bool value) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.doc('users/$uid').update({'marketingConsent': value});
  }

  /// Zmiana karty klienta razem z wpisem do dziennika, w jednej transakcji.
  /// Reguły pozwalają na nią tylko adminowi i tylko w granicach karty.
  Future<void> _updateCard(String uid, String action, StampCard Function(StampCard card) change) async {
    final me = _auth.currentUser?.uid;
    final ref = _db.doc('users/$uid');
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Nie ma klienta $uid');
      final before = Codec.stampCardFrom(snap.data());
      final after = change(before);
      tx.update(ref, {
        'stamps': after.stamps,
        'rewardsRedeemed': after.rewardsRedeemed,
        'lastStampAt': FieldValue.serverTimestamp(),
      });
      tx.set(_db.collection('auditLog').doc(), {
        'uid': me,
        'action': action,
        'path': 'users/$uid',
        'stampsBefore': before.stamps,
        'stampsAfter': after.stamps,
        'at': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> addStamps(String uid, int count) => _updateCard(uid, 'addStamps', (c) => c.addStamps(count));

  @override
  Future<void> redeemReward(String uid) => _updateCard(uid, 'redeemReward', (c) {
    if (!c.rewardReady) throw StateError('Karta nie jest pełna');
    return c.redeem();
  });

  @override
  Future<int> uploadBundledData() async {
    final batch = _db.batch();
    var count = 0;
    void put(String path, Map<String, dynamic> data) {
      batch.set(_db.doc(path), data);
      count++;
    }

    for (final (i, c) in bundled.categories.indexed) {
      put('categories/${c.id}', Codec.category(c, i * 10));
    }
    for (final (i, item) in bundled.menuItems.indexed) {
      put('menuItems/${item.id}', Codec.menuItem(item, i * 10));
    }
    for (final (i, p) in bundled.promotions.indexed) {
      put('promotions/${p.id}', Codec.promotion(p, i * 10));
    }
    put('shop/settings', Codec.shop(bundled.shop));
    // Jedna partia zapisów mieści do 500 dokumentów, menu ma mniej.
    await batch.commit();
    await _db.collection('auditLog').add({
      'uid': _auth.currentUser?.uid,
      'action': 'uploadBundledData',
      'path': '/',
      'at': FieldValue.serverTimestamp(),
    });
    return count;
  }

  @override
  Stream<List<AdminMenuItem>> adminMenuItems() => _sorted('menuItems').map(
    (docs) => [
      for (final d in docs)
        AdminMenuItem(
          item: Codec.anyMenuItemFrom(d.id, d.data()),
          active: Codec.isActive(d.data()),
          sortOrder: Codec.sortOrderOf(d.data()),
        ),
    ],
  );

  @override
  String newMenuItemId() => _db.collection('menuItems').doc().id;

  /// Zapis do bazy razem z wpisem w historii zmian.
  Future<void> _withAudit(String action, String path, void Function(WriteBatch batch) write) async {
    final batch = _db.batch();
    write(batch);
    batch.set(_db.collection('auditLog').doc(), {
      'uid': _auth.currentUser?.uid,
      'action': action,
      'path': path,
      'at': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<void> saveMenuItem(MenuItem item, {required bool active, required int sortOrder}) => _withAudit(
    'saveMenuItem',
    'menuItems/${item.id}',
    (b) => b.set(_db.doc('menuItems/${item.id}'), Codec.menuItem(item, sortOrder, active: active)),
  );

  @override
  Future<void> setMenuItemActive(String id, bool active) => _withAudit(
    active ? 'showMenuItem' : 'hideMenuItem',
    'menuItems/$id',
    (b) => b.update(_db.doc('menuItems/$id'), {'active': active}),
  );

  @override
  Future<void> deleteMenuItem(String id) =>
      _withAudit('deleteMenuItem', 'menuItems/$id', (b) => b.delete(_db.doc('menuItems/$id')));

  @override
  Future<void> saveCategoryNote(String categoryId, LocalizedText? note) => _withAudit(
    'saveCategoryNote',
    'categories/$categoryId',
    (b) => b.update(_db.doc('categories/$categoryId'), {'note': note == null ? null : Codec.text(note)}),
  );

  @override
  Stream<List<AdminPromotion>> adminPromotions() => _sorted('promotions').map((docs) {
    DateTime? time(Object? raw) => raw is Timestamp ? raw.toDate() : null;
    return [
      for (final d in docs)
        AdminPromotion(
          promotion: Codec.anyPromotionFrom(d.id, d.data()),
          active: Codec.isActive(d.data()),
          sortOrder: Codec.sortOrderOf(d.data()),
          startsAt: time(d.data()['startsAt']),
          endsAt: time(d.data()['endsAt']),
        ),
    ];
  });

  @override
  String newPromotionId() => _db.collection('promotions').doc().id;

  @override
  Future<void> savePromotion(AdminPromotion p) => _withAudit(
    'savePromotion',
    'promotions/${p.promotion.id}',
    (b) => b.set(
      _db.doc('promotions/${p.promotion.id}'),
      Codec.promotion(p.promotion, p.sortOrder, active: p.active, startsAt: p.startsAt, endsAt: p.endsAt),
    ),
  );

  @override
  Future<void> deletePromotion(String id) =>
      _withAudit('deletePromotion', 'promotions/$id', (b) => b.delete(_db.doc('promotions/$id')));

  /// `mergeFields` podmienia całe pola godzin (także usunięte dni specjalne),
  /// a adresu i linków nie rusza.
  @override
  Future<void> saveHours(List<DayHours?> hours, List<SpecialDay> specialDays) => _withAudit(
    'saveHours',
    'shop/settings',
    (b) => b.set(_db.doc('shop/settings'), {
      'hours': Codec.weekHours(hours),
      'specialHours': Codec.specialHours(specialDays),
    }, SetOptions(mergeFields: ['hours', 'specialHours'])),
  );
}
