import 'package:flutter_test/flutter_test.dart';
import 'package:ice_rolls/loyalty/stamp_claims.dart';
import 'package:ice_rolls/loyalty/stamp_code.dart';

void main() {
  late DateTime now;
  late LocalStampCodeService service;

  setUp(() {
    now = DateTime(2026, 10, 28, 15);
    service = LocalStampCodeService(clock: () => now);
  });

  Future<String> issue({int stamps = 1}) => service.issue(stamps: stamps, validFor: const Duration(minutes: 2));
  Future<ClaimResult> claim(String code, {String user = 'ala', int missing = 10}) =>
      service.claim(code, userId: user, stampsMissing: missing);

  test('poprawny kod dodaje pieczątki', () async {
    final result = await claim(await issue(stamps: 2));
    expect(result.status, ClaimStatus.added);
    expect(result.stamps, 2);
    expect(result.scansLeftToday, 1);
  });

  test('kod działa tylko raz, także dla innego konta', () async {
    final code = await issue();
    await claim(code);
    expect((await claim(code)).status, ClaimStatus.alreadyUsed);
    expect((await claim(code, user: 'ola')).status, ClaimStatus.alreadyUsed);
  });

  test('limit 2 skanów dziennie na konto, od północy od nowa', () async {
    await claim(await issue());
    await claim(await issue());
    final third = await issue();
    expect((await claim(third)).status, ClaimStatus.dailyLimit);
    expect((await claim(await issue(), user: 'ola')).status, ClaimStatus.added);

    now = DateTime(2026, 10, 29, 0, 1);
    expect(await service.scansLeftToday('ala'), 2);
    // Kod odrzucony przez limit się nie zużył, ale po 2 minutach już wygasł.
    expect((await claim(third)).status, ClaimStatus.expired);
    expect((await claim(await issue())).status, ClaimStatus.added);
  });

  test('wygasły kod jest odrzucany', () async {
    final code = await issue();
    now = now.add(const Duration(minutes: 2));
    expect((await claim(code)).status, ClaimStatus.expired);
  });

  test('zmieniony lub obcy kod jest odrzucany', () async {
    final code = await issue();
    final parts = code.split('.');
    parts[2] = '5';
    expect((await claim(parts.join('.'))).status, ClaimStatus.invalid);
    expect((await claim('https://example.com')).status, ClaimStatus.invalid);

    final otherShop = LocalStampCodeService(key: [1, 2, 3], clock: () => now);
    final foreign = await otherShop.issue(stamps: 1, validFor: const Duration(minutes: 2));
    expect((await claim(foreign)).status, ClaimStatus.invalid);
    expect(await service.scansLeftToday('ala'), 2);
  });

  test('pełna karta nie zużywa kodu ani skanu', () async {
    final code = await issue(stamps: 3);
    expect((await claim(code, missing: 0)).status, ClaimStatus.cardFull);
    expect(await service.scansLeftToday('ala'), 2);
    final result = await claim(code, missing: 1);
    expect(result.status, ClaimStatus.added);
    expect(result.stamps, 1);
  });

  test('kod mieści się w limicie pieczątek', () {
    final code = StampCode.issue(stamps: StampCode.maxStamps + 1, expiresAt: now).sign([1]);
    expect(StampCode.verify(code, [1]), isNull);
  });

  test('naklejka jest wielorazowa, ale liczy się do limitu 2 dziennie', () async {
    final sticker = await service.issueSticker(id: 'lada-1', validUntil: DateTime(2028));
    expect((await claim(sticker)).stamps, 1);
    expect((await claim(sticker)).status, ClaimStatus.added);
    expect((await claim(sticker)).status, ClaimStatus.dailyLimit);
    expect((await claim(sticker, user: 'ola')).status, ClaimStatus.added);
    now = DateTime(2026, 10, 29, 12);
    expect((await claim(sticker)).status, ClaimStatus.added);
  });

  test('naklejki nie da się przerobić na kod z więcej pieczątkami ani jednorazowy', () async {
    final sticker = await service.issueSticker(id: 'lada-1', validUntil: DateTime(2028));
    final parts = sticker.split('.');
    expect((await claim([...parts.take(2), '3', ...parts.skip(3)].join('.'))).status, ClaimStatus.invalid);
    expect((await claim(['IR1', ...parts.skip(1)].join('.'))).status, ClaimStatus.invalid);
  });
}
