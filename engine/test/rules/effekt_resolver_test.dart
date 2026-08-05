import 'package:btcg_engine/engine.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  final engine = GameEngine();

  group('Effekte (EFFEKTE.md §2)', () {
    test('zuwendung (heiligkeit) erhöht sofort beim Ausspielen', () {
      final karte = testKarte(
        'zuw',
        ['0', '0', '0', '0', '0', '0'],
        effekt: const Zuwendung(art: ZuwendungArt.heiligkeit, menge: 3),
      );
      final s1 = testSpieler('p1', hand: [karte]);
      final state = testState([s1, testSpieler('p2')]).copyWith(rundeNummer: 2);

      final (neu, events) = engine.apply(
        state,
        const KarteBauen(feldIndex: 0, karteId: 'zuw'),
      );

      expect(neu.spielerMitId('p1').heiligkeit, kStartHeiligkeit + 3);
      expect(events.whereType<EffektAusgeloest>().length, 1);
    });

    test('zuwendung (karten) zieht sofort beim Ausspielen', () {
      final karte = testKarte(
        'zuw',
        ['0', '0', '0', '0', '0', '0'],
        effekt: const Zuwendung(art: ZuwendungArt.karten, menge: 2),
      );
      final deck = [
        testKarte('d1', ['0', '0', '0', '0', '0', '0']),
        testKarte('d2', ['0', '0', '0', '0', '0', '0']),
      ];
      final s1 = testSpieler('p1', hand: [karte], deck: deck);
      final state = testState([s1, testSpieler('p2')]).copyWith(rundeNummer: 2);

      final (neu, _) = engine.apply(
        state,
        const KarteBauen(feldIndex: 0, karteId: 'zuw'),
      );

      expect(neu.spielerMitId('p1').hand.length, 2);
      expect(neu.spielerMitId('p1').deck, isEmpty);
    });

    test('suche findet eine gefilterte Karte im Deck und mischt danach', () {
      final karte = testKarte(
        'such',
        ['0', '0', '0', '0', '0', '0'],
        effekt: const Suche(Kategorie.glauben),
      );
      final ziel = testKarte('glaube1', ['0', '0', '0', '0', '0', '0'], kategorie: Kategorie.glauben);
      final andere = testKarte('gebet1', ['0', '0', '0', '0', '0', '0'], kategorie: Kategorie.gebet);
      final s1 = testSpieler('p1', hand: [karte], deck: [andere, ziel]);
      final state = testState([s1, testSpieler('p2')]).copyWith(rundeNummer: 2);

      final (neu, _) = engine.apply(
        state,
        KarteBauen(feldIndex: 0, karteId: 'such', effektWahl: SucheWahl('glaube1')),
      );

      final p1 = neu.spielerMitId('p1');
      expect(p1.hand.map((k) => k.id), contains('glaube1'));
      expect(p1.deck.length, 1);
      expect(p1.deck.first.id, 'gebet1');
    });

    test('suche gegen den Filter wird abgelehnt', () {
      final karte = testKarte(
        'such',
        ['0', '0', '0', '0', '0', '0'],
        effekt: const Suche(Kategorie.glauben),
      );
      final gebet = testKarte('gebet1', ['0', '0', '0', '0', '0', '0'], kategorie: Kategorie.gebet);
      final s1 = testSpieler('p1', hand: [karte], deck: [gebet]);
      final state = testState([s1, testSpieler('p2')]).copyWith(rundeNummer: 2);

      expect(
        () => engine.apply(
          state,
          KarteBauen(feldIndex: 0, karteId: 'such', effektWahl: SucheWahl('gebet1')),
        ),
        throwsA(isA<RegelVerstoss>()),
      );
    });

    test('erneuerung tauscht Handkarten gegen neue aus dem Deck', () {
      final karte = testKarte(
        'erneu',
        ['0', '0', '0', '0', '0', '0'],
        effekt: const Erneuerung(2),
      );
      final schlecht1 = testKarte('schlecht1', ['0', '0', '0', '0', '0', '0']);
      final schlecht2 = testKarte('schlecht2', ['0', '0', '0', '0', '0', '0']);
      final deck = [
        testKarte('neu1', ['0', '0', '0', '0', '0', '0']),
        testKarte('neu2', ['0', '0', '0', '0', '0', '0']),
      ];
      final s1 = testSpieler('p1', hand: [karte, schlecht1, schlecht2], deck: deck);
      final state = testState([s1, testSpieler('p2')]).copyWith(rundeNummer: 2);

      final (neu, _) = engine.apply(
        state,
        KarteBauen(
          feldIndex: 0,
          karteId: 'erneu',
          effektWahl: ErneuerungWahl(['schlecht1', 'schlecht2']),
        ),
      );

      final p1 = neu.spielerMitId('p1');
      expect(p1.hand.length, 2);
      expect(p1.deck.length, 2);
      // Die 4 betroffenen Karten (2 zurückgemischt + 2 ursprünglich im Deck)
      // verteilen sich neu auf Hand+Deck, gehen aber nicht verloren.
      final alleIds = {...p1.hand.map((k) => k.id), ...p1.deck.map((k) => k.id)};
      expect(alleIds, {'schlecht1', 'schlecht2', 'neu1', 'neu2'});
    });

    test('umordnung tauscht die Position zweier Karten im eigenen Stapel', () {
      final unten = testKarte('unten', ['1', '0', '0', '0', '0', '0']);
      final mitte = testKarte('mitte', ['x', '0', '0', '0', '0', '0']);
      final umordner = testKarte(
        'umordner',
        ['x', '0', '0', '0', '0', '0'],
        effekt: const Umordnung(UmordnungZiel.eigen),
      );
      final feld = testFeld([mitte, unten]);
      final s1 = testSpieler(
        'p1',
        hand: [umordner],
        spielfelder: [feld, const Spielfeld(), const Spielfeld()],
      );
      final state = testState([s1, testSpieler('p2')]).copyWith(rundeNummer: 2);

      // Nach dem Legen: [umordner, mitte, unten] (Tiefe 0,1,2).
      // Verschiebe "unten" (Tiefe 2) an Tiefe 1: [umordner, unten, mitte].
      final (neu, _) = engine.apply(
        state,
        KarteBauen(
          feldIndex: 0,
          karteId: 'umordner',
          effektWahl: UmordnungWahl(feldIndex: 0, vonTiefe: 2, nachTiefe: 1),
        ),
      );

      final stapel = neu.spielerMitId('p1').spielfelder[0].stapel;
      expect(stapel.map((k) => k.karte.id).toList(), ['umordner', 'unten', 'mitte']);
    });

    test('gebietserweiterung fügt ein viertes Spielfeld hinzu', () {
      final karte = testKarte(
        'gebiet',
        ['0', '0', '0', '0', '0', '0'],
        effekt: const Gebietserweiterung(),
      );
      final s1 = testSpieler('p1', hand: [karte]);
      final state = testState([s1, testSpieler('p2')]).copyWith(rundeNummer: 2);

      final (neu, events) = engine.apply(
        state,
        const KarteBauen(feldIndex: 0, karteId: 'gebiet'),
      );

      final p1 = neu.spielerMitId('p1');
      expect(p1.spielfelder.length, 4);
      expect(p1.spielfelder[3].stapel.single.karte.id, 'gebiet');
      expect(p1.hatGebietserweiterung, isTrue);
      expect(events.whereType<GebietErweitert>().length, 1);
    });

    test('gebietserweiterung ist auf eine pro Spieler begrenzt', () {
      final schonDa = testKarte('schonda', ['0', '0', '0', '0', '0', '0'], effekt: const Gebietserweiterung());
      final zweite = testKarte('zweite', ['0', '0', '0', '0', '0', '0'], effekt: const Gebietserweiterung());
      final s1 = testSpieler(
        'p1',
        hand: [zweite],
        spielfelder: [
          const Spielfeld(),
          const Spielfeld(),
          const Spielfeld(),
          testFeld([schonDa]),
        ],
      );
      final state = testState([s1, testSpieler('p2')]).copyWith(rundeNummer: 2);

      expect(
        () => engine.apply(state, const KarteBauen(feldIndex: 0, karteId: 'zweite')),
        throwsA(isA<RegelVerstoss>()),
      );
    });
  });
}
