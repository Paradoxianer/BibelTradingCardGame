import 'package:btcg_engine/bots/bots.dart';
import 'package:btcg_engine/engine.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

// Alle Kartentypen brauchen mindestens ein Loch, wie im echten Bestand
// (sheet_import-Report: Ø ~2,3 Löcher/Karte bei "gebet"). Ohne Löcher kann
// keine Karte je etwas Positives freilegen — ein Greedy-Bot sieht dann nie
// eine echte Verbesserung, hortet Karten auf ewig in der Hand, und D2
// greift nie (die Hand wird nie leer). Das ist ein Artefakt einer
// unrealistischen Testdatenmenge, keine Regelwerks-Lücke.
List<Karte> _deck(String prefix) => [
  for (var i = 0; i < 20; i++)
    testKarte('$prefix-r$i', ['x', '1', 'x', '1', 'x', '1']),
  for (var i = 0; i < 8; i++)
    testKarte('$prefix-s$i', ['-1', 'x', '-1', 'x', '-1', 'x']),
  for (var i = 0; i < 7; i++)
    testKarte(
      '$prefix-e$i',
      ['-1', '-1', '-1', '-1', '-1', '-1'],
      kategorie: Kategorie.evil,
      anzahlImDeckMax: 1,
    ),
];

SpielerAufbau _aufbau(String id) => SpielerAufbau(
  id: id,
  name: id,
  deck: _deck(id),
  eStart: testKarte('$id-estart', ['-1', '-1', '-1', '-1', '-1', '-1'], kategorie: Kategorie.start),
);

int _gesamtKartenzahl(GameState state) {
  var summe = 0;
  for (final s in state.spieler) {
    summe += s.hand.length + s.deck.length;
    for (final feld in s.spielfelder) {
      summe += feld.stapel.length;
    }
  }
  return summe;
}

void main() {
  final engine = GameEngine();

  for (final MapEntry(key: name, value: bots) in {
    'Greedy vs. Greedy': {'p1': const GreedyBot(), 'p2': const GreedyBot()},
    'Zufall vs. Zufall': {'p1': const ZufallsBot(), 'p2': const ZufallsBot()},
    'Greedy vs. Zufall': {'p1': const GreedyBot(), 'p2': const ZufallsBot()},
  }.entries) {
    test('$name: Partien laufen sauber durch (10 Seeds)', () {
      for (var seed = 0; seed < 10; seed++) {
        final anfangszustand = neuesSpiel(
          spieler: [_aufbau('p1'), _aufbau('p2')],
          seed: seed,
        );
        final erwarteteKartenzahl = _gesamtKartenzahl(anfangszustand);

        final ende = spielePartieBisEnde(
          engine: engine,
          anfangszustand: anfangszustand,
          bots: bots,
          botRng: SeedableRng.seeded(seed + 1000),
        );

        expect(ende.spielLaeuft, isFalse, reason: 'Seed $seed sollte enden');
        expect(ende.gewinnerId, isNotNull);
        expect(_gesamtKartenzahl(ende), erwarteteKartenzahl, reason: 'Seed $seed');
        for (final s in ende.spieler) {
          expect(s.heiligkeit, greaterThanOrEqualTo(0), reason: 'Seed $seed, ${s.id}');
        }
      }
    });
  }
}
