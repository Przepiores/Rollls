import 'dart:convert';

import 'stamp_code.dart';

/// Wynik skanu kodu z paragonu albo z lady.
enum ClaimStatus { added, invalid, expired, alreadyUsed, dailyLimit, cardFull }

class ClaimResult {
  const ClaimResult(this.status, {this.stamps = 0, this.scansLeftToday = 0});
  final ClaimStatus status;

  /// Ile pieczątek dodano. Większe od zera tylko przy [ClaimStatus.added].
  final int stamps;
  final int scansLeftToday;
}

/// Wydawanie i realizacja kodów na pieczątki.
///
/// Prototyp używa [LocalStampCodeService]. W wersji z Firebase ten sam
/// interfejs będą miały wywołania Cloud Functions `issueStampCode`
/// i `claimStampCode`: klucz sklepu, zużyte kody i licznik skanów
/// będą tylko na serwerze, a aplikacja wyśle sam tekst z kodu QR.
abstract interface class StampCodeService {
  static const dailyScanLimit = 2;

  /// Dla obsługi: nowy jednorazowy kod do pokazania lub wydruku.
  Future<String> issue({required int stamps, required Duration validFor});

  /// Dla właściciela: wielorazowy kod do wydrukowania na naklejkę przy ladzie.
  /// Daje 1 pieczątkę za skan, a chroni go tylko dzienny limit skanów.
  /// Nową naklejkę (inny [id]) drukuje się, gdy stara wycieknie lub wygaśnie.
  Future<String> issueSticker({required String id, required DateTime validUntil});

  /// Dla klienta: sprawdza kod i nalicza pieczątki na konto [userId].
  Future<ClaimResult> claim(String raw, {required String userId, required int stampsMissing});

  Future<int> scansLeftToday(String userId);
}

class LocalStampCodeService implements StampCodeService {
  LocalStampCodeService({List<int>? key, DateTime Function()? clock})
    : _key = key ?? utf8.encode('ice-rolls-prototyp-tylko-demo'),
      _clock = clock ?? DateTime.now;

  final List<int> _key;
  final DateTime Function() _clock;
  final _usedNonces = <String>{};
  final _scansByDay = <String, int>{};

  /// Dzień liczony w czasie lokalnym, więc limit odnawia się o północy.
  /// Na serwerze to będzie północ w strefie Europe/Warsaw.
  String _dayKey(String userId) {
    final now = _clock().toLocal();
    return '$userId/${now.year}-${now.month}-${now.day}';
  }

  int _scansToday(String userId) => _scansByDay[_dayKey(userId)] ?? 0;

  @override
  Future<String> issue({required int stamps, required Duration validFor}) async =>
      StampCode.issue(stamps: stamps, expiresAt: _clock().add(validFor)).sign(_key);

  @override
  Future<String> issueSticker({required String id, required DateTime validUntil}) async =>
      StampCode(nonce: id, stamps: 1, expiresAt: validUntil, sticker: true).sign(_key);

  @override
  Future<int> scansLeftToday(String userId) async => StampCodeService.dailyScanLimit - _scansToday(userId);

  @override
  Future<ClaimResult> claim(String raw, {required String userId, required int stampsMissing}) async {
    final used = _scansToday(userId);
    ClaimResult result(ClaimStatus status, {int stamps = 0}) => ClaimResult(
      status,
      stamps: stamps,
      scansLeftToday: StampCodeService.dailyScanLimit - used - (stamps > 0 ? 1 : 0),
    );

    final code = StampCode.verify(raw, _key);
    if (code == null) return result(ClaimStatus.invalid);
    if (!_clock().isBefore(code.expiresAt)) return result(ClaimStatus.expired);
    if (!code.sticker && _usedNonces.contains(code.nonce)) return result(ClaimStatus.alreadyUsed);
    if (used >= StampCodeService.dailyScanLimit) return result(ClaimStatus.dailyLimit);
    // Pełna karta: kod zostaje ważny, żeby klient mógł go użyć po odebraniu nagrody.
    if (stampsMissing <= 0) return result(ClaimStatus.cardFull);

    if (!code.sticker) _usedNonces.add(code.nonce);
    _scansByDay[_dayKey(userId)] = used + 1;
    return result(ClaimStatus.added, stamps: code.stamps.clamp(1, stampsMissing));
  }
}
