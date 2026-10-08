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
}
