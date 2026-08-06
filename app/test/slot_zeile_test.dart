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
  testWidgets('Handkarte: immer 6 Zellen, Loch zeigt das Loch-Tile', (
    tester,
  ) async {
    final karte = _karte('a', ['x', '1', '-1', '0', '2', '0']);
    await tester.pumpWidget(MaterialApp(home: SlotZeile.fuerKarte(karte)));

    final assets = _assets(tester);
    expect(assets, [
      'assets/artwork/V_x.png',
      'assets/artwork/V_1.png',
      'assets/artwork/S_-1.png',
      'assets/artwork/S_0.png',
      'assets/artwork/HG_2.png',
      'assets/artwork/HG_0.png',
    ]);
    // In der Hand liegt nichts darunter — kein "zählt"-Marker.
    expect(assets, isNot(contains(_marker)));
  });

  testWidgets(
    'Feld: bunter Wert durch ein Loch gesehen bekommt den "zählt"-Marker',
    (tester) async {
      final unten = _karte('unten', ['2', '0', '0', '0', '0', '0']);
      final oben = _karte('oben', ['x', '1', '0', '0', '0', '0']);
      final feld = Spielfeld([Kartenlage(oben), Kartenlage(unten)]);

      await tester.pumpWidget(MaterialApp(home: SlotZeile.fuerFeld(feld)));

      final assets = _assets(tester);
      // V1: durch das Loch von "oben" sieht man die 2 von "unten" -> zählt.
      expect(assets, contains('assets/artwork/V_2.png'));
      expect(assets, contains(_marker));
      // Genau ein Marker — nur V1 wird durch ein Loch gesehen.
      expect(assets.where((a) => a == _marker).length, 1);
      // V2 kommt von "oben" selbst (Tiefe 0) und zählt daher nicht.
      expect(assets, contains('assets/artwork/V_1.png'));
    },
  );

  testWidgets('Feld: Spalte komplett aus Löchern zeigt das Loch-Tile', (
    tester,
  ) async {
    final unten = _karte('unten', ['x', '0', '0', '0', '0', '0']);
    final oben = _karte('oben', ['x', '0', '0', '0', '0', '0']);
    final feld = Spielfeld([Kartenlage(oben), Kartenlage(unten)]);

    await tester.pumpWidget(MaterialApp(home: SlotZeile.fuerFeld(feld)));

    final assets = _assets(tester);
    expect(assets.first, 'assets/artwork/V_x.png');
    expect(assets, isNot(contains(_marker)));
  });

  testWidgets('Feld: oberste Karte ohne Loch verdeckt alles darunter', (
    tester,
  ) async {
    final unten = _karte('unten', ['2', '2', '2', '2', '2', '2']);
    final oben = _karte('oben', ['0', '0', '0', '0', '0', '0']);
    final feld = Spielfeld([Kartenlage(oben), Kartenlage(unten)]);

    await tester.pumpWidget(MaterialApp(home: SlotZeile.fuerFeld(feld)));

    final assets = _assets(tester);
    expect(assets, isNot(contains('assets/artwork/V_2.png')));
    expect(assets, isNot(contains(_marker)));
    expect(assets.length, 6, reason: 'immer genau 6 Zellen, nie Lücken');
  });

  testWidgets('Feld und Hand liefern beide immer genau 6 Zellen', (
    tester,
  ) async {
    final karte = _karte('k', ['x', 'x', 'x', 'x', 'x', 'x']);
    await tester.pumpWidget(MaterialApp(home: SlotZeile.fuerKarte(karte)));
    expect(_assets(tester).length, 6);

    await tester.pumpWidget(
      MaterialApp(home: SlotZeile.fuerFeld(const Spielfeld())),
    );
    expect(_assets(tester).length, 6, reason: 'auch ein leeres Feld');
  });
}
