import 'package:btcg_app/ui/widgets/karten_widget.dart';
import 'package:btcg_app/ui/widgets/slot_zeile.dart';
import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Karte _karte(String id, List<String> slots, {String seltenheit = 'haeufig'}) =>
    Karte(
      id: id,
      cardId: id,
      name: id,
      vers: const Vers(stelle: 'Philipper 1,19', text: 'Denn ich weiß …'),
      slots: slots.map(SlotSymbol.parse).toList(),
      kategorie: Kategorie.gebet,
      seltenheit: seltenheit,
      sofort: false,
      effekt: null,
      anzahlImDeckMax: 3,
      pictureLink: '',
    );

List<String> _assets(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((img) => (img.image as AssetImage).assetName)
    .where((a) => a.contains('/V_') || a.contains('/S_') || a.contains('/HG_'))
    .toList();

Future<void> _zeige(WidgetTester tester, Widget w) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: w))),
  );
}

void main() {
  final karte = _karte('a', ['x', '1', '-1', '0', '2', '0']);

  testWidgets('kompakt und voll zeigen dieselben sechs Slot-Zellen', (
    tester,
  ) async {
    await _zeige(tester, KartenWidget.handkarte(karte));
    final kompakt = _assets(tester);

    await _zeige(
      tester,
      KartenWidget.handkarte(karte, ansicht: KartenAnsicht.voll, breite: 320),
    );
    final voll = _assets(tester);

    expect(kompakt.length, 5, reason: '5 Wert-Tiles, das Loch hat keins');
    expect(kompakt, voll, reason: 'gleiche Karte, gleiche Symbole');
  });

  testWidgets('nur die Vollansicht zeigt Bibeltext und card_id', (
    tester,
  ) async {
    await _zeige(tester, KartenWidget.handkarte(karte));
    expect(find.text('Denn ich weiß …'), findsNothing);
    // Die Versangabe bleibt auch kompakt sichtbar — sie trägt den Inhalt.
    expect(find.text('Philipper 1,19'), findsOneWidget);

    await _zeige(
      tester,
      KartenWidget.handkarte(karte, ansicht: KartenAnsicht.voll, breite: 320),
    );
    expect(find.text('Denn ich weiß …'), findsOneWidget);
    expect(find.text('a'), findsWidgets); // Name und card_id
  });

  testWidgets('Rückseite verrät keinen Wert und spiegelt die Löcher', (
    tester,
  ) async {
    // Loch nur an V1 (erste Position von vorne).
    final einLoch = _karte('b', ['x', '1', '1', '1', '1', '1']);
    await _zeige(tester, KartenWidget.verdeckt(einLoch));

    expect(
      _assets(tester),
      isEmpty,
      reason: 'kein einziges Wert-Tile — Werte bleiben verborgen (D9)',
    );

    // Gespiegelt liegt das Loch an letzter Stelle.
    final zellen = SlotZeile.fuerVerdeckteKarte(einLoch).zellen;
    expect(zellen.first.verdeckt, isTrue);
    expect(zellen.last.verdeckt, isFalse, reason: 'das Loch, jetzt hinten');
    expect(zellen.last.symbol, isA<Loch>());
    expect(zellen.length, 6);
  });

  testWidgets('Seltenheit bestimmt die Rahmenfarbe', (tester) async {
    expect(seltenheitsFarbe('einzigartig'), isNot(seltenheitsFarbe('haeufig')));
    expect(seltenheitsFarbe('episch'), isNot(seltenheitsFarbe('selten')));

    await _zeige(tester, KartenWidget.handkarte(_karte('c', ['0', '0', '0', '0', '0', '0'], seltenheit: 'episch')));
    final rahmen = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.border != null)
        .toList();
    expect(rahmen, isNotEmpty);
  });

  testWidgets('leeres Spielfeld ist kein Karton, sondern freier Platz', (
    tester,
  ) async {
    await _zeige(tester, StapelWidget(feld: const Spielfeld()));
    expect(find.text('leer'), findsOneWidget);
    expect(_assets(tester), isEmpty, reason: 'keine Karte, keine Symbole');
  });
}
