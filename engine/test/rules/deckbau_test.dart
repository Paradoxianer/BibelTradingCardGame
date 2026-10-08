import 'package:btcg_engine/engine.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

List<Karte> _gueltigesDeck() => [
  for (var i = 0; i < 28; i++) testKarte('r$i', ['0', '0', '0', '0', '0', '0']),
  for (var i = 0; i < 7; i++)
    testKarte('e$i', ['-1', '-1', '-1', '-1', '-1', '-1'], kategorie: Kategorie.evil, anzahlImDeckMax: 1),
];

void main() {
  group('pruefeDeck (REGELWERK §2)', () {
    test('gültiges Deck liefert keine Fehler', () {
      expect(pruefeDeck(_gueltigesDeck()), isEmpty);
    });

    test('meldet falsche Deckgröße', () {
      final deck = _gueltigesDeck()..removeLast();
      expect(pruefeDeck(deck), contains(contains('34 von genau 35')));
    });

    test('meldet zu wenige Evil-Karten', () {
      final deck = _gueltigesDeck()..removeWhere((k) => k.kategorie == Kategorie.evil);
      final fehler = pruefeDeck(deck);
      expect(fehler, contains(contains('0 von genau 7 Evil')));
    });

    test('meldet doppelte Evil-Karten', () {
      final deck = _gueltigesDeck();
      deck[deck.indexWhere((k) => k.id == 'e1')] = deck.firstWhere((k) => k.id == 'e0');
      expect(pruefeDeck(deck), contains('Evil-Karten müssen alle unterschiedlich sein.'));
    });

    test('meldet Überschreitung von anzahlImDeckMax', () {
      final deck = _gueltigesDeck();
      final r0 = deck.firstWhere((k) => k.id == 'r0');
      // anzahlImDeckMax des Test-Helpers ist 3 -> vier Kopien überschreiten es.
      deck[1] = r0;
      deck[2] = r0;
      deck[3] = r0;
      final fehler = pruefeDeck(deck);
      expect(fehler, contains(contains('"r0" 4× im Deck')));
    });

    test('meldet die Startkarte, falls versehentlich im Deck', () {
      final deck = _gueltigesDeck();
      deck[0] = testKarte('estart', ['-1', '-1', '-1', '-1', '-1', '-1'], kategorie: Kategorie.start);
      expect(
        pruefeDeck(deck),
        contains('Die Startkarte gehört nicht ins Deck, sie liegt automatisch aus.'),
      );
    });
  });
}
