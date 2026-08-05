import 'package:btcg_engine/engine.dart';
import 'package:simulator/kartenstaerke.dart';
import 'package:test/test.dart';

Karte _karte(
  String id,
  List<String> slots, {
  Kategorie kategorie = Kategorie.gebet,
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

List<Karte> _pool() => [
  for (var i = 0; i < 20; i++)
    _karte('r$i', ['x', '1', 'x', '1', 'x', '1']),
  for (var i = 0; i < 8; i++) _karte('s$i', ['-1', 'x', '-1', 'x', '-1', 'x']),
  for (var i = 0; i < 10; i++)
    _karte(
      'e$i',
      ['-1', '-1', '-1', '-1', '-1', '-1'],
      kategorie: Kategorie.evil,
      anzahlImDeckMax: 1,
    ),
  _karte('estart', [
    '-1',
    '-1',
    '-1',
    '-1',
    '-1',
    '-1',
  ], kategorie: Kategorie.start),
];

void main() {
  group('bewerteKarte', () {
    test('liefert ein strukturell gültiges Ergebnis', () {
      final pool = _pool();
      final referenzAufbau = baueZufaelligesDeck(
        id: 'referenz',
        name: 'referenz',
        alleKarten: pool,
        seed: 1,
      );
      final karte = pool.firstWhere((k) => k.id == 'r0');

      final ergebnis = bewerteKarte(
        karte: karte,
        kartenpool: pool,
        referenzAufbau: referenzAufbau,
        stichprobengroesse: 5,
        startSeed: 10,
      );

      expect(ergebnis.cardId, 'r0');
      expect(ergebnis.stichprobengroesse, 5);
      expect(ergebnis.deltaWinrate, inInclusiveRange(-1, 1));
    });

    test('eine deutlich überlegene Karte hat eine positive Heiligkeits-Delta', () {
      // Eine Karte mit sehr hohem Farbwert an einer Position, die durch
      // viele Löcher im Deck sichtbar wird, sollte im Schnitt helfen.
      final pool = _pool();
      final starkeKarte = _karte('stark', [
        'x',
        '2',
        'x',
        '2',
        'x',
        '2',
      ], anzahlImDeckMax: 1);
      final referenzAufbau = baueZufaelligesDeck(
        id: 'referenz',
        name: 'referenz',
        alleKarten: pool,
        seed: 1,
      );

      final ergebnis = bewerteKarte(
        karte: starkeKarte,
        kartenpool: [...pool, starkeKarte],
        referenzAufbau: referenzAufbau,
        stichprobengroesse: 20,
        startSeed: 10,
      );

      // Nicht strikt deterministisch behauptet, aber die Richtung sollte
      // bei diesem klaren Beispiel stimmen.
      expect(ergebnis.deltaHeiligkeit, greaterThanOrEqualTo(0));
    });
  });

  group('bewerteAlleKarten', () {
    test('bewertet jede Ressourcenkarte genau einmal', () {
      final pool = _pool();
      final ergebnisse = bewerteAlleKarten(
        kartenpool: pool,
        stichprobengroesse: 2,
        startSeed: 1,
      );
      expect(ergebnisse.length, 28); // 20 r + 8 s, kein evil/start
      expect(ergebnisse.map((e) => e.cardId).toSet().length, 28);
    });
  });
}
