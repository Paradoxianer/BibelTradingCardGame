import 'package:btcg_app/ui/widgets/stapel_widget.dart';
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

void main() {
  testWidgets('ohne punkte-Angabe bleibt die Anzeige aus', (tester) async {
    final feld = Spielfeld([Kartenlage(_karte('a', ['2', '0', '0', '0', '0', '0']))]);
    await tester.pumpWidget(MaterialApp(home: StapelWidget(feld: feld)));
    expect(find.text('0'), findsNothing);
  });

  testWidgets('zeigt die aktuellen Punkte mit Vorzeichen und Farbe', (
    tester,
  ) async {
    final feld = Spielfeld([
      Kartenlage(_karte('e', ['-1', '-1', '-1', '-1', '-1', '-1'])),
    ]);
    await tester.pumpWidget(
      MaterialApp(home: StapelWidget(feld: feld, punkte: werteFeld(feld, 0).punkte)),
    );
    expect(find.text('-6'), findsOneWidget);
  });

  testWidgets(
    'Vorschau zeigt alten Wert, neuen Wert und die Differenz',
    (tester) async {
      // Unten zwei 2er, die verdeckt sind und daher nicht zählen.
      final feld = Spielfeld([
        Kartenlage(_karte('unten', ['2', '2', '0', '0', '0', '0'])),
      ]);
      expect(werteFeld(feld, 0).punkte, 0);

      // Karte mit Löchern darüber legt beide 2er frei -> 0 wird zu +4.
      final mitLoechern = _karte('oben', ['x', 'x', '0', '0', '0', '0']);

      await tester.pumpWidget(
        MaterialApp(
          home: StapelWidget(
            feld: feld,
            punkte: werteFeld(feld, 0).punkte,
            vorschauKarte: mitLoechern,
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget, reason: 'bisheriger Wert');
      expect(find.text('+4'), findsOneWidget, reason: 'Wert nach dem Ablegen');
      expect(find.text(' (+4)'), findsOneWidget, reason: 'Differenz');
    },
  );

  testWidgets('Vorschau zeigt auch eine Verschlechterung an', (tester) async {
    // EStart-artig: 6 schwarze Werte, -6 Punkte.
    final feld = Spielfeld([
      Kartenlage(_karte('e', ['-1', '-1', '-1', '-1', '-1', '-1'])),
    ]);
    // Karte ohne Löcher deckt alles zu -> -6 wird zu 0, also +6 Differenz.
    final deckel = _karte('d', ['0', '0', '0', '0', '0', '0']);

    await tester.pumpWidget(
      MaterialApp(
        home: StapelWidget(
          feld: feld,
          punkte: werteFeld(feld, 0).punkte,
          vorschauKarte: deckel,
        ),
      ),
    );

    expect(find.text('-6'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text(' (+6)'), findsOneWidget);
  });
}
