import 'package:btcg_app/data/deck_repository.dart';
import 'package:btcg_app/ui/screens/deckbau_screen.dart';
import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'test_storage.dart';

Karte _karte(String id, {Kategorie kategorie = Kategorie.gebet, int max = 3}) => Karte(
  id: id,
  cardId: id,
  name: id,
  vers: const Vers(stelle: 'X 1,1', text: ''),
  slots: ['0', '0', '0', '0', '0', '0'].map(SlotSymbol.parse).toList(),
  kategorie: kategorie,
  seltenheit: 'haeufig',
  sofort: false,
  effekt: null,
  anzahlImDeckMax: max,
  pictureLink: '',
);

Kartenset _kartenset() => Kartenset(
  set: 'TEST',
  version: '1.0.0',
  tabs: {
    'R_Test': [
      for (var i = 0; i < 30; i++) _karte('r$i'),
      for (var i = 0; i < 7; i++) _karte('e$i', kategorie: Kategorie.evil, max: 1),
      _karte('estart', kategorie: Kategorie.start),
    ],
  },
);

void main() {
  setUp(() => HydratedBloc.storage = SpeicherImArbeitsspeicher());

  testWidgets('Zufällig füllen ergibt ein gültiges Deck, Speichern legt es ab', (tester) async {
    final kartenset = _kartenset();
    await tester.pumpWidget(MaterialApp(home: DeckbauScreen(kartenset: kartenset)));
    await tester.pump();

    expect(find.text('Deck ist gültig.'), findsNothing);

    await tester.tap(find.text('Zufällig füllen'));
    await tester.pump();

    expect(find.text('35/35 Karten · 7/7 Evil'), findsOneWidget);
    expect(find.text('Deck ist gültig.'), findsOneWidget);

    await tester.tap(find.text('Speichern'));
    await tester.pump();

    final gespeichert = DeckRepository.lade(kartenset.alleKarten);
    expect(gespeichert.length, 35);
    expect(gespeichert.where((k) => k.kategorie == Kategorie.evil).length, 7);
  });

  testWidgets('Karten einzeln hinzufügen und wieder entfernen', (tester) async {
    final kartenset = _kartenset();
    await tester.pumpWidget(MaterialApp(home: DeckbauScreen(kartenset: kartenset)));
    await tester.pump();

    expect(find.text('0/35 Karten · 0/7 Evil'), findsOneWidget);

    final r0Zeile = find.widgetWithText(ListTile, 'r0');
    await tester.tap(find.descendant(of: r0Zeile, matching: find.byIcon(Icons.add_circle_outline)));
    await tester.pump();

    expect(find.text('1/35 Karten · 0/7 Evil'), findsOneWidget);

    await tester.tap(find.descendant(of: r0Zeile, matching: find.byIcon(Icons.remove_circle_outline)));
    await tester.pump();

    expect(find.text('0/35 Karten · 0/7 Evil'), findsOneWidget);
  });

  testWidgets('Evil-Karten lassen sich nicht doppelt hinzufügen (anzahlImDeckMax 1)', (tester) async {
    final kartenset = _kartenset();
    await tester.pumpWidget(MaterialApp(home: DeckbauScreen(kartenset: kartenset)));
    await tester.pump();

    final e0Zeile = find.widgetWithText(ListTile, 'e0');
    // e0 steht in der Evil-Sektion weit unten in der Liste — erst hinscrollen.
    await tester.dragUntilVisible(e0Zeile, find.byType(ListView), const Offset(0, -400));
    final plus = find.descendant(of: e0Zeile, matching: find.byIcon(Icons.add_circle_outline));
    await tester.tap(plus);
    await tester.pump();

    expect(find.text('1/35 Karten · 1/7 Evil'), findsOneWidget);

    // Nochmal tippen darf nichts ändern — Max für Evil-Karten ist 1.
    await tester.tap(plus);
    await tester.pump();
    expect(find.text('1/35 Karten · 1/7 Evil'), findsOneWidget);
  });
}
