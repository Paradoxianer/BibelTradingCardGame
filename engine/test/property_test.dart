import 'package:btcg_engine/engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

int _gesamtKartenzahl(GameState state) {
  var summe = 0;
  for (final s in state.spieler) {
    summe += s.hand.length;
    summe += s.deck.length;
    for (final feld in s.spielfelder) {
      summe += feld.stapel.length;
    }
  }
  if (state.pendingEvilKarte != null) summe += 1;
  return summe;
}

List<Karte> _deck(String prefix) => [
  for (var i = 0; i < 20; i++)
    testKarte('$prefix-r$i', ['0', '1', '0', '1', '0', '1']),
  for (var i = 0; i < 8; i++)
    testKarte('$prefix-s$i', ['-1', '0', '-1', '0', '-1', '0']),
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
  eStart: testKarte(
    '$id-estart',
    ['-1', '-1', '-1', '-1', '-1', '-1'],
    kategorie: Kategorie.start,
  ),
);

/// Deterministischer "dümmster Bot": baut immer die erste Nicht-Evil-Karte
/// der Hand auf Feld 0, spielt nie Evil, reagiert nie. Reicht, um viele Züge
/// am Stück durch die Engine zu schicken.
GameState _einfacherZug(GameEngine engine, GameState state) {
  var s = state;
  if (s.phase == ZugPhase.bauen) {
    final hand = s.aktiverSpieler.hand;
    final spielbar = hand.where((k) => k.kategorie != Kategorie.evil);
    if (spielbar.isNotEmpty) {
      final (neu, _) = engine.apply(
        s,
        KarteBauen(feldIndex: 0, karteId: spielbar.first.id),
      );
      s = neu;
    } else {
      final (neu, _) = engine.apply(s, const Passen());
      s = neu;
    }
  }
  if (s.phase == ZugPhase.evilSpielen) {
    final (neu, _) = engine.apply(s, const Passen());
    s = neu;
  }
  if (s.phase == ZugPhase.reaktion) {
    final (neu, _) = engine.apply(s, const Passen());
    s = neu;
  }
  return s;
}

void main() {
  group('Property-Tests (ARCHITEKTUR §6)', () {
    test('Kartenzahl bleibt über viele Züge konstant, Heiligkeit fällt nie unter 0', () {
      final engine = GameEngine();
      var state = neuesSpiel(spieler: [_aufbau('p1'), _aufbau('p2')], seed: 99);
      final erwarteteKartenzahl = _gesamtKartenzahl(state);

      for (var i = 0; i < 60 && state.spielLaeuft; i++) {
        state = _einfacherZug(engine, state);
        expect(_gesamtKartenzahl(state), erwarteteKartenzahl);
        for (final s in state.spieler) {
          expect(s.heiligkeit, greaterThanOrEqualTo(0));
        }
      }
    });

    test('Determinismus: gleicher Seed + gleiche Commands = identische Events', () {
      final engine = GameEngine();

      List<String> lauf(int seed) {
        var state = neuesSpiel(spieler: [_aufbau('p1'), _aufbau('p2')], seed: seed);
        final protokoll = <String>[];
        for (var i = 0; i < 40 && state.spielLaeuft; i++) {
          state = _einfacherZug(engine, state);
          protokoll.add(
            '${state.aktiverIndex}|${state.phase}|${state.rundeNummer}|'
            '${state.spieler.map((s) => '${s.id}:${s.heiligkeit}:${s.hand.length}:${s.deck.length}').join(',')}',
          );
        }
        return protokoll;
      }

      final a = lauf(2024);
      final b = lauf(2024);
      expect(a, b);
    });
  });
}
