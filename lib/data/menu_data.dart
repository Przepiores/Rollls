import 'package:flutter/painting.dart';

import '../theme.dart';
import 'models.dart';

// Menu Ice Rolls przepisane z kart menu lokalu (październik 2026).
// W wersji z Firebase te dane będą w bazie i właściciel zmieni je w panelu sklepu.

typedef L = LocalizedText;

const categories = [
  MenuCategory(
    id: 'rolls',
    image: 'assets/images/lody_tajskie.jpg',
    name: L('Lody tajskie', 'Ice cream rolls'),
    color: RollColors.pink,
    note: L(
      '1\u00a0składnik\u00a020\u00a0zł, 2\u00a0składniki\u00a023\u00a0zł, 3\u00a0składniki\u00a025\u00a0zł\n'
          'Studenci: 2\u00a0składniki\u00a021\u00a0zł, 3\u00a0składniki\u00a023\u00a0zł\n'
          'Składniki można łączyć dowolnie, poniżej polecane smaki. Lody są na bazie śmietany, '
          'jest też opcja vege. Dodatki po 4 zł: bita śmietana, polewa, posypka.',
      '1\u00a0ingredient\u00a020\u00a0zł, 2\u00a0ingredients\u00a023\u00a0zł, 3\u00a0ingredients\u00a025\u00a0zł\n'
          'Students: 2\u00a0ingredients\u00a021\u00a0zł, 3\u00a0ingredients\u00a023\u00a0zł\n'
          'Mix any ingredients you like, below are our favourite combos. Made with cream, '
          'vegan option available. Extras 4 zł each: whipped cream, sauce, sprinkles.',
    ),
  ),
  MenuCategory(
    id: 'freak',
    image: 'assets/images/gofr_babelkowy.jpg',
    name: L('Freak Shake', 'Freak Shake'),
    color: RollColors.purple,
    note: L('Każdy Freak Shake 29,90 zł.', 'Every Freak Shake is 29.90 zł.'),
  ),
  MenuCategory(
    id: 'classic',
    image: 'assets/images/gofry_belgijskie_kawa.jpg',
    imageAlignment: Alignment(0.6, -0.15),
    name: L('Classic Shake', 'Classic Shake'),
    color: RollColors.sky,
    note: L(
      'Każdy Classic Shake 22,90 zł. Bita śmietana +4 zł.',
      'Every Classic Shake is 22.90 zł. Whipped cream +4 zł.',
    ),
  ),
  MenuCategory(
    id: 'bubble',
    image: 'assets/images/gofry_babelkowe.jpg',
    imageAlignment: Alignment(0, -0.45),
    name: L('Gofry bąbelkowe', 'Bubble waffles'),
    color: RollColors.yellow,
    note: L(
      '27 zł z bitą śmietaną lub z lodami · 30 zł z bitą śmietaną i z lodami',
      '27 zł with whipped cream or ice cream · 30 zł with whipped cream and ice cream',
    ),
  ),
  MenuCategory(
    id: 'belgian',
    image: 'assets/images/gofry_belgijskie_kawa.jpg',
    imageAlignment: Alignment(0, 0.55),
    name: L('Gofry belgijskie', 'Belgian waffles'),
    color: RollColors.lime,
    note: L('Każdy gofr belgijski 28 zł.', 'Every Belgian waffle is 28 zł.'),
  ),
  MenuCategory(
    id: 'autumn',
    image: 'assets/images/gofr_wisniowy.jpg',
    name: L('Jesienne smaki', 'Autumn flavours'),
    color: RollColors.red,
    note: L('Jesienne gofry belgijskie, każdy 28 zł.', 'Autumn Belgian waffles, 28 zł each.'),
  ),
  MenuCategory(
    id: 'coffee',
    image: 'assets/images/gofry_belgijskie_kawa.jpg',
    imageAlignment: Alignment(-0.9, -0.2),
    name: L('Kawa i herbata', 'Coffee and tea'),
    color: RollColors.sky,
    note: L('M / L to rozmiar kubka. Mleko roślinne +3 zł.', 'M / L is the cup size. Plant milk +3 zł.'),
  ),
  MenuCategory(
    id: 'choco',
    image: 'assets/images/gofry_belgijskie_kawa.jpg',
    imageAlignment: Alignment(-0.9, -0.2),
    name: L('Czekolady', 'Hot chocolate'),
    color: RollColors.purple,
    note: L(
      'Dodatki po 4 zł: maliny, truskawki, jagody lub wiśnie na gorąco, bita śmietana, gałka lodów, '
          'posypka kolorowa, posypka oreo, pianki marshmallow, chilli, cynamon. '
          'Choco set znajdziesz w menu na stoliku.',
      'Extras 4 zł each: hot raspberries, strawberries, blueberries or cherries, whipped cream, a scoop of ice cream, '
          'rainbow sprinkles, Oreo crumbs, marshmallows, chilli, cinnamon. '
          'Ask for the Choco set from the table menu.',
    ),
  ),
];

