import 'package:flutter_test/flutter_test.dart';
import 'package:ice_rolls/data/menu_data.dart';
import 'package:ice_rolls/widgets/category_note.dart';

void main() {
  test('notatka lodów: ceny, studenci, dodatki i opis', () {
    final rolls = categories.firstWhere((c) => c.id == 'rolls');
    final blocks = parseNote(rolls.note!.pl);
    expect(blocks.map((b) => b.runtimeType), [PriceBlock, PriceBlock, TagBlock, TextBlock]);
    final first = blocks[0] as PriceBlock;
    expect(first.label, isNull);
    expect(first.prices, hasLength(3));
    expect(first.prices.first.$2, '20 zł');
    expect((blocks[1] as PriceBlock).label, 'Studenci');
    expect((blocks[2] as TagBlock).tags, ['bita śmietana', 'polewa', 'posypka']);
    expect((blocks[3] as TextBlock).text, startsWith('Składniki można'));
  });

  test('cena przed nazwą i kilka zdań z cenami', () {
    final bubble = parseNote('27 zł z bitą śmietaną lub z lodami · 30 zł z bitą śmietaną i z lodami');
    expect((bubble.single as PriceBlock).prices.first, ('z bitą śmietaną lub z lodami', '27 zł'));
    final classic = parseNote('Każdy Classic Shake 22,90 zł. Bita śmietana +4 zł.');
    expect((classic.single as PriceBlock).prices, [('Każdy Classic Shake', '22,90 zł'), ('Bita śmietana', '+4 zł')]);
  });

  test('zwykły tekst zostaje opisem', () {
    final coffee = parseNote('M / L to rozmiar kubka. Mleko roślinne +3 zł.');
    expect(coffee.map((b) => b.runtimeType), [TextBlock, PriceBlock]);
  });

  test('każda notatka z menu daje przynajmniej jeden blok, PL i EN', () {
    for (final c in categories.where((c) => c.note != null)) {
      expect(parseNote(c.note!.pl), isNotEmpty, reason: c.id);
      expect(parseNote(c.note!.en), isNotEmpty, reason: c.id);
    }
  });
}
