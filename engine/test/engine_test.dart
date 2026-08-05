import 'package:btcg_engine/engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  final engine = GameEngine();

  group('Rundenablauf (REGELWERK §5)', () {
    test('Bauen legt Karte obenauf und wechselt zur Evil-Phase', () {
      final karte = testKarte('k1', ['0', '0', '0', '0', '0', '0']);
      final s1 = testSpieler('p1', hand: [karte]);
      final s2 = testSpieler('p2');
      var state = testState([s1, s2]).copyWith(rundeNummer: 2);

      final (neu, events) = engine.apply(
        state,
        const KarteBauen(feldIndex: 0, karteId: 'k1'),
      );

      expect(neu.phase, ZugPhase.evilSpielen);
      expect(neu.spielerMitId('p1').spielfelder[0].oberste!.karte.id, 'k1');
      expect(neu.spielerMitId('p1').hand, isEmpty);
      expect(events.whereType<KarteGelegt>().length, 1);
    });

    test('Passen im Bauen ist erlaubt (Bauen ist optional)', () {
      final s1 = testSpieler('p1');
      final s2 = testSpieler('p2');
      final state = testState([s1, s2]).copyWith(rundeNummer: 2);
      final (neu, _) = engine.apply(state, const Passen());
      expect(neu.phase, ZugPhase.evilSpielen);
    });

    test('Passen in Evil-Phase löst Wertung, Nachziehen und Zugwechsel aus', () {
      final schwarzKarte = testKarte('schwarz', ['-1', '0', '0', '0', '0', '0']);
      final feld = testFeld([schwarzKarte]);
      final s1 = testSpieler(
        'p1',
        spielfelder: [feld, const Spielfeld(), const Spielfeld()],
        deck: [testKarte('d1', ['0', '0', '0', '0', '0', '0'])],
      );
      final s2 = testSpieler('p2');
      final state = testState([
        s1,
        s2,
      ]).copyWith(phase: ZugPhase.evilSpielen, rundeNummer: 2);

      final (neu, events) = engine.apply(state, const Passen());

      expect(neu.spielerMitId('p1').heiligkeit, kStartHeiligkeit - 1);
      expect(neu.spielerMitId('p1').hand.length, 1); // 1 Karte nachgezogen
      expect(neu.aktiverIndex, 1);
      expect(neu.phase, ZugPhase.bauen);
      expect(events.whereType<HeiligkeitGeaendert>().length, 1);
      expect(events.whereType<ZugBeendet>().length, 1);
    });

    test('Runde erhöht sich erst, wenn wieder Spieler 0 an der Reihe ist', () {
      final restDeck = [testKarte('d', ['0', '0', '0', '0', '0', '0'])];
      final s1 = testSpieler('p1', deck: restDeck);
      final s2 = testSpieler('p2', deck: restDeck);
      var state = testState([
        s1,
        s2,
      ]).copyWith(phase: ZugPhase.evilSpielen, rundeNummer: 2, aktiverIndex: 0);
      var (neu, _) = engine.apply(state, const Passen());
      expect(neu.rundeNummer, 2); // p1 -> p2, noch keine neue Runde
      neu = neu.copyWith(phase: ZugPhase.evilSpielen);
      final (neu2, _) = engine.apply(neu, const Passen());
      expect(neu2.rundeNummer, 3); // p2 -> p1, neue Runde
    });

    test('Heiligkeit fällt nie unter 0', () {
      final schwarzKarte = testKarte('schwarz', ['-1', '-1', '-1', '-1', '-1', '-1']);
      final feld = testFeld([schwarzKarte]);
      final s1 = testSpieler(
        'p1',
        heiligkeit: 2,
        spielfelder: [feld, const Spielfeld(), const Spielfeld()],
      );
      final s2 = testSpieler('p2');
      final state = testState([
        s1,
        s2,
      ]).copyWith(phase: ZugPhase.evilSpielen, rundeNummer: 2);
      final (neu, _) = engine.apply(state, const Passen());
      expect(neu.spielerMitId('p1').heiligkeit, 0);
    });

    test('Sieg bei >= 100 Heiligkeit am Ende der Wertungsphase', () {
      final buntKarteUnten = testKarte('unten', ['2', '2', '2', '2', '2', '2']);
      final lochKarte = testKarte('loch', ['x', 'x', 'x', 'x', 'x', 'x']);
      final feld = testFeld([lochKarte, buntKarteUnten]);
      final s1 = testSpieler(
        'p1',
        heiligkeit: 99,
        spielfelder: [feld, const Spielfeld(), const Spielfeld()],
      );
      final s2 = testSpieler('p2');
      final state = testState([
        s1,
        s2,
      ]).copyWith(phase: ZugPhase.evilSpielen, rundeNummer: 2);
      final (neu, events) = engine.apply(state, const Passen());
      expect(neu.gewinnerId, 'p1');
      expect(neu.spielLaeuft, false);
      expect(events.whereType<SpielerGewonnen>().length, 1);
    });
  });

  group('Evil-Karten (REGELWERK D1, D4, D8)', () {
    test('Evil ist in Runde 1 verboten', () {
      final evil = testKarte('e1', ['-1', '0', '0', '0', '0', '0'], kategorie: Kategorie.evil);
      final s1 = testSpieler('p1', hand: [evil]);
      final s2 = testSpieler('p2');
      final state = testState([
        s1,
        s2,
      ]).copyWith(phase: ZugPhase.evilSpielen, rundeNummer: 1);

      expect(
        () => engine.apply(
          state,
          const EvilSpielen(zielSpielerId: 'p2', zielFeldIndex: 0, karteId: 'e1'),
        ),
        throwsA(isA<RegelVerstoss>()),
      );
    });

    test('Angreifer wählt das Zielfeld, Evil landet obenauf (D1)', () {
      final evil = testKarte('e1', ['-1', '0', '0', '0', '0', '0'], kategorie: Kategorie.evil);
      final s1 = testSpieler('p1', hand: [evil]);
      final s2 = testSpieler('p2');
      final state = testState([
        s1,
        s2,
      ]).copyWith(phase: ZugPhase.evilSpielen, rundeNummer: 2);

      final (neu, events) = engine.apply(
        state,
        const EvilSpielen(zielSpielerId: 'p2', zielFeldIndex: 1, karteId: 'e1'),
      );

      expect(neu.spielerMitId('p2').spielfelder[1].oberste!.karte.id, 'e1');
      expect(events.whereType<EvilGespielt>().length, 1);
    });

    test('ein Spieler kann pro Runde nur einmal Evil erhalten (D8)', () {
      final evil1 = testKarte('e1', ['-1', '0', '0', '0', '0', '0'], kategorie: Kategorie.evil);
      final s1 = testSpieler('p1', hand: [evil1]);
      final s2 = testSpieler('p2');
      final state = testState([
        s1,
        s2,
      ]).copyWith(
        phase: ZugPhase.evilSpielen,
        rundeNummer: 2,
        evilEmpfangenDieseRunde: {'p2'},
      );

      expect(
        () => engine.apply(
          state,
          const EvilSpielen(zielSpielerId: 'p2', zielFeldIndex: 0, karteId: 'e1'),
        ),
        throwsA(isA<RegelVerstoss>()),
      );
    });

    test('Sofort-Reaktion: Verteidiger darf sofort-Karte spielen (D4)', () {
      final evil = testKarte('e1', ['-1', '0', '0', '0', '0', '0'], kategorie: Kategorie.evil);
      final sofortKarte = testKarte('s1', ['0', '0', '0', '0', '0', '0'], sofort: true);
      final s1 = testSpieler('p1', hand: [evil]);
      final s2 = testSpieler('p2', hand: [sofortKarte]);
      final state = testState([
        s1,
        s2,
      ]).copyWith(phase: ZugPhase.evilSpielen, rundeNummer: 2);

      final (nachEvil, _) = engine.apply(
        state,
        const EvilSpielen(zielSpielerId: 'p2', zielFeldIndex: 0, karteId: 'e1'),
      );
      expect(nachEvil.phase, ZugPhase.reaktion);

      final (neu, events) = engine.apply(
        nachEvil,
        const SofortReagieren(karteId: 's1'),
      );
      // Reaktionskarte unten, Evil-Karte landet danach trotzdem obenauf
      expect(neu.spielerMitId('p2').spielfelder[0].stapel.length, 2);
      expect(neu.spielerMitId('p2').spielfelder[0].oberste!.karte.id, 'e1');
      expect(events.whereType<SofortGespielt>().length, 1);
    });

    test('schutz wehrt die Evil-Karte ab, sie geht zurück auf die Hand des Angreifers', () {
      final evil = testKarte('e1', ['-1', '0', '0', '0', '0', '0'], kategorie: Kategorie.evil);
      final schutzKarte = testKarte(
        'schild',
        ['0', '0', '0', '0', '0', '0'],
        sofort: true,
        effekt: const Schutz(reichweite: SchutzReichweite.feld),
      );
      final s1 = testSpieler('p1', hand: [evil]);
      final s2 = testSpieler('p2', hand: [schutzKarte]);
      final state = testState([
        s1,
        s2,
      ]).copyWith(phase: ZugPhase.evilSpielen, rundeNummer: 2);

      final (nachEvil, _) = engine.apply(
        state,
        const EvilSpielen(zielSpielerId: 'p2', zielFeldIndex: 0, karteId: 'e1'),
      );
      final (neu, events) = engine.apply(
        nachEvil,
        const SofortReagieren(karteId: 'schild'),
      );

      expect(neu.spielerMitId('p2').spielfelder[0].stapel.length, 1);
      expect(neu.spielerMitId('p2').spielfelder[0].oberste!.karte.id, 'schild');
      expect(neu.spielerMitId('p1').hand.map((k) => k.id), contains('e1'));
      expect(events.whereType<EvilAbgewehrt>().length, 1);
      expect(neu.evilEmpfangenDieseRunde.contains('p2'), isFalse);
    });

    test('bereits liegender schutz wehrt Evil automatisch ab, ohne Reaktion', () {
      final evil = testKarte('e1', ['-1', '0', '0', '0', '0', '0'], kategorie: Kategorie.evil);
      final schutzKarte = testKarte(
        'schild',
        ['0', '0', '0', '0', '0', '0'],
        effekt: const Schutz(reichweite: SchutzReichweite.spieler),
      );
      final s1 = testSpieler('p1', hand: [evil]);
      final feldMitSchutz = testFeld([schutzKarte]);
      final s2 = testSpieler(
        'p2',
        spielfelder: [const Spielfeld(), feldMitSchutz, const Spielfeld()],
      );
      final state = testState([
        s1,
        s2,
      ]).copyWith(phase: ZugPhase.evilSpielen, rundeNummer: 2);

      final (neu, events) = engine.apply(
        state,
        const EvilSpielen(zielSpielerId: 'p2', zielFeldIndex: 0, karteId: 'e1'),
      );

      expect(neu.spielerMitId('p2').spielfelder[0].istLeer, isTrue);
      expect(neu.spielerMitId('p1').hand.map((k) => k.id), contains('e1'));
      expect(events.whereType<EvilAbgewehrt>().length, 1);
    });
  });

  group('D2: Deck leer', () {
    test('wenn niemand mehr handeln kann, gewinnt die höchste Heiligkeit', () {
      final s1 = testSpieler('p1', heiligkeit: 50, hand: const [], deck: const []);
      final s2 = testSpieler('p2', heiligkeit: 40, hand: const [], deck: const []);
      final state = testState([
        s1,
        s2,
      ]).copyWith(phase: ZugPhase.evilSpielen, rundeNummer: 2);
      final (neu, events) = engine.apply(state, const Passen());
      expect(neu.gewinnerId, 'p1');
      expect(events.whereType<PartieEndeDeckLeer>().length, 1);
    });
  });

  group('Determinismus (ARCHITEKTUR §2)', () {
    test('gleicher Seed + gleiche Commands = gleiches Ergebnis', () {
      GameState lauf(int seed) {
        final karte = testKarte('k1', ['0', '0', '0', '0', '0', '0']);
        var state = testState(
          [testSpieler('p1', hand: [karte]), testSpieler('p2')],
          seed: seed,
        ).copyWith(rundeNummer: 2);
        final (nach1, _) = engine.apply(
          state,
          const KarteBauen(feldIndex: 0, karteId: 'k1'),
        );
        final (nach2, _) = engine.apply(nach1, const Passen());
        return nach2;
      }

      final a = lauf(123);
      final b = lauf(123);
      expect(a.spieler[0].heiligkeit, b.spieler[0].heiligkeit);
      expect(a.aktiverIndex, b.aktiverIndex);
      expect(a.rng.state, b.rng.state);
    });
  });
}
