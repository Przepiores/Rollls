import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/menu_data.dart' as bundled;
import '../data/models.dart';
import '../data/shop_data.dart' as bundled;
import '../loyalty/stamp_claims.dart';
import 'backend.dart';
import 'codec.dart';
import 'firebase_config.dart';

/// Dane z Firestore, konta z Firebase Auth, pieczątki przez Cloud Functions.
class FirebaseBackend implements Backend {
  FirebaseBackend({FirebaseFirestore? db, FirebaseAuth? auth, FirebaseFunctions? functions})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance,
      _functions = functions ?? FirebaseFunctions.instanceFor(region: FirebaseConfig.functionsRegion) {
    stampCodes = FunctionsStampCodeService(_functions);
  }

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  @override
  late final StampCodeService stampCodes;

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
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? docSub;
    var generation = 0;

    out = StreamController<Session?>(
      onListen: () {
        // idTokenChanges, a nie authStateChanges: rola przychodzi w tokenie
        // i zmienia się po odświeżeniu tokenu, bez ponownego logowania.
        authSub = _auth.idTokenChanges().listen((user) async {
          final gen = ++generation;
          await docSub?.cancel();
          docSub = null;
          if (user == null) {
            out.add(null);
            return;
          }
          String? role;
          try {
            final claim = (await user.getIdTokenResult()).claims?['role'];
            role = claim is String ? claim : null;
          } catch (_) {
            // Bez sieci zostaje rola z poprzedniego tokenu albo brak roli.
          }
          if (gen != generation) return;
          Session build(Map<String, dynamic>? d) => Session(
            uid: user.uid,
            name: (d?['displayName'] as String?) ?? user.displayName ?? user.email?.split('@').first ?? '',
            email: user.email,
            role: role,
            marketingConsent: d?['marketingConsent'] == true,
          );
          out.add(build(null));
          docSub = _db
              .doc('users/${user.uid}')
              .snapshots()
              .listen((s) => out.add(build(s.data())), onError: (Object _) {});
        }, onError: out.addError);
      },
      onCancel: () async {
        await authSub?.cancel();
        await docSub?.cancel();
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

  /// uid z kodu `IRU1.<uid>`. Ten sam wzorzec sprawdza funkcja serwera (uidArg).
  static String? uidFromCustomerCode(String raw) => _customerCodePattern.firstMatch(raw.trim())?.group(1);

  @override
  String? customerUidFromCode(String raw) => uidFromCustomerCode(raw);

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

  @override
  Stream<List<StickerInfo>> stickers() => _db.collection('stickers').snapshots().map((snap) {
    DateTime? time(Object? raw) => raw is Timestamp ? raw.toDate() : null;
    final list = [
      for (final d in snap.docs)
        if (time(d.data()['validUntil']) case final validUntil?)
          StickerInfo(
            id: d.id,
            validUntil: validUntil,
            revoked: d.data()['revoked'] == true,
            createdAt: time(d.data()['createdAt']),
          ),
    ];
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return list..sort((a, b) => (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch));
  });

  @override
  Future<void> createSticker(String id, DateTime validUntil) async {
    // Funkcja zakłada dokument naklejki i zapisuje wpis w historii zmian.
    await stampCodes.issueSticker(id: id, validUntil: validUntil);
  }

  @override
  Future<void> revokeSticker(String id) async {
    final uid = _auth.currentUser?.uid;
    final batch = _db.batch()..update(_db.doc('stickers/$id'), {'revoked': true});
    if (uid != null) {
      batch.set(_db.collection('auditLog').doc(), {
        'uid': uid,
        'action': 'revokeSticker',
        'path': 'stickers/$id',
        'at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Tworzy profil przy pierwszym logowaniu i sprawdza, czy to konto właściciela.
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
    try {
      // Nadaje rolę owner, jeśli e-mail jest na liście właścicieli w Cloud Functions.
      final res = await _functions.httpsCallable('claimOwner').call<Map<String, dynamic>>();
      if (res.data['role'] != null) await user.getIdToken(true);
    } catch (e) {
      debugPrint('claimOwner: $e');
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

  @override
  Future<void> addStamps(String uid, int count) =>
      _functions.httpsCallable('addStamps').call<void>({'uid': uid, 'count': count});

  @override
  Future<void> redeemReward(String uid) => _functions.httpsCallable('redeemReward').call<void>({'uid': uid});

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
}

/// Kody na pieczątki podpisuje i sprawdza serwer (Cloud Functions).
/// Klucz sklepu, zużyte kody i liczniki skanów nigdy nie trafiają do aplikacji.
class FunctionsStampCodeService implements StampCodeService {
  FunctionsStampCodeService(this._functions);
  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> _call(String name, [Map<String, dynamic>? data]) async {
    final res = await _functions.httpsCallable(name).call<Map<String, dynamic>>(data);
    return Map<String, dynamic>.from(res.data);
  }

  @override
  Future<String> issue({required int stamps, required Duration validFor}) async =>
      (await _call('issueStampCode', {'stamps': stamps, 'validForSeconds': validFor.inSeconds}))['code'] as String;

  @override
  Future<String> issueSticker({required String id, required DateTime validUntil}) async =>
      (await _call('issueSticker', {'id': id, 'validUntil': validUntil.toUtc().toIso8601String()}))['code'] as String;

  @override
  Future<int> scansLeftToday(String userId) async => ((await _call('scansLeftToday'))['scansLeftToday'] as num).toInt();

  @override
  Future<ClaimResult> claim(String raw, {required String userId, required int stampsMissing}) async {
    final d = await _call('claimStampCode', {'code': raw});
    final status = ClaimStatus.values.asNameMap()[d['status']] ?? ClaimStatus.invalid;
    return ClaimResult(
      status,
      stamps: (d['stamps'] as num? ?? 0).toInt(),
      scansLeftToday: (d['scansLeftToday'] as num? ?? 0).toInt(),
    );
  }
}