// Składniki lodów tajskich. Cena zależy od liczby składników w smaku.
const _ingredients = <String, LocalizedText>{
  'oreo': L('oreo', 'Oreo'),
  'truskawka': L('truskawka', 'strawberry'),
  'malina': L('malina', 'raspberry'),
  'espresso': L('espresso', 'espresso'),
  'jagoda': L('jagoda', 'blueberry'),
  'banan': L('banan', 'banana'),
  'matcha': L('matcha', 'matcha'),
  'mieta': L('mięta', 'mint'),
  'maslo': L('masło orzechowe', 'peanut butter'),
  'bueno': L('kinder bueno', 'Kinder Bueno'),
  'beza': L('beza', 'meringue'),
  'raffaello': L('raffaello', 'Raffaello'),
  'nutella': L('nutella', 'Nutella'),
  'michalek': L('biały michałek', 'white Michałek candy'),
  'bczekolada': L('biała czekolada', 'white chocolate'),
  'mango': L('mango', 'mango'),
  'chalwa': L('chałwa', 'halva'),
  'maslane': L('ciastko maślane', 'butter cookie'),
  'pistacje': L('pistacje', 'pistachio'),
  'gruszka': L('gruszka', 'pear'),
  'porzeczka': L('czarna porzeczka', 'blackcurrant'),
  'krowka': L('krówka', 'fudge'),
  'precelki': L('słone precelki', 'salted pretzels'),
  'tiramisu': L('tiramisu (biszkopt, espresso, kakao)', 'tiramisu (sponge, espresso, cocoa)'),
  'brownie': L('brownie', 'brownie'),
  'cini': L('cini minis', 'Cini Minis'),
  'knoppers': L('knoppers', 'Knoppers'),
  'toffi': L('toffi', 'toffee'),
  'maxiking': L('maxi king', 'Maxi King'),
  'kitkat': L('kit kat', 'KitKat'),
  'dubajska': L('dubajska czekolada (kataifi, pistacje, czekolada)', 'Dubai chocolate (kataifi, pistachio, chocolate)'),
  'marakuja': L('marakuja', 'passion fruit'),
  'cytryna': L('cytryna', 'lemon'),
  'liczi': L('liczi', 'lychee'),
  'proteiny': L('proteiny', 'protein'),
  'korzenne': L('ciastko korzenne', 'gingerbread cookie'),
  'miod': L('miód', 'honey'),
};

const rollPrices = {1: 2000, 2: 2300, 3: 2500};

