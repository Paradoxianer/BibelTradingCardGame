import 'package:btcg_app/ui/widgets/slot_layout.dart';
import 'package:btcg_engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

const double _breite = 240;
const SlotLayout _layout = SlotLayout(
  kartenBreite: _breite,
  zelle: _breite / 8.2,
  oben: _breite / 40,
);

void main() {
  group('SlotLayout — gemeinsame Geometrie für Zeichnen und Stanzen', () {
    test('sechs Zellen sitzen mittig und ohne Überlappung nebeneinander', () {
      final mitten = [for (var i = 0; i < 6; i++) _layout.mitte(i)];

      // Waagerecht aufsteigend, gleicher Abstand.
      final abstaende = [
        for (var i = 1; i < 6; i++) mitten[i].dx - mitten[i - 1].dx,
      ];
      for (final a in abstaende) {
        expect(a, closeTo(_layout.zelle + SlotLayout.abstand, 0.001));
      }

      // Symmetrisch zur Kartenmitte.
      final mitteDerZeile = (mitten.first.dx + mitten.last.dx) / 2;
      expect(mitteDerZeile, closeTo(_breite / 2, 0.001));

      // Alle auf derselben Höhe.
      for (final m in mitten) {
        expect(m.dy, closeTo(_layout.oben + _layout.zelle / 2, 0.001));
      }
    });

    test('die Stanzung bleibt innerhalb der Zelle, der Ring bleibt stehen', () {
      // Innenradius aus dem Tile gemessen: 121,5 von 378.
      expect(_layout.lochRadius, closeTo(_layout.zelle * 121.5 / 378, 0.001));
      // Deutlich kleiner als die halbe Zelle — sonst wäre der Ring weg.
      expect(_layout.lochRadius, lessThan(_layout.zelle / 2));
    });

    test('die Zeile passt in die Karte', () {
      expect(_layout.startX, greaterThan(0));
      expect(_layout.startX + _layout.gesamtBreite, lessThan(_breite));
    });
  });

  group('welche Slots gestanzt werden', () {
    Karte karte(List<String> slots) => Karte(
      id: 'k',
      cardId: 'k',
      name: 'k',
      vers: const Vers(stelle: '', text: ''),
      slots: slots.map(SlotSymbol.parse).toList(),
      kategorie: Kategorie.gebet,
      seltenheit: 'haeufig',
      sofort: false,
      effekt: null,
      anzahlImDeckMax: 3,
      pictureLink: '',
    );

    test('genau die Loch-Slots, in Anzeigereihenfolge', () {
      final k = karte(['x', '1', 'x', '0', '-1', 'x']);
      final loecher = [
        for (var i = 0; i < kSlotOrder.length; i++)
          if (k.slotAn(kSlotOrder[i]) is Loch) i,
      ];
      expect(loecher, [0, 2, 5]);
    });

    test('Karte ohne Loch wird nicht gestanzt', () {
      final k = karte(['1', '1', '0', '0', '-1', '2']);
      final loecher = [
        for (var i = 0; i < kSlotOrder.length; i++)
          if (k.slotAn(kSlotOrder[i]) is Loch) i,
      ];
      expect(loecher, isEmpty);
    });
  });
}
