import 'package:btcg_app/ui/widgets/karten_widget.dart';
import 'package:btcg_app/ui/widgets/slot_symbole.dart';
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

/// Die tatsächlich gezeichneten Slot-Zellen aus dem Widgetbaum.
List<SlotAnzeige> _gezeichnet(WidgetTester tester) =>
    tester.widget<SlotSymbole>(find.byType(SlotSymbole)).zellen;

Future<void> _zeige(WidgetTester tester, Widget w) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: w))));
}

void main() {
  final karte = _karte('a', ['x', '1', '-1', '0', '2', '0']);

  testWidgets('kompakt und voll zeichnen dieselben sechs Zellen', (
    tester,
  ) async {
    await _zeige(tester, KartenWidget.handkarte(karte));
    final kompakt = _gezeichnet(tester);

    await _zeige(
      tester,
      KartenWidget.handkarte(karte, ansicht: KartenAnsicht.voll, breite: 320),
    );
    final voll = _gezeichnet(tester);

    expect(kompakt.length, 6);
    expect(
      kompakt.map((z) => (z.pos, z.symbol, z.verdeckt)),
      voll.map((z) => (z.pos, z.symbol, z.verdeckt)),
      reason: 'gleiche Karte, gleiche Symbole — nur anders angeordnet',
    );
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
    // Loch nur an V1 (vorne).
    final einLoch = _karte('b', ['x', '1', '1', '1', '1', '1']);
    await _zeige(tester, KartenWidget.verdeckt(einLoch));

    final zellen = _gezeichnet(tester);
    expect(zellen.length, 6);
    expect(
      zellen.where((z) => !z.verdeckt).map((z) => z.symbol),
      everyElement(isA<Loch>()),
      reason: 'sichtbar sind ausschließlich Löcher (D9)',
    );
    expect(zellen.last.symbol, isA<Loch>(), reason: 'gespiegelt nach hinten');
  });

  testWidgets('Seltenheit bestimmt die Rahmenfarbe', (tester) async {
    expect(seltenheitsFarbe('einzigartig'), isNot(seltenheitsFarbe('haeufig')));
    expect(seltenheitsFarbe('episch'), isNot(seltenheitsFarbe('selten')));

    await _zeige(
      tester,
      KartenWidget.handkarte(
        _karte('c', ['0', '0', '0', '0', '0', '0'], seltenheit: 'episch'),
      ),
    );
    final rahmen = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => d.decoration)
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
    expect(find.byType(SlotSymbole), findsNothing, reason: 'keine Karte');
  });

  testWidgets('Stapel zeichnet jede Karte, damit Löcher echt durchscheinen', (
    tester,
  ) async {
    final unten = _karte('unten', ['2', '2', '2', '2', '2', '2']);
    final oben = _karte('oben', ['x', '0', '0', '0', '0', '0']);
    await _zeige(
      tester,
      StapelWidget(feld: Spielfeld([Kartenlage(oben), Kartenlage(unten)])),
    );

    expect(
      find.byType(SlotSymbole),
      findsNWidgets(2),
      reason: 'beide Karten werden gezeichnet, nicht nur die oberste',
    );
  });
}
