import 'package:btcg_engine/model/model.dart';
import 'package:btcg_engine/rules/wertung.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('Wertungsalgorithmus (REGELWERK §6)', () {
    test('bunter Wert auf der obersten Karte zählt nicht', () {
      final feld = testFeld([testKarte('k1', ['2', '1', '0', '1', '2', '0'])]);
      final s = testSpieler('p1', spielfelder: [feld, const Spielfeld(), const Spielfeld()]);
      final wertung = berechneWertung(testState([s]), 'p1');
      expect(wertung.punkte, 0);
    });

    test('schwarzer Wert auf der obersten Karte zählt immer', () {
      final feld = testFeld([testKarte('k1', ['-1', '-1', '-1', '-1', '-1', '-1'])]);
      final s = testSpieler('p1', spielfelder: [feld, const Spielfeld(), const Spielfeld()]);
      final wertung = berechneWertung(testState([s]), 'p1');
      expect(wertung.punkte, -6); // EStart-Fall, D7
    });

    test('bunter Wert zählt, wenn durch ein Loch der Karte darüber sichtbar', () {
      final unten = testKarte('unten', ['2', '0', '0', '0', '0', '0']);
      final oben = testKarte('oben', ['x', '0', '0', '0', '0', '0']);
      final feld = testFeld([oben, unten]);
      final s = testSpieler('p1', spielfelder: [feld, const Spielfeld(), const Spielfeld()]);
      final wertung = berechneWertung(testState([s]), 'p1');
      expect(wertung.punkte, 2);
    });

    test('Loch-Kette über mehrere Karten schaut bis zum ersten Symbol durch', () {
      final unten = testKarte('unten', ['1', '0', '0', '0', '0', '0']);
      final mitte = testKarte('mitte', ['x', '0', '0', '0', '0', '0']);
      final oben = testKarte('oben', ['x', '0', '0', '0', '0', '0']);
      final feld = testFeld([oben, mitte, unten]);
      final s = testSpieler('p1', spielfelder: [feld, const Spielfeld(), const Spielfeld()]);
      final wertung = berechneWertung(testState([s]), 'p1');
      expect(wertung.punkte, 1);
    });

    test('schwarzer Wert zählt auch durch ein Loch sichtbar', () {
      final unten = testKarte('unten', ['-1', '0', '0', '0', '0', '0']);
      final oben = testKarte('oben', ['x', '0', '0', '0', '0', '0']);
      final feld = testFeld([oben, unten]);
      final s = testSpieler('p1', spielfelder: [feld, const Spielfeld(), const Spielfeld()]);
      final wertung = berechneWertung(testState([s]), 'p1');
      expect(wertung.punkte, -1);
    });

    test('Loch ohne Karte darunter zählt die Spalte als 0', () {
      final oben = testKarte('oben', ['x', '0', '0', '0', '0', '0']);
      final feld = testFeld([oben]);
      final s = testSpieler('p1', spielfelder: [feld, const Spielfeld(), const Spielfeld()]);
      final wertung = berechneWertung(testState([s]), 'p1');
      expect(wertung.punkte, 0);
    });

    test('leeres Spielfeld wertet 0', () {
      final s = testSpieler('p1');
      final wertung = berechneWertung(testState([s]), 'p1');
      expect(wertung.punkte, 0);
    });

    test('alle drei Spielfelder werden zusammen gewertet', () {
      final f1 = testFeld([testKarte('a', ['-1', '0', '0', '0', '0', '0'])]);
      final f2 = testFeld([testKarte('b', ['-1', '0', '0', '0', '0', '0'])]);
      final f3 = testFeld([testKarte('c', ['-1', '0', '0', '0', '0', '0'])]);
      final s = testSpieler('p1', spielfelder: [f1, f2, f3]);
      final wertung = berechneWertung(testState([s]), 'p1');
      expect(wertung.punkte, -3);
    });

    test('umkehrung wandelt schwarz in positiv nur im angegebenen Slot', () {
      final unten = testKarte('unten', ['-1', '-1', '0', '0', '0', '0']);
      final umkehrer = testKarte(
        'umkehrer',
        ['x', 'x', '0', '0', '0', '0'],
        effekt: Umkehrung([1]),
      );
      final feld = testFeld([umkehrer, unten]);
      final s = testSpieler('p1', spielfelder: [feld, const Spielfeld(), const Spielfeld()]);
      final wertung = berechneWertung(testState([s]), 'p1');
      // Slot 1 (V1): -1 -> +1 durch umkehrung. Slot 2 (V2): -1 bleibt -1.
      expect(wertung.punkte, 0);
    });

    test('umkehrung wirkt nur, solange die Effektkarte oben liegt', () {
      final unten = testKarte('unten', ['-1', '0', '0', '0', '0', '0']);
      final umkehrer = testKarte('umkehrer', ['x', '0', '0', '0', '0', '0'], effekt: Umkehrung([1]));
      final ueberbaut = testKarte('ueberbaut', ['x', '0', '0', '0', '0', '0']);
      final feld = testFeld([ueberbaut, umkehrer, unten]);
      final s = testSpieler('p1', spielfelder: [feld, const Spielfeld(), const Spielfeld()]);
      final wertung = berechneWertung(testState([s]), 'p1');
      // umkehrer ist nicht mehr oben -> normale Wertung: -1.
      expect(wertung.punkte, -1);
    });

    test('globale_aura addiert einen festen Zuschlag für alle Spieler', () {
      final auraKarte = testKarte(
        'aura',
        ['0', '0', '0', '0', '0', '0'],
        effekt: const GlobaleAura(1),
      );
      final f1 = testFeld([auraKarte]);
      final s1 = testSpieler('p1', spielfelder: [f1, const Spielfeld(), const Spielfeld()]);
      final s2 = testSpieler('p2');
      final state = testState([s1, s2]);
      expect(berechneWertung(state, 'p1').punkte, 1);
      expect(berechneWertung(state, 'p2').punkte, 1);
    });

    test('Punktebeitrag je Kategorie und Person wird korrekt zugeordnet', () {
      final gebet = testKarte('g1', ['2', '0', '0', '0', '0', '0'], kategorie: Kategorie.gebet);
      final glauben = testKarte('l1', ['x', '0', '0', '0', '0', '0'], kategorie: Kategorie.glauben);
      final feld = testFeld([glauben, gebet]);
      final s = testSpieler('p1', spielfelder: [feld, const Spielfeld(), const Spielfeld()]);
      final wertung = berechneWertung(testState([s]), 'p1');

      final jeKategorie = punkteJeKategorie(wertung);
      expect(jeKategorie[Kategorie.gebet], 2);
      expect(jeKategorie.containsKey(Kategorie.glauben), isFalse); // 0 Punkte, nicht gezählt

      final jePerson = punkteJePerson(wertung);
      expect(jePerson[Person.vater], 2);
      expect(jePerson.containsKey(Person.sohn), isFalse);
    });
  });

  group('werteFeld (einzelnes Feld, u.a. für die UI-Vorschau)', () {
    test('stimmt mit berechneWertung für dasselbe Feld überein', () {
      final unten = testKarte('u', ['2', '-1', '0', '0', '0', '0']);
      final oben = testKarte('o', ['x', 'x', '0', '0', '0', '0']);
      final feld = testFeld([oben, unten]);
      final s = testSpieler(
        'p1',
        spielfelder: [feld, const Spielfeld(), const Spielfeld()],
      );

      final ausGesamtwertung = berechneWertung(testState([s]), 'p1').felder[0];
      expect(werteFeld(feld, 0).punkte, ausGesamtwertung.punkte);
      // 2 durch Loch sichtbar, -1 zählt immer.
      expect(werteFeld(feld, 0).punkte, 1);
    });

    test('bewertet ein hypothetisches Feld: Karte drauflegen als Vorschau', () {
      final unten = testKarte('u', ['2', '2', '0', '0', '0', '0']);
      final feld = testFeld([unten]);
      // Bunte Werte der obersten Karte zählen nicht -> vorher 0 Punkte.
      expect(werteFeld(feld, 0).punkte, 0);

      // Karte mit Löchern darüber legt die beiden 2er frei.
      final mitLoechern = testKarte('o', ['x', 'x', '0', '0', '0', '0']);
      expect(werteFeld(feld.legeObenauf(mitLoechern), 0).punkte, 4);

      // Karte ohne Löcher verdeckt sie -> bleibt 0.
      final ohneLoecher = testKarte('o2', ['1', '1', '0', '0', '0', '0']);
      expect(werteFeld(feld.legeObenauf(ohneLoecher), 0).punkte, 0);
    });

    test('leeres Feld bringt 0 Punkte', () {
      expect(werteFeld(const Spielfeld(), 0).punkte, 0);
    });
  });
}
