import 'package:btcg_engine/bots/bots.dart';
import 'package:btcg_engine/engine.dart';
import 'package:simulator/simulator.dart';
import 'package:test/test.dart';

List<Karte> _kartenpool() {
  final ressourcen = [
    for (var i = 0; i < 20; i++)
      _karte('r$i', ['x', '1', 'x', '1', 'x', '1'], Kategorie.gebet),
    for (var i = 0; i < 8; i++)
      _karte('s$i', ['-1', 'x', '-1', 'x', '-1', 'x'], Kategorie.gebet),
  ];
  final evil = [
    for (var i = 0; i < 10; i++)
      _karte('e$i', ['-1', '-1', '-1', '-1', '-1', '-1'], Kategorie.evil, anzahlImDeckMax: 1),
  ];
  final start = _karte('estart', ['-1', '-1', '-1', '-1', '-1', '-1'], Kategorie.start);
  return [...ressourcen, ...evil, start];
}

Karte _karte(
  String id,
  List<String> slots,
  Kategorie kategorie, {
  int anzahlImDeckMax = 3,
}) => Karte(
  id: id,
  cardId: id,
  name: id,
  vers: const Vers(stelle: '', text: ''),
  slots: slots.map(SlotSymbol.parse).toList(),
  kategorie: kategorie,
  seltenheit: 'haeufig',
  sofort: false,
  effekt: null,
  anzahlImDeckMax: anzahlImDeckMax,
  pictureLink: '',
);

void main() {
  group('simulator', () {
    test('spielePartieMitMetriken beendet eine Partie', () {
      final ergebnis = spielePartieMitMetriken(
        seed: 1,
        kartenpool: _kartenpool(),
        bot1: const GreedyBot(),
        bot2: const GreedyBot(),
      );
      expect(ergebnis.abgebrochen, isFalse);
      expect(ergebnis.gewinnerId, isNotNull);
      expect(ergebnis.zuege, greaterThan(0));
    });

    test('simuliere aggregiert über mehrere Partien', () {
      final ergebnis = simuliere(
        anzahlPartien: 20,
        startSeed: 100,
        kartenpool: _kartenpool(),
        bot1Fabrik: () => const GreedyBot(),
        bot2Fabrik: () => const GreedyBot(),
      );
      expect(ergebnis.beendet, 20);
      expect(ergebnis.medianZuege, greaterThan(0));
      expect(ergebnis.startspielerWinrate, inInclusiveRange(0, 1));
      final summeAnteile = ergebnis.kategorieAnteile.values.fold(0.0, (a, b) => a + b);
      expect(summeAnteile, closeTo(1.0, 0.001));

      expect(ergebnis.medianFuehrungswechsel, greaterThanOrEqualTo(0));
      expect(ergebnis.wertungsSchwankung, greaterThanOrEqualTo(0));
      expect(ergebnis.genutzteKartenvielfalt, inInclusiveRange(0, 1));
      expect(ergebnis.meistgespielteKarten(top: 3).length, lessThanOrEqualTo(3));
    });

    test('ohne Evil ist Evil-Phase immer ein Passen', () {
      final ergebnis = spielePartieMitMetriken(
        seed: 5,
        kartenpool: _kartenpool(),
        bot1: const GreedyBot(),
        bot2: const GreedyBot(),
        config: const SimulatorConfig(mitEvil: false),
      );
      expect(ergebnis.abgebrochen, isFalse);
    });

    test('kategorieAnteile bleibt bei sich aufhebenden Summen bei <= 100%', () {
      // Regressionstest: gebet (+1000) und evil (-900) heben sich in der
      // Netto-Summe fast auf (+100) — die Anteile dürfen sich trotzdem nicht
      // an einem kleinen Netto-Nenner orientieren (das ergäbe > 100%).
      final ergebnis = SammelErgebnis(
        anzahlPartien: 1,
        abgebrochen: 0,
        zuege: const [10],
        tiefpunkte: const [20],
        startspielerSiege: 1,
        kategorieSummen: const {Kategorie.gebet: 1000, Kategorie.evil: -900},
        personSummen: const {},
        fuehrungswechsel: const [2],
        alleWertungsWerte: const [1, -1, 2],
        gespielteKartenGesamt: const {},
        kartenpoolGroesse: 0,
      );
      final anteile = ergebnis.kategorieAnteile;
      for (final wert in anteile.values) {
        expect(wert, lessThanOrEqualTo(1.0));
      }
      expect(anteile[Kategorie.gebet], closeTo(1000 / 1900, 0.001));
      expect(anteile[Kategorie.evil], closeTo(900 / 1900, 0.001));
    });

    test('median berechnet korrekt für gerade und ungerade Längen', () {
      expect(median([1, 2, 3]), 2);
      expect(median([1, 2, 3, 4]), 2.5);
      expect(median([]), 0);
    });

    test('stddev ist 0 bei konstanten Werten und > 0 bei Streuung', () {
      expect(stddev([5, 5, 5, 5]), 0);
      expect(stddev([]), 0);
      expect(stddev([1]), 0);
      expect(stddev([0, 10]), closeTo(7.07, 0.01));
    });

    test('genutzteKartenvielfalt und meistgespielteKarten', () {
      final ergebnis = SammelErgebnis(
        anzahlPartien: 1,
        abgebrochen: 0,
        zuege: const [10],
        tiefpunkte: const [20],
        startspielerSiege: 1,
        kategorieSummen: const {},
        personSummen: const {},
        fuehrungswechsel: const [1],
        alleWertungsWerte: const [],
        gespielteKartenGesamt: const {'a': 5, 'b': 2, 'c': 1},
        kartenpoolGroesse: 10,
      );
      expect(ergebnis.genutzteKartenvielfalt, closeTo(0.3, 0.001));
      expect(
        ergebnis.meistgespielteKarten(top: 2).map((e) => e.key),
        ['a', 'b'],
      );
    });
  });
}
