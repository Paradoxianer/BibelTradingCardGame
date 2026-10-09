import 'package:btcg_engine/bots/bots.dart';
import 'package:btcg_engine/engine.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  test('GreedyBot mischt beim Bauen einer erneuerung-Karte die Evil-Karten der Hand zurück', () {
    final erneuerung = testKarte(
      'ern',
      ['x', '1', 'x', '1', 'x', '1'],
      effekt: const Erneuerung(2),
    );
    Karte evil(String id) => testKarte(
      id,
      ['-1', '-1', '-1', '-1', '-1', '-1'],
      kategorie: Kategorie.evil,
      anzahlImDeckMax: 1,
    );
    final state = testState([
      testSpieler(
        'p1',
        hand: [erneuerung, evil('e1'), evil('e2'), evil('e3')],
        deck: [for (var i = 0; i < 5; i++) testKarte('r$i', ['x', '1', 'x', '1', 'x', '1'])],
      ),
      testSpieler('p2'),
    ]);

    final (command, _) = const GreedyBot().waehleCommand(state, 'p1', SeedableRng.seeded(1));

    expect(command, isA<KarteBauen>());
    final bauen = command as KarteBauen;
    expect(bauen.karteId, 'ern');
    final wahl = bauen.effektWahl as ErneuerungWahl;
    expect(wahl.handKartenIds, hasLength(2), reason: 'menge 2 begrenzt die Auswahl');
    expect(wahl.handKartenIds, everyElement(startsWith('e')), reason: 'nur Evil-Karten');
  });

  test('GreedyBot nutzt umordnung, um eine wertvolle Karte unter ein Loch zu schieben', () {
    final loch = testKarte('loch', ['x', 'x', 'x', 'x', 'x', 'x']);
    final null0 = testKarte('null', ['0', '0', '0', '0', '0', '0']);
    final zwei = testKarte('zwei', ['2', '2', '2', '2', '2', '2']);
    final umordnung = testKarte(
      'umo',
      ['0', '0', '0', '0', '0', '0'],
      effekt: const Umordnung(UmordnungZiel.eigen),
    );
    // Feld 0: Loch oben, darunter die Null-Karte — die 2er liegt verdeckt
    // ganz unten. Eine Verschiebung bringt sie direkt unter das Loch.
    final state = testState([
      testSpieler(
        'p1',
        hand: [umordnung],
        spielfelder: [testFeld([loch, null0, zwei]), const Spielfeld(), const Spielfeld()],
      ),
      testSpieler('p2'),
    ]);
    final vorher = berechneWertung(state, 'p1').punkte;

    final (command, _) = const GreedyBot().waehleCommand(state, 'p1', SeedableRng.seeded(1));
    expect(command, isA<KarteBauen>());
    expect((command as KarteBauen).effektWahl, isA<UmordnungWahl>());

    final (nachher, _) = GameEngine().apply(state, command);
    final feld0 = nachher.spielerMitId('p1').spielfelder[0].stapel.map((l) => l.karte.id).toList();
    expect(feld0.indexOf('zwei'), 1, reason: 'die 2er liegt jetzt direkt unter dem Loch');
    expect(berechneWertung(nachher, 'p1').punkte, greaterThan(vorher));
  });
}
