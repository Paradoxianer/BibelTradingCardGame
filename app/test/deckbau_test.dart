import 'package:btcg_app/data/deck_repository.dart';
import 'package:btcg_app/ui/screens/deckbau_screen.dart';
import 'package:btcg_app/ui/widgets/karten_widget.dart';
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

/// Findet die Karte mit [id] im Pool-Karussell (unten) — dort steht der
/// ganze wählbare Bestand, in Kategorie-Reihenfolge sortiert.
Finder _imPool(WidgetTester tester, String id) {
  final finder = find.descendant(
    of: find.byKey(const ValueKey('pool-karussell')),
    matching: find.byWidgetPredicate((w) => w is KartenWidget && w.karte?.id == id),
  );
  return finder;
}

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

  testWidgets('Karten im Pool antippen fügt sie dem Deck-Karussell hinzu; im Deck antippen entfernt sie', (
    tester,
  ) async {
    final kartenset = _kartenset();
    await tester.pumpWidget(MaterialApp(home: DeckbauScreen(kartenset: kartenset)));
    await tester.pump();

    expect(find.text('0/35 Karten · 0/7 Evil'), findsOneWidget);
    expect(find.text('Noch keine Karten im Deck.'), findsOneWidget);

    // r0 steht als erste Karte direkt sichtbar im Pool-Karussell.
    await tester.tap(_imPool(tester, 'r0'));
    await tester.pump();

    expect(find.text('1/35 Karten · 0/7 Evil'), findsOneWidget);
    expect(find.text('Noch keine Karten im Deck.'), findsNothing);

    // Dieselbe Karte steht jetzt auch im Deck-Karussell (oben) — antippen
    // dort entfernt sie wieder.
    final imDeck = find.descendant(
      of: find.byKey(const ValueKey('deck-karussell')),
      matching: find.byWidgetPredicate((w) => w is KartenWidget && w.karte?.id == 'r0'),
    );
    expect(imDeck, findsOneWidget);
    await tester.tap(imDeck);
    await tester.pump();

    expect(find.text('0/35 Karten · 0/7 Evil'), findsOneWidget);
  });

  testWidgets('Evil-Karten lassen sich nicht doppelt hinzufügen (anzahlImDeckMax 1)', (tester) async {
    final kartenset = _kartenset();
    await tester.pumpWidget(MaterialApp(home: DeckbauScreen(kartenset: kartenset)));
    await tester.pump();

    // e0 steht in der Evil-Sektion weit rechts im Pool-Karussell.
    final e0 = _imPool(tester, 'e0');
    await tester.dragUntilVisible(e0, find.byKey(const ValueKey('pool-karussell')), const Offset(-400, 0));

    await tester.tap(e0);
    await tester.pump();
    expect(find.text('1/35 Karten · 1/7 Evil'), findsOneWidget);

    // Nochmal tippen darf nichts ändern — Max für Evil-Karten ist 1, die
    // Karte ist jetzt abgeblendet und ohne onTap.
    await tester.tap(e0, warnIfMissed: false);
    await tester.pump();
    expect(find.text('1/35 Karten · 1/7 Evil'), findsOneWidget);
  });
}
