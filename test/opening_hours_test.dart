import 'package:flutter_test/flutter_test.dart';
import 'package:ice_rolls/data/models.dart';
import 'package:ice_rolls/data/opening_hours.dart';
import 'package:ice_rolls/data/sample_data.dart';

void main() {
  // 2026-10-19 to poniedziałek.
  DateTime at(int day, int hour, [int minute = 0]) => DateTime(2026, 10, 19 + day, hour, minute);

  test('otwarte w ciągu dnia, zamknięcie o 21:30', () {
    final s = openStatus(shop.hours, at(0, 15)) as OpenNow;
    expect(formatTime(s.closesAt), '21:30');
  });

  test('przed otwarciem pokazuje dzisiejszą godzinę', () {
    final s = openStatus(shop.hours, at(2, 9)) as ClosedNow;
    expect(s.daysAhead, 0);
    expect(formatTime(s.opensAt), '11:00');
  });

  test('po zamknięciu w sobotę otwieramy w niedzielę o 10:00', () {
    final s = openStatus(shop.hours, at(5, 22, 5)) as ClosedNow;
    expect(s.daysAhead, 1);
    expect(formatTime(s.opensAt), '10:00');
  });

  test('dokładnie o zamknięciu jest już zamknięte', () {
    expect(openStatus(shop.hours, at(1, 21, 30)), isA<ClosedNow>());
  });

  test('dzień wolny przeskakuje do następnego otwartego', () {
    final hours = [...shop.hours]..[1] = null;
    final s = openStatus(hours, at(0, 23)) as ClosedNow;
    expect(s.daysAhead, 2);
  });

  group('karta pieczątek', () {
    test('nie przekracza 10 i daje nagrodę', () {
      final c = const StampCard(stamps: 8).addStamps(5);
      expect(c.stamps, 10);
      expect(c.rewardReady, isTrue);
    });

    test('wydanie nagrody zeruje kartę i liczy nagrody', () {
      final c = const StampCard(stamps: 10, rewardsRedeemed: 2).redeem();
      expect(c.stamps, 0);
      expect(c.rewardsRedeemed, 3);
    });

    test('bez pełnej karty nagrody nie da się wydać', () {
      const c = StampCard(stamps: 4);
      expect(c.redeem(), same(c));
    });
  });
}
