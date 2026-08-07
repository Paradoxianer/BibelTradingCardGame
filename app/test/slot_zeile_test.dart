import 'package:btcg_app/ui/widgets/slot_zeile.dart';
import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';
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

List<String> _assets(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((img) => (img.image as AssetImage).assetName)
    .toList();

const String _marker = 'assets/artwork/Loch_Marker.png';

void main() {
  testWidgets('Handkarte: immer 6 Zellen, Loch zeigt den durchsichtigen Marker', (
    tester,
  ) async {
    final karte = _karte('a', ['x', '1', '-1', '0', '2', '0']);
    await tester.pumpWidget(MaterialApp(home: SlotZeile.fuerKarte(karte)));

    final assets = _assets(tester);
    // Das Loch zeichnet nur Ring und Dreiecke; die Mitte bleibt frei, damit
    // der Hintergrund durchscheint.
    expect(assets, [
      _marker,
      'assets/artwork/V_1.png',
      'assets/artwork/S_-1.png',
      'assets/artwork/S_0.png',
      'assets/artwork/HG_2.png',
      'assets/artwork/HG_0.png',
    ]);
    expect(assets.length, 6, reason: 'immer genau 6 Zellen');
  });

  testWidgets('Karte mit Loch: Marker statt Wert-Tile an der Lochstelle', (
    tester,
  ) async {
    final karte = _karte('a', ['x', '2', '0', '0', '0', '0']);
    await tester.pumpWidget(MaterialApp(home: SlotZeile.fuerKarte(karte)));

    final assets = _assets(tester);
    expect(assets.first, _marker, reason: 'Loch: nur Ring und Dreiecke');
    expect(assets[1], 'assets/artwork/V_2.png');
    expect(assets.length, 6);
  });
}
