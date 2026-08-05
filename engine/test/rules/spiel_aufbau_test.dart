import 'package:btcg_engine/engine.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

List<Karte> _testDeck(String prefix) => [
  for (var i = 0; i < 28; i++) testKarte('$prefix-r$i', ['0', '0', '0', '0', '0', '0']),
  for (var i = 0; i < 7; i++)
    testKarte('$prefix-e$i', ['-1', '-1', '-1', '-1', '-1', '-1'], kategorie: Kategorie.evil, anzahlImDeckMax: 1),
];

SpielerAufbau _aufbau(String id) => SpielerAufbau(
  id: id,
  name: id,
  deck: _testDeck(id),
  eStart: testKarte('$id-estart', ['-1', '-1', '-1', '-1', '-1', '-1'], kategorie: Kategorie.start),
);

void main() {
  group('Spielaufbau (REGELWERK §4)', () {
    test('EStart liegt auf Feld 1, Deck hat 35 Karten, Hand hat 5', () {
      final state = neuesSpiel(spieler: [_aufbau('p1'), _aufbau('p2')], seed: 1);
      for (final s in state.spieler) {
        expect(s.spielfelder[0].stapel.length, 1);
        expect(s.spielfelder[0].oberste!.karte.kategorie, Kategorie.start);
        expect(s.hand.length, 5);
        expect(s.deck.length, 30);
        expect(s.hand.length + s.deck.length, 35);
      }
    });

    test('D5: Startspieler zieht nur 4 Karten, wenn Flag aktiv', () {
      final state = neuesSpiel(
        spieler: [_aufbau('p1'), _aufbau('p2')],
        seed: 1,
        config: const RegelConfig(startspielerZiehtNurVier: true),
      );
      expect(state.spieler[0].hand.length, 4);
      expect(state.spieler[1].hand.length, 5);
    });

    test('gleicher Seed liefert deterministisch denselben Aufbau', () {
      final a = neuesSpiel(spieler: [_aufbau('p1'), _aufbau('p2')], seed: 7);
      final b = neuesSpiel(spieler: [_aufbau('p1'), _aufbau('p2')], seed: 7);
      expect(a.spieler[0].hand.map((k) => k.id), b.spieler[0].hand.map((k) => k.id));
      expect(a.spieler[0].deck.map((k) => k.id), b.spieler[0].deck.map((k) => k.id));
      expect(a.spieler[0].id, b.spieler[0].id);
    });
  });
}
