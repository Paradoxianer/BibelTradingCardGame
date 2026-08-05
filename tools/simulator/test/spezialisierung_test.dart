import 'package:btcg_engine/engine.dart';
import 'package:simulator/spezialisierung.dart';
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

void main() {
  group('personStaerke', () {
    test('summiert nur die beiden Slots der Person, Löcher zählen 0', () {
      // V1=2, V2=x, S1=1, S2=x, HG1=-1, HG2=x
      final karte = _karte('k', ['2', 'x', '1', 'x', '-1', 'x']);
      expect(personStaerke(karte, Person.vater), 2);
      expect(personStaerke(karte, Person.sohn), 1);
      expect(personStaerke(karte, Person.heiligerGeist), -1);
    });
  });

  group('baueSpezialisiertesDeck', () {
    test('priorisiert Ressourcenkarten mit der höchsten Personenstärke', () {
      final starkeVaterKarte = _karte('stark', ['2', '2', '0', '0', '0', '0'], anzahlImDeckMax: 1);
      final schwacheVaterKarte = _karte(
        'schwach',
        ['0', '0', '0', '0', '0', '0'],
        anzahlImDeckMax: 30,
      );
      final evil = [
        for (var i = 0; i < 10; i++)
          _karte('e$i', [
            '-1',
            '-1',
            '-1',
            '-1',
            '-1',
            '-1',
          ], kategorie: Kategorie.evil, anzahlImDeckMax: 1),
      ];
      final start = _karte('estart', [
        '-1',
        '-1',
        '-1',
        '-1',
        '-1',
        '-1',
      ], kategorie: Kategorie.start);
      final pool = [starkeVaterKarte, schwacheVaterKarte, ...evil, start];

      final aufbau = baueSpezialisiertesDeck(
        id: 'p1',
        kartenpool: pool,
        zielPerson: Person.vater,
        seed: 1,
      );

      expect(aufbau.deck.length, 35);
      // Die starke Karte (anzahlImDeckMax: 1) muss vor der schwachen kommen.
      expect(aufbau.deck.where((k) => k.id == 'stark').length, 1);
      expect(aufbau.deck.where((k) => k.id == 'schwach').length, 27);
    });
  });

  group('vergleicheSpezialisierung', () {
    test('liefert plausible, strukturell gültige Ergebnisse', () {
      final pool = [
        for (var i = 0; i < 20; i++)
          _karte('r$i', ['x', '1', 'x', '1', 'x', '1']),
        for (var i = 0; i < 8; i++)
          _karte('s$i', ['-1', 'x', '-1', 'x', '-1', 'x']),
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

      final ergebnis = vergleicheSpezialisierung(
        kartenpool: pool,
        zielPerson: Person.vater,
        anzahlPartien: 10,
        startSeed: 1,
      );

      expect(ergebnis.anzahlPartien, 10);
      expect(ergebnis.spezialistWinrate, inInclusiveRange(0, 1));
      expect(ergebnis.avgHeiligkeitSpezialist, greaterThanOrEqualTo(0));
      expect(ergebnis.avgHeiligkeitNormal, greaterThanOrEqualTo(0));
    });
  });
}
