import 'package:btcg_app/data/deck_repository.dart';
import 'package:btcg_app/ui/screens/deckbau_screen.dart';
import 'package:btcg_app/ui/widgets/karten_widget.dart';
import 'package:btcg_engine/engine.dart';
import 'package:flutter/gestures.dart';
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

Karte _karteMitV1(String id, String v1Code) => Karte(
  id: id,
  cardId: id,
  name: id,
  vers: const Vers(stelle: 'X 1,1', text: ''),
  slots: [v1Code, '0', '0', '0', '0', '0'].map(SlotSymbol.parse).toList(),
  kategorie: Kategorie.gebet,
  seltenheit: 'haeufig',
  sofort: false,
  effekt: null,
  anzahlImDeckMax: 3,
  pictureLink: '',
);

Karte _karteMitSeltenheit(String id, String seltenheit) => Karte(
  id: id,
  cardId: id,
  name: id,
  vers: const Vers(stelle: 'X 1,1', text: ''),
  slots: ['0', '0', '0', '0', '0', '0'].map(SlotSymbol.parse).toList(),
  kategorie: Kategorie.gebet,
  seltenheit: seltenheit,
  sofort: false,
  effekt: null,
  anzahlImDeckMax: 3,
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

// FilledButton.tonalIcon/OutlinedButton.icon liefern private Unterklassen
// (_FilledButtonWithIcon/_OutlinedButtonWithIcon) — find.widgetWithText
// vergleicht exakt auf den Typ, deshalb hier über ButtonStyleButton (die
// gemeinsame Basisklasse, die auch onPressed trägt) suchen.
Finder _hinzufuegenKnopf() => find.ancestor(
  of: find.text('Zum Deck hinzufügen'),
  matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
);
Finder _entfernenKnopf() => find.ancestor(
  of: find.text('Aus dem Deck entfernen'),
  matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
);
final _deckZiel = find.byKey(const ValueKey('deck-dragtarget'));
final _poolZiel = find.byKey(const ValueKey('pool-dragtarget'));

/// Legt vor dem Pumpen ein neues, aktives Deck mit [karten] an — [anlegen]
/// setzt es automatisch als aktiv, `DeckbauScreen` lädt beim Start also
/// genau dieses Deck.
Future<void> _seedeAktivesDeck(List<Karte> karten) async {
  final id = await DeckRepository.anlegen('Testdeck');
  await DeckRepository.speichereKarten(id, karten);
}

void main() {
  setUp(() => HydratedBloc.storage = SpeicherImArbeitsspeicher());

  Future<void> pumpScreen(WidgetTester tester, Kartenset kartenset) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: DeckbauScreen(kartenset: kartenset)));
    await tester.pump();
  }

  Future<void> ziehen(WidgetTester tester, Finder quelle, Finder ziel) async {
    final geste = await tester.startGesture(tester.getCenter(quelle));
    // LongPressDraggable statt Draggable (damit ein Wisch weiterhin das
    // Karussell blättert statt eine Karte aufzuheben): erst nach
    // kLongPressTimeout beginnt der Zug.
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await geste.moveTo(tester.getCenter(ziel));
    await tester.pump(const Duration(milliseconds: 50));
    await geste.up();
    await tester.pumpAndSettle();
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

    final gespeichert = DeckRepository.ladeKarten(DeckRepository.aktiv(), kartenset.alleKarten);
    expect(gespeichert.length, 35);
    expect(gespeichert.where((k) => k.kategorie == Kategorie.evil).length, 7);
  });

  testWidgets('Knopf fügt die zentrierte Pool-Karte hinzu; Knopf entfernt die zentrierte Deck-Karte', (
    tester,
  ) async {
    final kartenset = _kartenset();
    await pumpScreen(tester, kartenset);

    expect(find.text('0/35 Karten · 0/7 Evil'), findsOneWidget);
    expect(find.text('Noch keine Karten im Deck.'), findsOneWidget);

    // r0 ist die erste (zentrierte) Karte im sortierten Pool.
    await tester.tap(_hinzufuegenKnopf());
    await tester.pump();

    expect(find.text('1/35 Karten · 0/7 Evil'), findsOneWidget);
    expect(find.text('Noch keine Karten im Deck.'), findsNothing);
    expect(_entfernenKnopf(), findsOneWidget);

    await tester.tap(_entfernenKnopf());
    await tester.pump();

    expect(find.text('0/35 Karten · 0/7 Evil'), findsOneWidget);
  });

  testWidgets('Ziehen der Pool-Karte auf das Deck-Ziel fügt sie hinzu', (tester) async {
    final kartenset = _kartenset();
    await pumpScreen(tester, kartenset);

    final r0 = find.byWidgetPredicate((w) => w is Draggable<Object?> && (w.data as dynamic)?.karte?.id == 'r0');
    expect(r0, findsOneWidget);

    await ziehen(tester, r0, _deckZiel);

    expect(find.text('1/35 Karten · 0/7 Evil'), findsOneWidget);
  });

  testWidgets('Ziehen der Deck-Karte auf das Pool-Ziel entfernt sie wieder', (tester) async {
    final kartenset = _kartenset();
    await pumpScreen(tester, kartenset);

    await tester.tap(_hinzufuegenKnopf());
    await tester.pump();
    expect(find.text('1/35 Karten · 0/7 Evil'), findsOneWidget);

    // r0 ist bis anzahlImDeckMax (3) weiterhin auch im Pool ziehbar — hier
    // gezielt die Deck-Instanz treffen, nicht die Pool-Instanz.
    final imDeck = find.byWidgetPredicate(
      (w) =>
          w is Draggable<Object?> &&
          (w.data as dynamic)?.karte?.id == 'r0' &&
          (w.data as dynamic)?.ausDeck == true,
    );
    expect(imDeck, findsOneWidget);

    await ziehen(tester, imDeck, _poolZiel);

    expect(find.text('0/35 Karten · 0/7 Evil'), findsOneWidget);
  });

  testWidgets('Ein waagerechter Wisch blättert das Pool-Karussell, statt eine Karte zu ziehen', (
    tester,
  ) async {
    final kartenset = _kartenset();
    await pumpScreen(tester, kartenset);

    final r0 = find.byWidgetPredicate((w) => w is Draggable<Object?> && (w.data as dynamic)?.karte?.id == 'r0');
    expect(r0, findsOneWidget);

    // LongPressDraggable lehnt sich aktiv ab, sobald sich der Finger vor
    // Ablauf der Wartezeit bewegt, und gibt die Geste an die PageView-
    // Wischgeste weiter — mit einem normalen Draggable (auch mit `axis`)
    // gewann dieser Wisch nie das Blättern.
    await tester.fling(r0, const Offset(-400, 0), 800);
    await tester.pumpAndSettle();

    // Nichts wurde gezogen: das Deck bleibt leer.
    expect(find.text('0/35 Karten · 0/7 Evil'), findsOneWidget);

    // Aber das Karussell hat geblättert: der Knopf fügt jetzt eine andere
    // Karte als r0 hinzu.
    await tester.tap(_hinzufuegenKnopf());
    await tester.pump();

    expect(find.text('1/35 Karten · 0/7 Evil'), findsOneWidget);
    final r0ImDeck = find.byWidgetPredicate(
      (w) =>
          w is Draggable<Object?> &&
          (w.data as dynamic)?.karte?.id == 'r0' &&
          (w.data as dynamic)?.ausDeck == true,
    );
    expect(r0ImDeck, findsNothing, reason: 'nach dem Wisch ist nicht mehr r0 zentriert');
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

    final knopf = tester.widget<ButtonStyleButton>(_hinzufuegenKnopf());
    expect(knopf.onPressed, isNull, reason: 'e0 steckt schon einmal im Deck, Max ist 1');
  });

  testWidgets('Sortiermenü ordnet den Pool nach dem gewählten Slot statt nach Name', (tester) async {
    final kartenset = Kartenset(
      set: 'TEST',
      version: '1.0.0',
      tabs: {
        'R_Test': [
          _karteMitV1('aaa_schwach', '-1'), // schlechtestes Symbol, aber alphabetisch zuerst
          _karteMitV1('bbb_null', '0'),
          _karteMitV1('ccc_stark', '2'),
          _karteMitV1('ddd_loch', 'x'), // bestes Symbol an V1, alphabetisch zuletzt
        ],
      },
    );
    await pumpScreen(tester, kartenset);

    expect(
      find.byWidgetPredicate((w) => w is KartenWidget && w.karte?.id == 'aaa_schwach'),
      findsOneWidget,
      reason: 'Standardsortierung ist Kategorie/Name',
    );

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    // warnIfMissed: false — PopupMenuButton positioniert seine Overlay-Items
    // in Tests knapp außerhalb der von getCenter() berechneten Trefferzone
    // (bekannte Flutter-Test-Eigenart), der Tap kommt trotzdem an.
    await tester.tap(find.text('Nach V1'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((w) => w is KartenWidget && w.karte?.id == 'ddd_loch'),
      findsOneWidget,
      reason: 'Ein Loch an V1 gilt als bestes Symbol und steht nach der Sortierung zentriert',
    );
    expect(find.byWidgetPredicate((w) => w is KartenWidget && w.karte?.id == 'aaa_schwach'), findsNothing);
  });

  testWidgets(
    'Deck-Kategorie-Filter zeigt nur Karten der gewählten Kategorie, unabhängig vom Pool-Filter',
    (tester) async {
      final kartenset = Kartenset(
        set: 'TEST',
        version: '1.0.0',
        tabs: {
          'R_Test': [
            _karte('g0', kategorie: Kategorie.gebet),
            _karte('gl0', kategorie: Kategorie.glauben),
          ],
        },
      );
      await _seedeAktivesDeck([kartenset.alleKarten[0], kartenset.alleKarten[1]]);
      await pumpScreen(tester, kartenset);

      expect(find.text('2/35 Karten · 0/7 Evil'), findsOneWidget);

      final deckFilterChip = find.descendant(
        of: find.byKey(const ValueKey('deck-filterrow')),
        matching: find.widgetWithText(ChoiceChip, 'Glauben'),
      );
      expect(deckFilterChip, findsOneWidget);
      await tester.tap(deckFilterChip);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('deck-dragtarget')),
          matching: find.byWidgetPredicate((w) => w is KartenWidget && w.karte?.id == 'gl0'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('deck-dragtarget')),
          matching: find.byWidgetPredicate((w) => w is KartenWidget && w.karte?.id == 'g0'),
        ),
        findsNothing,
        reason: 'g0 ist gebet, nicht glauben — nach dem Deck-Filter ausgeblendet',
      );

      // Der Pool-Filter bleibt unberührt: 'Alle' ist dort weiterhin gewählt.
      final poolAlleChip = tester.widget<ChoiceChip>(
        find.descendant(
          of: find.byKey(const ValueKey('pool-filterrow')),
          matching: find.widgetWithText(ChoiceChip, 'Alle'),
        ),
      );
      expect(poolAlleChip.selected, isTrue);
    },
  );

  testWidgets('Deck-Sortiermenü sortiert das Deck unabhängig vom Pool-Sortiermenü', (tester) async {
    final kartenset = Kartenset(
      set: 'TEST',
      version: '1.0.0',
      tabs: {
        'R_Test': [
          _karteMitV1('aaa_schwach', '-1'),
          _karteMitV1('bbb_null', '0'),
          _karteMitV1('ccc_stark', '2'),
          _karteMitV1('ddd_loch', 'x'),
        ],
      },
    );
    await _seedeAktivesDeck(kartenset.alleKarten);
    await pumpScreen(tester, kartenset);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('deck-dragtarget')),
        matching: find.byWidgetPredicate((w) => w is KartenWidget && w.karte?.id == 'aaa_schwach'),
      ),
      findsOneWidget,
      reason: 'Standardsortierung ist Kategorie/Name',
    );

    final deckSortIcon = find.descendant(
      of: find.byKey(const ValueKey('deck-filterrow')),
      matching: find.byIcon(Icons.sort),
    );
    await tester.tap(deckSortIcon);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nach V1'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('deck-dragtarget')),
        matching: find.byWidgetPredicate((w) => w is KartenWidget && w.karte?.id == 'ddd_loch'),
      ),
      findsOneWidget,
      reason: 'Ein Loch an V1 gilt als bestes Symbol und steht nach der Sortierung zentriert',
    );

    // Der Pool bleibt bei seiner eigenen (Standard-)Sortierung.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pool-dragtarget')),
        matching: find.byWidgetPredicate((w) => w is KartenWidget && w.karte?.id == 'aaa_schwach'),
      ),
      findsOneWidget,
      reason: 'Pool-Sortierung ist unverändert Kategorie/Name geblieben',
    );
  });

  testWidgets('Sortiermenü ordnet den Pool nach Seltenheit', (tester) async {
    final kartenset = Kartenset(
      set: 'TEST',
      version: '1.0.0',
      tabs: {
        'R_Test': [
          _karteMitSeltenheit('aaa_haeufig', 'haeufig'), // alphabetisch zuerst, aber am wenigsten selten
          _karteMitSeltenheit('bbb_selten', 'selten'),
          _karteMitSeltenheit('ccc_episch', 'episch'),
          _karteMitSeltenheit('ddd_einzigartig', 'einzigartig'), // alphabetisch zuletzt, aber am seltensten
        ],
      },
    );
    await pumpScreen(tester, kartenset);

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nach Seltenheit'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((w) => w is KartenWidget && w.karte?.id == 'ddd_einzigartig'),
      findsOneWidget,
      reason: 'einzigartig ist die höchste Seltenheitsstufe und steht nach der Sortierung zentriert',
    );
    expect(find.byWidgetPredicate((w) => w is KartenWidget && w.karte?.id == 'aaa_haeufig'), findsNothing);
  });

  final deckWechselMenu = find.byKey(const ValueKey('deck-wechsel-menu'));
  final umbenennenKnopf = find.widgetWithIcon(IconButton, Icons.edit_outlined);
  final loeschenKnopf = find.widgetWithIcon(IconButton, Icons.delete_outline);

  testWidgets('Neues Deck anlegen wechselt dorthin; das alte Deck bleibt mit seinen Karten erhalten', (
    tester,
  ) async {
    final kartenset = _kartenset();
    await pumpScreen(tester, kartenset);

    await tester.tap(_hinzufuegenKnopf());
    await tester.pump();
    expect(find.text('1/35 Karten · 0/7 Evil'), findsOneWidget);

    await tester.tap(deckWechselMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neues Deck…'), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Zweitdeck');
    await tester.tap(find.text('Anlegen'));
    await tester.pumpAndSettle();

    expect(find.text('Zweitdeck'), findsOneWidget, reason: 'AppBar-Titel zeigt den Namen des neuen Decks');
    expect(find.text('Noch keine Karten im Deck.'), findsOneWidget);
    expect(find.text('0/35 Karten · 0/7 Evil'), findsOneWidget);

    await tester.tap(deckWechselMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deck 1'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.text('1/35 Karten · 0/7 Evil'),
      findsOneWidget,
      reason: 'die Karte im ersten Deck wurde beim Wechsel automatisch mitgesichert',
    );
  });

  testWidgets(
    'Karte, die erst nach dem Wechsel zu einem Deck hinzugefügt wird, übersteht einen erneuten Wechsel weg und zurück',
    (tester) async {
      final kartenset = _kartenset();
      await pumpScreen(tester, kartenset);

      // Zweitdeck anlegen (noch ohne Karten) und dorthin wechseln.
      await tester.tap(deckWechselMenu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Neues Deck…'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Zweitdeck');
      await tester.tap(find.text('Anlegen'));
      await tester.pumpAndSettle();
      expect(find.text('Zweitdeck'), findsOneWidget);

      // Anders als im vorigen Test: die Karte kommt hier hinzu, NACHDEM
      // "Zweitdeck" schon aktiv ist (nicht im selben Zug wie das Anlegen) —
      // genau der Fall, in dem die zwischengespeicherte Deck-Liste beim
      // späteren Zurückwechseln veraltet sein könnte.
      await tester.tap(_hinzufuegenKnopf());
      await tester.pump();
      expect(find.text('1/35 Karten · 0/7 Evil'), findsOneWidget);

      await tester.tap(deckWechselMenu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deck 1'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Deck 1'), findsOneWidget);

      await tester.tap(deckWechselMenu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zweitdeck'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.text('1/35 Karten · 0/7 Evil'),
        findsOneWidget,
        reason: 'die vorher hinzugefügte Karte darf beim Zurückwechseln nicht verloren gehen',
      );
      expect(find.text('Noch keine Karten im Deck.'), findsNothing);
    },
  );

  testWidgets('Deck umbenennen ändert den Titel', (tester) async {
    final kartenset = _kartenset();
    await pumpScreen(tester, kartenset);

    expect(find.text('Deck 1'), findsOneWidget);

    await tester.tap(umbenennenKnopf);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mein Kampfdeck');
    await tester.tap(find.text('Umbenennen'));
    await tester.pumpAndSettle();

    expect(find.text('Mein Kampfdeck'), findsOneWidget);
    expect(find.text('Deck 1'), findsNothing);
  });

  testWidgets('Deck löschen ist nur mit mehr als einem Deck möglich; wechselt danach zum verbleibenden', (
    tester,
  ) async {
    final kartenset = _kartenset();
    await pumpScreen(tester, kartenset);

    // Nur ein Deck vorhanden: der Löschen-Knopf ist deaktiviert.
    var loeschenButton = tester.widget<IconButton>(loeschenKnopf);
    expect(loeschenButton.onPressed, isNull);

    await tester.tap(deckWechselMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neues Deck…'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Zweitdeck');
    await tester.tap(find.text('Anlegen'));
    await tester.pumpAndSettle();

    expect(find.text('Zweitdeck'), findsOneWidget);
    loeschenButton = tester.widget<IconButton>(loeschenKnopf);
    expect(loeschenButton.onPressed, isNotNull, reason: 'jetzt gibt es zwei Decks');

    await tester.tap(loeschenKnopf);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();

    expect(find.text('Deck 1'), findsOneWidget, reason: 'nach dem Löschen ist das verbleibende Deck aktiv');
    expect(find.text('Zweitdeck'), findsNothing);
  });
}