// Polecane smaki w kolejności z menu, w blokach jak na karcie.
const _rollGroups = <(LocalizedText, List<String>)>[
  (
    L('Oreo', 'Oreo'),
    [
      'oreo', 'oreo+truskawka', 'oreo+malina', 'oreo+espresso', 'oreo+jagoda', 'oreo+banan', //
      'oreo+matcha', 'oreo+mieta', 'oreo+maslo', 'oreo+bueno',
    ],
  ),
  (
    L('Malina', 'Raspberry'),
    [
      'malina', 'malina+beza', 'malina+mieta', 'malina+raffaello', 'malina+nutella', 'malina+matcha', //
      'malina+michalek', 'malina+bczekolada',
    ],
  ),
  (
    L('Truskawka', 'Strawberry'),
    [
      'truskawka', 'truskawka+banan', 'truskawka+raffaello', 'truskawka+nutella', 'truskawka+mango', //
      'truskawka+chalwa', 'truskawka+bueno',
    ],
  ),
  (L('Nutella', 'Nutella'), ['nutella', 'nutella+maslane', 'nutella+banan', 'nutella+maslo']),
  (L('Mango', 'Mango'), ['mango', 'mango+mieta', 'mango+jagoda', 'mango+oreo', 'mango+matcha', 'mango+raffaello']),
  (L('Pistacje', 'Pistachio'), ['pistacje', 'pistacje+bueno', 'pistacje+michalek', 'pistacje+bczekolada']),
  (L('Gruszka', 'Pear'), ['gruszka', 'gruszka+mango', 'gruszka+mieta', 'gruszka+banan']),
  (
    L('Czarna porzeczka', 'Blackcurrant'),
    ['porzeczka+beza', 'porzeczka+mieta', 'porzeczka+mango', 'porzeczka+nutella'],
  ),
  (
    L('Krówka i desery', 'Fudge and desserts'),
    ['krowka', 'krowka+precelki', 'tiramisu', 'brownie+maslo', 'cini', 'knoppers', 'precelki+toffi'],
  ),
  (L('Batony i czekolady', 'Candy bars and chocolate'), ['maxiking', 'bueno', 'kitkat+maslo', 'dubajska']),
  (
    L('Marakuja', 'Passion fruit'),
    ['marakuja', 'marakuja+mieta', 'marakuja+mango', 'marakuja+oreo', 'marakuja+truskawka', 'marakuja+cytryna+mieta'],
  ),
  (L('Liczi', 'Lychee'), ['liczi', 'liczi+mieta', 'liczi+mango', 'liczi+malina+mieta', 'liczi+mango+truskawka']),
  (L('Proteiny', 'Protein'), ['proteiny', 'proteiny+truskawka', 'proteiny+malina', 'proteiny+banan', 'proteiny+maslo']),
  (
    L('Więcej smaków', 'More flavours'),
    ['banan+maslo', 'banan+jagoda', 'espresso+chalwa', 'korzenne', 'cytryna+mieta+miod'],
  ),
];

List<MenuItem> _rolls() => [
  for (final (group, combos) in _rollGroups)
    for (final combo in combos) _roll(group, combo),
];

MenuItem _roll(LocalizedText group, String combo) {
  final parts = combo.split('+').map((k) => _ingredients[k]!).toList();
  String join(String Function(LocalizedText) f) {
    final s = parts.map(f).join(' + ');
    return s[0].toUpperCase() + s.substring(1);
  }

  return MenuItem(
    id: 'roll-$combo',
    categoryId: 'rolls',
    group: group,
    name: LocalizedText(join((t) => t.pl), join((t) => t.en)),
    prices: [Price(rollPrices[parts.length]!)],
  );
}

const _freak = [Price(2990)];
const _classic = [Price(2290)];
const _bubble = [
  Price(2700, L('z bitą śmietaną lub z lodami', 'with whipped cream or ice cream')),
  Price(3000, L('z bitą śmietaną i z lodami', 'with whipped cream and ice cream')),
];
const _belgian = [Price(2800)];
const _m = L('M', 'M');
const _l = L('L', 'L');

MenuItem _item(
  String id,
  String category,
  LocalizedText name,
  List<Price> prices, {
  LocalizedText? description,
  LocalizedText? group,
  String? image,
  Set<MenuBadge> badges = const {},
}) => MenuItem(
  id: id,
  categoryId: category,
  name: name,
  prices: prices,
  description: description,
  group: group,
  image: image,
  badges: badges,
);

