import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ice_rolls/data/menu_data.dart';
import 'package:ice_rolls/data/models.dart';

void main() {
  MenuItem byId(String id) => menuItems.firstWhere((i) => i.id == id);

  test('cena lodów zależy od liczby składników', () {
    expect(byId('roll-marakuja').priceLabel, '20 zł');
    expect(byId('roll-marakuja+mieta').priceLabel, '23 zł');
    expect(byId('roll-marakuja+cytryna+mieta').priceLabel, '25 zł');
    expect(byId('roll-marakuja+cytryna+mieta').name.pl, 'Marakuja + cytryna + mięta');
  });

  test('rozmiary M/L i ceny z groszami', () {
    expect(byId('coffee-latte').priceLabel, '12 / 14 zł');
    expect(byId('coffee-latte').priceDetails(const Locale('pl')), ['M: 12 zł', 'L: 14 zł']);
    expect(byId('freak-bueno').priceLabel, '29,90 zł');
  });

  test('każda pozycja ma istniejącą kategorię i unikalne id', () {
    final ids = categories.map((c) => c.id).toSet();
    expect(menuItems.every((i) => ids.contains(i.categoryId)), isTrue);
    expect(menuItems.map((i) => i.id).toSet().length, menuItems.length);
  });
}
