import 'package:btcg_app/bloc/game_bloc.dart';
import 'package:btcg_app/ui/screens/spiel_screen.dart';
import 'package:btcg_app/ui/widgets/karten_widget.dart';
import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'test_storage.dart';

Karte _karte(String id, List<String> slots, {Kategorie kategorie = Kategorie.gebet, int max = 3}) => Karte(
  id: id,
  cardId: id,
  name: id,
  vers: const Vers(stelle: '', text: ''),
  slots: slots.map(SlotSymbol.parse).toList(),
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
      for (var i = 0; i < 20; i++) _karte('r$i', ['x', '1', 'x', '1', 'x', '1']),
      for (var i = 0; i < 7; i++)
        _karte('e$i', ['-1', '-1', '-1', '-1', '-1', '-1'], kategorie: Kategorie.evil, max: 1),
      _karte('estart', ['-1', '-1', '-1', '-1', '-1', '-1'], kategorie: Kategorie.start),
    ],
  },
);

GameBloc _bloc(Kartenset kartenset) => GameBloc(
  kartenset: kartenset,
  aufbauListe: [
    baueZufaelligesDeck(id: 'p1', name: 'p1', alleKarten: kartenset.alleKarten, seed: 1),
    baueZufaelligesDeck(id: 'p2', name: 'p2', alleKarten: kartenset.alleKarten, seed: 2),
  ],
  seed: 5,
);

void main() {
  setUp(() => HydratedBloc.storage = SpeicherImArbeitsspeicher());

  group('kartenDarstellungFuer', () {
    test('Hochformat (Handy): kompakte Mini-Karten', () {
      expect(kartenDarstellungFuer(const Size(390, 720)).ansicht, KartenAnsicht.kompakt);
    });

    test('Querformat (Desktop): volle Karten', () {
      expect(kartenDarstellungFuer(const Size(1920, 834)).ansicht, KartenAnsicht.voll);
    });

    test('Karten skalieren mit der Fläche', () {
      final klein = kartenDarstellungFuer(const Size(1920, 834));
      final gross = kartenDarstellungFuer(const Size(2560, 1300));
      expect(gross.breite, greaterThan(klein.breite));

      final handyKlein = kartenDarstellungFuer(const Size(360, 640));
      final handyGross = kartenDarstellungFuer(const Size(430, 860));
      expect(handyGross.breite, greaterThan(handyKlein.breite));
    });

    test('drei Kartenreihen passen in die Höhe', () {
      const flaeche = Size(1920, 834);
      final d = kartenDarstellungFuer(flaeche);
      expect(3 * KartenWidget.hoeheFuer(d.breite, d.ansicht), lessThan(flaeche.height));
    });

    test('ein viertes Feld (Gebietserweiterung) verkleinert die Karten in der Breite', () {
      const flaeche = Size(400, 800);
      expect(
        kartenDarstellungFuer(flaeche, felder: 4).breite,
        lessThan(kartenDarstellungFuer(flaeche).breite),
      );
    });

    test('Großansicht per Doppeltipp lohnt nur, solange die Karte kleiner ist', () {
      expect(grossansichtLohnt(KartenAnsicht.kompakt, 400), isTrue);
      expect(grossansichtLohnt(KartenAnsicht.voll, 150), isTrue);
      expect(grossansichtLohnt(KartenAnsicht.voll, kGrossansichtBreite), isFalse);
    });
  });

  for (final (groesse, erwartet) in [
    (const Size(1920, 953), KartenAnsicht.voll), // Fenster, in dem die Hand verschwand
    (const Size(2560, 1440), KartenAnsicht.voll),
    (const Size(400, 850), KartenAnsicht.kompakt), // Handy hochkant
  ]) {
    testWidgets('Regression: auf ${groesse.width.toInt()}×${groesse.height.toInt()} passt das ganze Brett '
        'samt eigener Hand ohne Scrollen (${erwartet.name})', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = groesse;
      tester.view.devicePixelRatio = 1.0;
      final bloc = _bloc(_kartenset());
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(home: BlocProvider.value(value: bloc, child: SpielScreen(onNeuesSpiel: () {}))),
      );
      await tester.pump();

      final feldkarte = tester.widget<KartenWidget>(
        find
            .descendant(of: find.byKey(const ValueKey('eigenes-feld-0')), matching: find.byType(KartenWidget))
            .first,
      );
      expect(feldkarte.ansicht, erwartet);

      final brett = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.vertical,
      );
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: brett, matching: find.byType(Scrollable)).first,
      );
      expect(scrollable.position.maxScrollExtent, 0, reason: 'nichts darf unter den Rand rutschen');
    });
  }
}