final List<MenuItem> menuItems = [
  ..._rolls(),

  // Freak Shake
  _item(
    'freak-bueno',
    'freak',
    L('Kinder Bueno', 'Kinder Bueno'),
    _freak,
    description: L(
      'Mleko, lody śmietankowe, krem bueno, bita śmietana, freak dodatki.',
      'Milk, cream ice cream, Bueno cream, whipped cream, freak toppings.',
    ),
  ),
  _item(
    'freak-karmel',
    'freak',
    L('Słony karmel', 'Salted caramel'),
    _freak,
    description: L(
      'Mleko, lody słony karmel, masa słony karmel, bita śmietana, donut, freak dodatki.',
      'Milk, salted caramel ice cream, salted caramel spread, whipped cream, donut, freak toppings.',
    ),
  ),
  _item(
    'freak-babeczka',
    'freak',
    L('Babeczka truskawkowa', 'Strawberry cupcake'),
    _freak,
    description: L(
      'Mleko, truskawki, babeczka, lody śmietankowe, bita śmietana, donut, freak dodatki.',
      'Milk, strawberries, cupcake, cream ice cream, whipped cream, donut, freak toppings.',
    ),
  ),
  _item(
    'freak-pistacja',
    'freak',
    L('Pistacja', 'Pistachio'),
    _freak,
    description: L(
      'Krem pistacjowy, mleko, lody śmietankowe, bita śmietana, freak dodatki.',
      'Pistachio cream, milk, cream ice cream, whipped cream, freak toppings.',
    ),
  ),
  _item(
    'freak-unicorn',
    'freak',
    L('Unicorn', 'Unicorn'),
    _freak,
    description: L(
      'Mleko, lody truskawkowe, mango, bita śmietana, donut, freak dodatki.',
      'Milk, strawberry ice cream, mango, whipped cream, donut, freak toppings.',
    ),
  ),
  _item(
    'freak-cookie',
    'freak',
    L('Cookie Monster', 'Cookie Monster'),
    _freak,
    description: L(
      'Mleko, pieguski, lody śmietankowe, nutella, bita śmietana, donut, freak dodatki.',
      'Milk, chocolate chip cookies, cream ice cream, Nutella, whipped cream, donut, freak toppings.',
    ),
  ),

  // Classic Shake
  _item(
    'classic-truskawka',
    'classic',
    L('Truskawka', 'Strawberry'),
    _classic,
    description: L('Lody śmietankowe, mleko, truskawki.', 'Cream ice cream, milk, strawberries.'),
  ),
  _item(
    'classic-mango',
    'classic',
    L('Truskawka + mango', 'Strawberry + mango'),
    _classic,
    description: L('Lody śmietankowe, mleko, truskawki, mango.', 'Cream ice cream, milk, strawberries, mango.'),
  ),
  _item(
    'classic-oreo',
    'classic',
    L('Oreo', 'Oreo'),
    _classic,
    description: L('Lody śmietankowe, mleko, oreo.', 'Cream ice cream, milk, Oreo.'),
  ),
  _item(
    'classic-proteiny',
    'classic',
    L('Banan + proteiny', 'Banana + protein'),
    _classic,
    description: L(
      'Lody śmietankowe, mleko, banan, odżywka białkowa.',
      'Cream ice cream, milk, banana, protein powder.',
    ),
  ),

  // Gofry bąbelkowe
  _item(
    'bubble-owoce',
    'bubble',
    L('Mix owoców', 'Mixed fruit'),
    _bubble,
    description: L('Mix owoców, polewa toffi, beza.', 'Mixed fruit, toffee sauce, meringue.'),
  ),
  _item(
    'bubble-nutella',
    'bubble',
    L('Nutella', 'Nutella'),
    _bubble,
    description: L("Mix owoców, M&M's, nutella, polewa czekoladowa.", "Mixed fruit, M&M's, Nutella, chocolate sauce."),
  ),
  _item(
    'bubble-oreo',
    'bubble',
    L('Oreo', 'Oreo'),
    _bubble,
    description: L(
      'Mix owoców, posypka oreo, ciastko oreo, polewa czekoladowa.',
      'Mixed fruit, Oreo crumbs, Oreo cookie, chocolate sauce.',
    ),
  ),
  _item(
    'bubble-bueno',
    'bubble',
    L('Kinder Bueno', 'Kinder Bueno'),
    _bubble,
    description: L(
      'Mix owoców, krem bueno, baton bueno, polewa czekoladowa.',
      'Mixed fruit, Bueno cream, Bueno bar, chocolate sauce.',
    ),
  ),
  _item(
    'bubble-unicorn',
    'bubble',
    L('Unicorn', 'Unicorn'),
    _bubble,
    description: L(
      'Mix owoców, krem marshmallow, mini pianki, posypka kolorowa, wata cukrowa.',
      'Mixed fruit, marshmallow cream, mini marshmallows, rainbow sprinkles, cotton candy.',
    ),
  ),
  _item(
    'bubble-raffaello',
    'bubble',
    L('Raffaello', 'Raffaello'),
    _bubble,
    description: L(
      'Mix owoców, krem raffaello, praliny Raffaello, polewa toffi.',
      'Mixed fruit, Raffaello cream, Raffaello pralines, toffee sauce.',
    ),
  ),
  _item(
    'bubble-maslo',
    'bubble',
    L('Masło orzechowe', 'Peanut butter'),
    _bubble,
    description: L(
      'Banan, brzoskwinie, masło orzechowe, popcorn karmelowy, polewa toffi.',
      'Banana, peaches, peanut butter, caramel popcorn, toffee sauce.',
    ),
  ),
  _item(
    'bubble-karmel',
    'bubble',
    L('Słony karmel', 'Salted caramel'),
    _bubble,
    description: L(
      'Banan, precelki, krem słony karmel, orzeszki w karmelu, polewa toffi.',
      'Banana, pretzels, salted caramel cream, caramelised peanuts, toffee sauce.',
    ),
  ),
  _item(
    'bubble-pistacja',
    'bubble',
    L('Pistacja', 'Pistachio'),
    _bubble,
    description: L(
      'Mix owoców, krem pistacjowy, posypka pistacjowa, polewa biała czekolada.',
      'Mixed fruit, pistachio cream, pistachio crumbs, white chocolate sauce.',
    ),
  ),
  _item(
    'bubble-kitkat',
    'bubble',
    L('Kit Kat', 'KitKat'),
    _bubble,
    description: L(
      'Mix owoców, krem kit kat, baton kit kat, polewa czekoladowa.',
      'Mixed fruit, KitKat cream, KitKat bar, chocolate sauce.',
    ),
  ),
  _item('bubble-suchy', 'bubble', L('Suchy lub z cukrem pudrem', 'Plain or with powdered sugar'), const [Price(1000)]),

  // Gofry belgijskie
  _item(
    'belgian-owoce',
    'belgian',
    L('Owocowy raj', 'Fruit paradise'),
    _belgian,
    description: L('Bita śmietana, mix owoców, syrop klonowy.', 'Whipped cream, mixed fruit, maple syrup.'),
  ),
  _item(
    'belgian-lotus',
    'belgian',
    L('Lotus', 'Lotus'),
    _belgian,
    description: L(
      'Lody śmietankowe, mix owoców, krem biscoff, kruszonka z ciasteczek lotus, polewa toffi.',
      'Cream ice cream, mixed fruit, Biscoff cream, Lotus cookie crumble, toffee sauce.',
    ),
  ),
  _item(
    'belgian-pistacja',
    'belgian',
    L('Pistacjowe szaleństwo', 'Pistachio madness'),
    _belgian,
    description: L(
      'Lody śmietankowe, krem pistacjowy, mix owoców, polewa pistacjowa i czekoladowa, posypka pistacjowa.',
      'Cream ice cream, pistachio cream, mixed fruit, pistachio and chocolate sauce, pistachio crumbs.',
    ),
  ),
  _item(
    'belgian-kinder',
    'belgian',
    L('Kinder', 'Kinder'),
    _belgian,
    description: L(
      'Bita śmietana, krem bueno, baton kinder bueno, polewa czekoladowa.',
      'Whipped cream, Bueno cream, Kinder Bueno bar, chocolate sauce.',
    ),
  ),
  _item(
    'belgian-nutella',
    'belgian',
    L('Nutella', 'Nutella'),
    _belgian,
    description: L(
      "Bita śmietana, mix owoców, M&M's, polewa czekoladowa.",
      "Whipped cream, mixed fruit, M&M's, chocolate sauce.",
    ),
  ),

  // Jesienne smaki
  _item(
    'autumn-wisnia',
    'autumn',
    L('Wiśnia w żelu', 'Cherries in jelly'),
    _belgian,
    description: L(
      'Wiśnie w żelu, bita śmietana, wiórki czekoladowe.',
      'Cherries in jelly, whipped cream, chocolate shavings.',
    ),
    badges: {MenuBadge.isNew},
  ),
  _item(
    'autumn-pistacja',
    'autumn',
    L('Pistacja z truskawkami', 'Pistachio with strawberries'),
    _belgian,
    description: L(
      'Truskawki w żelu, bita śmietana, polewa pistacjowa, pistacje.',
      'Strawberries in jelly, whipped cream, pistachio sauce, pistachios.',
    ),
    badges: {MenuBadge.isNew},
  ),
  _item(
    'autumn-jablko',
    'autumn',
    L('Jabłko z cynamonem', 'Apple and cinnamon'),
    _belgian,
    description: L(
      'Ciepłe jabłka z cynamonem, bita śmietana, kruszonka, polewa toffi.',
      'Warm cinnamon apples, whipped cream, crumble, toffee sauce.',
    ),
    badges: {MenuBadge.isNew},
  ),

  // Kawa i herbata
  ...[
    ('espresso', L('Espresso', 'Espresso'), [const Price(800)]),
    ('doppio', L('Podwójne espresso', 'Double espresso'), [const Price(900)]),
    ('affogato', L('Affogato', 'Affogato'), [const Price(1100)]),
    ('americano', L('Americano 180 ml', 'Americano 180 ml'), [const Price(1000)]),
    ('biala', L('Kawa biała', 'White coffee'), [const Price(1200, _m), const Price(1400, _l)]),
    ('cappuccino', L('Cappuccino', 'Cappuccino'), [const Price(1200, _m), const Price(1400, _l)]),
    ('latte', L('Latte', 'Latte'), [const Price(1200, _m), const Price(1400, _l)]),
    ('latte-czek', L('Latte czekoladowe', 'Chocolate latte'), [const Price(1600, _m), const Price(1800, _l)]),
    ('latte-karmel', L('Latte karmelowe', 'Caramel latte'), [const Price(1400, _m), const Price(1600, _l)]),
  ].map((e) => _item('coffee-${e.$1}', 'coffee', e.$2, e.$3, group: const L('Kawa', 'Coffee'))),
  _item(
    'coffee-mrozona',
    'coffee',
    L('Kawa mrożona firmowa', 'Signature iced coffee'),
    const [Price(2300)],
    group: L('Kawa', 'Coffee'),
    description: L(
      '2× espresso, syrop karmelowy, bita śmietana, mleko.',
      '2× espresso, caramel syrup, whipped cream, milk.',
    ),
  ),
  _item('tea', 'coffee', L('Herbata czarna lub zielona', 'Black or green tea'), const [
    Price(1200),
  ], group: L('Herbata', 'Tea')),

  // Czekolady
  ...[
    ('mleczna33', L('Mleczna 33%', 'Milk 33%')),
    ('mleczna40', L('Mleczna 40%', 'Milk 40%')),
    ('deserowa53', L('Deserowa 53%', 'Dark 53%')),
    ('deserowa60', L('Deserowa 60%', 'Dark 60%')),
    ('gorzka70', L('Gorzka 70%', 'Extra dark 70%')),
    ('gorzka80', L('Gorzka 80%', 'Extra dark 80%')),
    ('biala', L('Biała', 'White')),
  ].map((e) => _item('choco-${e.$1}', 'choco', e.$2, const [Price(1690)], group: const L('Classic', 'Classic'))),
  ...[
    ('pomaranczowa', L('Pomarańczowa', 'Orange')),
    ('truskawkowa', L('Truskawkowa', 'Strawberry')),
    ('miodowa', L('Miodowa', 'Honey')),
    ('karmelowa', L('Karmelowa', 'Caramel')),
  ].map((e) => _item('choco-${e.$1}', 'choco', e.$2, const [Price(1990)], group: const L('Select', 'Select'))),
];
