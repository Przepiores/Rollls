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
  const MenuCategory({required this.id, required this.name, required this.color});
  final String id;
  final LocalizedText name;
  final Color color;
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.priceGrosze,
    this.image,
    this.badges = const {},
  });
  final String id;
  final String categoryId;
  final LocalizedText name;
  final LocalizedText description;
  final int priceGrosze;
  final String? image;
  final Set<MenuBadge> badges;

  String get priceLabel {
    final zl = priceGrosze ~/ 100;
    final gr = priceGrosze % 100;
    return gr == 0 ? '$zl zł' : '$zl,${gr.toString().padLeft(2, '0')} zł';
  }
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
