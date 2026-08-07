import 'package:btcg_app/ui/widgets/slot_symbole.dart';
import 'package:btcg_engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

Karte _karte(String id, List<String> slots) => Karte(
  id: id,
  cardId: id,
  name: id,
  vers: const Vers(stelle: '', text: ''),
  slots: slots.map(SlotSymbol.parse).toList(),
  kategorie: Kategorie.gebet,
  seltenheit: 'haeufig',
  sofort: false,
  effekt: null,
  anzahlImDeckMax: 3,
  pictureLink: '',
);

void main() {
  test('offene Karte: sechs Zellen in Kartenreihenfolge, nichts verdeckt', () {
    final karte = _karte('a', ['x', '1', '-1', '0', '2', '0']);
    final zellen = slotsFuerKarte(karte);

    expect(zellen.length, 6);
    expect(zellen.map((z) => z.pos), kSlotOrder);
    expect(zellen.every((z) => !z.verdeckt), isTrue);
    expect(zellen.first.symbol, isA<Loch>());
    expect((zellen[1].symbol as Farbig).wert, 1);
    expect(zellen[2].symbol, isA<Schwarz>());
  });

  test('verdeckte Karte: Löcher sichtbar, Werte nicht, Reihenfolge gespiegelt', () {
    // Loch nur an V1, also vorne.
    final karte = _karte('b', ['x', '1', '1', '1', '1', '2']);
    final zellen = slotsFuerVerdeckteKarte(karte);

    expect(zellen.length, 6);
    expect(zellen.map((z) => z.pos), kSlotOrder.reversed);

    // Gespiegelt liegt das Loch hinten — und nur es ist nicht verdeckt.
    expect(zellen.last.symbol, isA<Loch>());
    expect(zellen.last.verdeckt, isFalse);
    expect(zellen.take(5).every((z) => z.verdeckt), isTrue);
  });

  test('jede Person hat ihre eigene Farbe, Slot-Paare teilen sie', () {
    expect(personenFarbe(SlotPosition.v1), personenFarbe(SlotPosition.v2));
    expect(personenFarbe(SlotPosition.s1), personenFarbe(SlotPosition.s2));
    expect(personenFarbe(SlotPosition.hg1), personenFarbe(SlotPosition.hg2));

    final farben = {
      personenFarbe(SlotPosition.v1),
      personenFarbe(SlotPosition.s1),
      personenFarbe(SlotPosition.hg1),
    };
    expect(farben.length, 3, reason: 'drei unterscheidbare Personenfarben');
  });
}
