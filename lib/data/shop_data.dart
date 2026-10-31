import 'package:flutter/material.dart';

import '../theme.dart';
import 'models.dart';

// Dane lokalu z publicznych wizytówek. Promocje biorą się z menu lokalu,
// w wersji z Firebase właściciel ustawi je w panelu sklepu.

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

const promotions = [
  Promotion(
    id: 'p-autumn',
    title: LocalizedText('Jesienne smaki', 'Autumn flavours'),
    body: LocalizedText(
      'Wiśnia w żelu, pistacja z truskawkami i jabłko z cynamonem na gofrze belgijskim. 28 zł.',
      'Cherries in jelly, pistachio with strawberries and apple with cinnamon on a Belgian waffle. 28 zł.',
    ),
    color: RollColors.yellow,
    image: 'assets/images/gofr_wisniowy.jpg',
  ),
  Promotion(
    id: 'p-students',
    title: LocalizedText('Cena dla studentów', 'Student price'),
    body: LocalizedText(
      'Lody tajskie z 2 składnikami za 21 zł, z 3 składnikami za 23 zł.',
      'Ice cream rolls with 2 ingredients for 21 zł, with 3 ingredients for 23 zł.',
    ),
    color: RollColors.lime,
    image: 'assets/images/lody_tajskie.jpg',
  ),
  Promotion(
    id: 'p-choco',
    title: LocalizedText('Choco set', 'Choco set'),
    body: LocalizedText(
      'Trzy małe czekolady na gorąco do spróbowania. Zapytaj o niego przy stoliku.',
      'Three small hot chocolates to taste. Ask for it at your table.',
    ),
    color: RollColors.pink,
    image: 'assets/images/gofry_belgijskie_kawa.jpg',
  ),
];
