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

Finder _hinzufuegenKnopf() => find.widgetWithText(FilledButton, 'Zum Deck hinzufügen');

void main() {
  setUp(() => HydratedBloc.storage = SpeicherImArbeitsspeicher());

  Future<void> pumpScreen(WidgetTester tester, Kartenset kartenset) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: DeckbauScreen(kartenset: kartenset)));
    await tester.pump();
  }

  testWidgets('Zufällig füllen ergibt ein gültiges Deck, Speichern legt es ab', (tester) async {
    final kartenset = _kartenset();
    await pumpScreen(tester, kartenset);

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

  testWidgets('Erste Pool-Karte (r0) steht offen zum Durchblättern da, Knopf fügt sie hinzu', (
    tester,
  ) async {
    final kartenset = _kartenset();
    await pumpScreen(tester, kartenset);

    expect(find.text('0/35 Karten · 0/7 Evil'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is KartenWidget && w.karte?.id == 'r0'),
      findsOneWidget,
      reason: 'r0 ist die erste Karte im sortierten Pool und steht ohne Blättern da',
    );

    await tester.tap(_hinzufuegenKnopf());
    await tester.pump();

    expect(find.text('1/35 Karten · 0/7 Evil'), findsOneWidget);
  });

  testWidgets('Ziehen der aktuellen Pool-Karte auf den Deck-Stapel fügt sie hinzu', (tester) async {
    final kartenset = _kartenset();
    await pumpScreen(tester, kartenset);

    final r0 = find.byWidgetPredicate((w) => w is Draggable<Karte> && w.data?.id == 'r0');
    final deckStapel = find.byType(StapelWidget);
    expect(r0, findsOneWidget);
    expect(deckStapel, findsOneWidget);

    final geste = await tester.startGesture(tester.getCenter(r0));
    await tester.pump(const Duration(milliseconds: 50));
    await geste.moveTo(tester.getCenter(deckStapel));
    await tester.pump(const Duration(milliseconds: 50));
    await geste.up();
    await tester.pumpAndSettle();

    expect(find.text('1/35 Karten · 0/7 Evil'), findsOneWidget);
  });

  testWidgets('Deck antippen öffnet den Durchblättern-Dialog, X entfernt eine Karte', (tester) async {
    final kartenset = _kartenset();
    await pumpScreen(tester, kartenset);

    await tester.tap(_hinzufuegenKnopf());
    await tester.pump();
    expect(find.text('1/35 Karten · 0/7 Evil'), findsOneWidget);

    await tester.tap(find.byType(StapelWidget));
    await tester.pumpAndSettle();
    expect(find.text('Dein Deck (1)'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(find.text('Dein Deck (0)'), findsOneWidget);
    expect(find.text('0/35 Karten · 0/7 Evil'), findsOneWidget, reason: 'Entfernen wirkt auch auf den Hintergrund');
  });

  testWidgets('Evil-Karten lassen sich nicht doppelt hinzufügen (anzahlImDeckMax 1)', (tester) async {
    final kartenset = _kartenset();
    await pumpScreen(tester, kartenset);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Evil'));
    await tester.pumpAndSettle();

    expect(find.byWidgetPredicate((w) => w is KartenWidget && w.karte?.id == 'e0'), findsOneWidget);

    await tester.tap(_hinzufuegenKnopf());
    await tester.pump();
    expect(find.text('1/35 Karten · 1/7 Evil'), findsOneWidget);

    final knopf = tester.widget<FilledButton>(_hinzufuegenKnopf());
    expect(knopf.onPressed, isNull, reason: 'e0 steckt schon einmal im Deck, Max ist 1');
  });
}
