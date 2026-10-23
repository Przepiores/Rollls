import 'package:flutter/material.dart';

import '../theme.dart';
import 'models.dart';

// Dane lokalu z publicznych wizytówek. Menu i promocje są przykładowe,
// prawdziwe dane wprowadzi właściciel w panelu sklepu.

const shop = Shop(
  name: 'Ice Rolls',
  street: 'Kuźnicza 10',
  city: '50-138 Wrocław',
  mapsQuery: 'Ice Rolls, Kuźnicza 10, 50-138 Wrocław',
  instagram: 'https://www.instagram.com/icerollspl/',
  facebook: 'https://www.facebook.com/icerollspl/',
  hours: [
    DayHours(TimeOfDay(hour: 11, minute: 0), TimeOfDay(hour: 21, minute: 30)),
    DayHours(TimeOfDay(hour: 11, minute: 0), TimeOfDay(hour: 21, minute: 30)),
    DayHours(TimeOfDay(hour: 11, minute: 0), TimeOfDay(hour: 21, minute: 30)),
    DayHours(TimeOfDay(hour: 11, minute: 0), TimeOfDay(hour: 21, minute: 30)),
    DayHours(TimeOfDay(hour: 11, minute: 0), TimeOfDay(hour: 21, minute: 30)),
    DayHours(TimeOfDay(hour: 11, minute: 0), TimeOfDay(hour: 22, minute: 0)),
    DayHours(TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 21, minute: 30)),
  ],
);

const categories = [
  MenuCategory(id: 'rolls', name: LocalizedText('Lody rolowane', 'Ice cream rolls'), color: RollColors.pink),
  MenuCategory(id: 'bubble', name: LocalizedText('Gofry bąbelkowe', 'Bubble waffles'), color: RollColors.yellow),
  MenuCategory(id: 'belgian', name: LocalizedText('Gofry belgijskie', 'Belgian waffles'), color: RollColors.purple),
  MenuCategory(id: 'drinks', name: LocalizedText('Shake i napoje', 'Shakes and drinks'), color: RollColors.sky),
];

const menuItems = [
  MenuItem(
    id: 'r1',
    categoryId: 'rolls',
    name: LocalizedText('Truskawkowa chmurka', 'Strawberry cloud'),
    description: LocalizedText(
      'Rolki z truskawek i śmietanki, świeże owoce, bita śmietana, pianki.',
      'Strawberry and cream rolls, fresh fruit, whipped cream, marshmallows.',
    ),
    priceGrosze: 2200,
    badges: {MenuBadge.bestseller},
  ),
  MenuItem(
    id: 'r2',
    categoryId: 'rolls',
    name: LocalizedText('Oreo Crunch', 'Oreo Crunch'),
    description: LocalizedText(
      'Rolki z ciasteczkami Oreo, sos czekoladowy, kruszonka.',
      'Oreo cookie rolls, chocolate sauce, crumble.',
    ),
    priceGrosze: 2300,
  ),
  MenuItem(
    id: 'r3',
    categoryId: 'rolls',
    name: LocalizedText('Mango Tango', 'Mango Tango'),
    description: LocalizedText(
      'Rolki z mango i marakui, kokos, świeże mango.',
      'Mango and passion fruit rolls, coconut, fresh mango.',
    ),
    priceGrosze: 2300,
    badges: {MenuBadge.isNew},
  ),
  MenuItem(
    id: 'r4',
    categoryId: 'rolls',
    name: LocalizedText('Pistacjowy sen', 'Pistachio dream'),
    description: LocalizedText(
      'Rolki pistacjowe, krem pistacjowy, posiekane orzechy.',
      'Pistachio rolls, pistachio cream, chopped nuts.',
    ),
    priceGrosze: 2500,
  ),
  MenuItem(
    id: 'b1',
    categoryId: 'bubble',
    name: LocalizedText('Tęczowy gofr', 'Rainbow waffle'),
    description: LocalizedText(
      'Gofr bąbelkowy, bita śmietana, truskawki, borówki, pianki, posypka i wata cukrowa.',
      'Bubble waffle, whipped cream, strawberries, blueberries, marshmallows, sprinkles and cotton candy.',
    ),
    priceGrosze: 2600,
    image: 'assets/images/gofr_babelkowy.jpg',
    badges: {MenuBadge.bestseller},
  ),
  MenuItem(
    id: 'b2',
    categoryId: 'bubble',
    name: LocalizedText('Czekoladowa bomba', 'Chocolate bomb'),
    description: LocalizedText(
      'Gofr bąbelkowy, lody czekoladowe, sos czekoladowy, brownie.',
      'Bubble waffle, chocolate ice cream, chocolate sauce, brownie.',
    ),
    priceGrosze: 2500,
  ),
  MenuItem(
    id: 'w1',
    categoryId: 'belgian',
    name: LocalizedText('Wiśniowy', 'Cherry'),
    description: LocalizedText(
      'Gofr belgijski, bita śmietana, wiśnie w sosie, wiórki czekolady.',
      'Belgian waffle, whipped cream, cherries in sauce, chocolate shavings.',
    ),
    priceGrosze: 1900,
    image: 'assets/images/gofr_wisniowy.jpg',
  ),
  MenuItem(
    id: 'w2',
    categoryId: 'belgian',
    name: LocalizedText('Klasyczny z cukrem pudrem', 'Classic with powdered sugar'),
    description: LocalizedText(
      'Chrupiący gofr belgijski z cukrem pudrem.',
      'Crispy Belgian waffle with powdered sugar.',
    ),
    priceGrosze: 1200,
  ),
  MenuItem(
    id: 'd1',
    categoryId: 'drinks',
    name: LocalizedText('Shake jednorożec', 'Unicorn shake'),
    description: LocalizedText(
      'Waniliowy shake z kolorową posypką i bitą śmietaną.',
      'Vanilla shake with rainbow sprinkles and whipped cream.',
    ),
    priceGrosze: 1800,
    badges: {MenuBadge.isNew},
  ),
];

const promotions = [
  Promotion(
    id: 'p1',
    title: LocalizedText('Happy hours 11–13', 'Happy hours 11–1 pm'),
    body: LocalizedText(
      'Druga porcja lodów rolowanych -50% w dni robocze.',
      'Second ice cream roll half price on weekdays.',
    ),
    color: RollColors.lime,
  ),
  Promotion(
    id: 'p2',
    title: LocalizedText('Nowość: Mango Tango', 'New: Mango Tango'),
    body: LocalizedText(
      'Tropikalne rolki z mango i marakui. Spróbuj, zanim znikną!',
      'Tropical mango and passion fruit rolls. Try them before they are gone!',
    ),
    color: RollColors.yellow,
  ),
  Promotion(
    id: 'p3',
    title: LocalizedText('Podwójne pieczątki w środy', 'Double stamps on Wednesdays'),
    body: LocalizedText(
      'W każdą środę za każdy deser dostajesz dwie pieczątki.',
      'Every Wednesday each dessert earns two stamps.',
    ),
    color: RollColors.pink,
  ),
];
