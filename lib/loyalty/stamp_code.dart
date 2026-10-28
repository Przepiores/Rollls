import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Kod QR, za który klient dostaje pieczątki.
///
/// Format: `IR1.<nonce>.<pieczątki>.<ważny do, sekundy unix>.<podpis>`.
/// Podpis to HMAC-SHA256 z pierwszych czterech pól, liczony kluczem sklepu.
/// Bez klucza nie da się zmienić liczby pieczątek ani daty ważności,
/// a nonce pozwala oznaczyć kod jako zużyty.
///
/// Naklejka na ladzie ma prefiks `IR1S`: jest wielorazowa, a jej nonce
/// to stały identyfikator naklejki, który da się unieważnić.
class StampCode {
  const StampCode({required this.nonce, required this.stamps, required this.expiresAt, this.sticker = false});

  static const prefix = 'IR1';
  static const stickerPrefix = 'IR1S';
  static const maxStamps = 5;

  final String nonce;
  final int stamps;
  final DateTime expiresAt;
  final bool sticker;

  String get _payload =>
      '${sticker ? stickerPrefix : prefix}.$nonce.$stamps.${expiresAt.millisecondsSinceEpoch ~/ 1000}';

  /// Gotowy tekst do zakodowania w QR.
  String sign(List<int> key) => '$_payload.${_signature(key, _payload)}';

  static StampCode issue({required int stamps, required DateTime expiresAt, Random? random}) {
    final rnd = random ?? Random.secure();
    final nonce = base64Url.encode(List.generate(9, (_) => rnd.nextInt(256)));
    return StampCode(nonce: nonce, stamps: stamps, expiresAt: expiresAt);
  }

  /// Sprawdza format i podpis. Zwraca null dla obcego albo podrobionego kodu.
  static StampCode? verify(String raw, List<int> key) {
    final parts = raw.trim().split('.');
    if (parts.length != 5 || (parts[0] != prefix && parts[0] != stickerPrefix)) return null;
    final stamps = int.tryParse(parts[2]);
    final exp = int.tryParse(parts[3]);
    if (stamps == null || stamps < 1 || stamps > maxStamps || exp == null) return null;
    final payload = parts.take(4).join('.');
    if (!_equal(_signature(key, payload), parts[4])) return null;
    return StampCode(
      nonce: parts[1],
      stamps: stamps,
      sticker: parts[0] == stickerPrefix,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true),
    );
  }

  static String _signature(List<int> key, String payload) {
    final mac = Hmac(sha256, key).convert(utf8.encode(payload)).bytes;
    // 16 bajtów wystarczy, a kod QR zostaje mały i łatwy do zeskanowania.
    return base64Url.encode(mac.sublist(0, 16)).replaceAll('=', '');
  }

  /// Porównanie w stałym czasie, żeby nie zdradzać podpisu po czasie odpowiedzi.
  static bool _equal(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
