import 'package:btcg_engine/engine.dart';
import 'package:simulator/effektwert.dart';
import 'package:test/test.dart';

Karte _karte(String id, List<String> slots, Kategorie kategorie, {int anzahlImDeckMax = 3}) => Karte(
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

List<Karte> _kartenpool() => [
  for (var i = 0; i < 12; i++) _karte('loch$i', ['x', 'x', 'x', '0', '0', '0'], Kategorie.gebet),
  for (var i = 0; i < 12; i++) _karte('wert$i', ['2', '2', '2', '1', '1', '1'], Kategorie.gebet),
  for (var i = 0; i < 7; i++)
    _karte('e$i', ['-1', '-1', '-1', '-1', '-1', '-1'], Kategorie.evil, anzahlImDeckMax: 1),
  _karte('estart', ['-1', '-1', '-1', '-1', '-1', '-1'], Kategorie.start),
];

void main() {
  test('karteMitEffekt behält Slots und Kategorie, bekommt eigene ID', () {
    final basis = _kartenpool().first;
    final variante = karteMitEffekt(basis, const Umordnung(UmordnungZiel.eigen));
    expect(variante.id, isNot(basis.id));
    expect(variante.slots, basis.slots);
    expect(variante.kategorie, basis.kategorie);
    expect(variante.effekt, isA<Umordnung>());
  });

  test('bewerteEffekt: umordnung wird eingesetzt und bringt messbar Sofort-Punkte', () {
    final pool = _kartenpool();
    final e = bewerteEffekt(
      effekt: const Umordnung(UmordnungZiel.eigen),
      kartenpool: pool,
      referenzAufbau: baueZufaelligesDeck(id: 'ref', name: 'ref', alleKarten: pool, seed: 1),
      stichprobengroesse: 30,
      startSeed: 10,
    );
    expect(e.einsaetze, greaterThan(0));
    expect(e.sofortGewinne, hasLength(e.einsaetze));
    expect(e.sofortGewinne, everyElement(greaterThanOrEqualTo(0)),
        reason: 'GreedyBot verschiebt nur, wenn es nicht schadet');
  });
}
