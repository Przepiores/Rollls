import 'package:flutter/material.dart';

/// Tekst w dwóch językach. Panel sklepu będzie zapisywał oba warianty.
class LocalizedText {
  const LocalizedText(this.pl, this.en);
  final String pl;
  final String en;

  String of(Locale locale) => locale.languageCode == 'en' ? en : pl;
}

enum MenuBadge { isNew, bestseller }

class MenuCategory {
  const MenuCategory({required this.id, required this.name, required this.color, this.note});
  final String id;
  final LocalizedText name;
  final Color color;

  /// Ceny i zasady całej kategorii, pokazywane nad listą.
  final LocalizedText? note;
}

/// Jedna cena pozycji, np. rozmiar L albo gofr z bitą śmietaną i lodami.
class Price {
  const Price(this.grosze, [this.label]);
  final int grosze;
  final LocalizedText? label;
}

String formatPln(int grosze) {
  final zl = grosze ~/ 100;
  final gr = grosze % 100;
  return gr == 0 ? '$zl zł' : '$zl,${gr.toString().padLeft(2, '0')} zł';
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.prices,
    this.description,
    this.group,
    this.image,
    this.badges = const {},
  });
  final String id;
  final String categoryId;
  final LocalizedText name;
  final List<Price> prices;
  final LocalizedText? description;

  /// Grupa na liście kategorii, np. smaki lodów z oreo. Pozycje z grupą
  /// pokazujemy jako zwarte wiersze zamiast kafelków.
  final LocalizedText? group;
  final String? image;
  final Set<MenuBadge> badges;

  /// Krótka cena do kafelka, np. „12 / 14 zł”.
  String get priceLabel {
    final all = prices.map((p) => formatPln(p.grosze)).toList();
    if (all.length == 1) return all.single;
    return '${all.map((s) => s.replaceAll(' zł', '')).join(' / ')} zł';
  }

  /// Ceny z opisem wariantu, np. „L: 14 zł”.
  List<String> priceDetails(Locale locale) => [
    for (final p in prices)
      if (p.label != null) '${p.label!.of(locale)}: ${formatPln(p.grosze)}',
  ];
}

class Promotion {
  const Promotion({required this.id, required this.title, required this.body, required this.color, this.image});
  final String id;
  final LocalizedText title;
  final LocalizedText body;
  final Color color;
  final String? image;
}

class Shop {
  const Shop({
    required this.name,
    required this.street,
    required this.city,
    required this.mapsQuery,
    required this.instagram,
    required this.facebook,
    required this.hours,
  });
  final String name;
  final String street;
  final String city;
  final String mapsQuery;
  final String instagram;
  final String facebook;

  /// Godziny otwarcia, indeks 0 = poniedziałek.
  final List<DayHours?> hours;
}

class DayHours {
  const DayHours(this.open, this.close);
  final TimeOfDay open;
  final TimeOfDay close;
}

/// Karta pieczątek klienta. W wersji z Firebase pieczątki dodaje tylko serwer.
class StampCard {
  const StampCard({this.stamps = 0, this.rewardsRedeemed = 0});
  static const int goal = 10;

  final int stamps;
  final int rewardsRedeemed;

  bool get rewardReady => stamps >= goal;
  int get remaining => (goal - stamps).clamp(0, goal);

  StampCard addStamps(int count) =>
      StampCard(stamps: (stamps + count).clamp(0, goal), rewardsRedeemed: rewardsRedeemed);

  StampCard redeem() => rewardReady ? StampCard(stamps: 0, rewardsRedeemed: rewardsRedeemed + 1) : this;
}
