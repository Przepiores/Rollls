import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_rolls/backend/codec.dart';
import 'package:ice_rolls/data/menu_data.dart';
import 'package:ice_rolls/data/models.dart';
import 'package:ice_rolls/data/shop_data.dart';

void main() {
  test('całe menu przechodzi przez bazę bez zmian', () {
    for (final (i, c) in categories.indexed) {
      final back = Codec.categoryFrom(c.id, Codec.category(c, i))!;
      expect(back.name.pl, c.name.pl);
      expect(back.note?.en, c.note?.en);
      expect(back.color, c.color);
      expect(back.image, c.image);
      expect(back.imageAlignment, c.imageAlignment);
    }
    for (final (i, item) in menuItems.indexed) {
      final back = Codec.menuItemFrom(item.id, Codec.menuItem(item, i))!;
      expect(back.categoryId, item.categoryId);
      expect(back.name.en, item.name.en);
      expect(back.group?.pl, item.group?.pl);
      expect(back.description?.pl, item.description?.pl);
      expect(back.priceLabel, item.priceLabel);
      expect(back.priceDetails(const Locale('pl')), item.priceDetails(const Locale('pl')));
      expect(back.badges, item.badges);
      expect(back.image, item.image);
    }
  });

  test('godziny i dane lokalu', () {
    final back = Codec.shopFrom(Codec.shop(shop), shop);
    expect(back.street, shop.street);
    for (var d = 0; d < 7; d++) {
      expect(back.hours[d]?.open, shop.hours[d]?.open);
      expect(back.hours[d]?.close, shop.hours[d]?.close);
    }
    final closedMonday = Codec.shop(shop)..['hours'] = [null, ...(Codec.shop(shop)['hours'] as List).skip(1)];
    expect(Codec.shopFrom(closedMonday, shop).hours.first, isNull);
    expect(Codec.shopFrom({}, shop).name, shop.name);
  });

  test('wyłączone pozycje i promocje poza terminem znikają', () {
    final item = Codec.menuItem(menuItems.first, 0)..['active'] = false;
    expect(Codec.menuItemFrom('x', item), isNull);

    final promo = Codec.promotion(promotions.first, 0);
    final now = DateTime(2026, 11, 10);
    expect(Codec.promotionFrom('p', promo, now: now), isNotNull);
    expect(Codec.promotionFrom('p', promo, now: now, startsAt: DateTime(2026, 12)), isNull);
    expect(Codec.promotionFrom('p', promo, now: now, endsAt: DateTime(2026, 11, 1)), isNull);
  });

  test('brak tłumaczenia pokazuje tekst po polsku', () {
    expect(Codec.textOrNull({'pl': 'gofr', 'en': ''})!.en, 'gofr');
    expect(Codec.textOrNull('gofr'), isNull);
  });

  test('pieczątki z dokumentu użytkownika', () {
    expect(Codec.stampCardFrom(null).stamps, 0);
    expect(Codec.stampCardFrom({'stamps': 14, 'rewardsRedeemed': 2}).stamps, StampCard.goal);
  });
}
