import 'package:btcg_app/bloc/game_bloc.dart';
import 'package:btcg_app/ui/screens/spiel_screen.dart';
import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'test_storage.dart';

Karte _karte(
  String id,
  List<String> slots, {
  Kategorie kategorie = Kategorie.gebet,
  int anzahlImDeckMax = 3,
}) => Karte(
  id: id,
  cardId: id,
  name: id,
  vers: const Vers(stelle: 'Test 1,1', text: 'Testvers'),
  slots: slots.map(SlotSymbol.parse).toList(),
  kategorie: kategorie,
  seltenheit: 'haeufig',
  sofort: false,
  effekt: null,
  anzahlImDeckMax: anzahlImDeckMax,
  pictureLink: '',
);

/// Ressourcenkarten mit Löchern an V1/S1/HG1, EStart mit sechs schwarzen
/// Werten — so lässt sich das Freilegen gut nachrechnen.
Kartenset _kartenset() => Kartenset(
  set: 'TEST',
  version: '1.0.0',
  tabs: {
    'R_Test': [
      for (var i = 0; i < 20; i++) _karte('r$i', ['x', '1', 'x', '1', 'x', '1']),
      for (var i = 0; i < 7; i++)
        _karte(
          'e$i',
          ['-1', '-1', '-1', '-1', '-1', '-1'],
          kategorie: Kategorie.evil,
          anzahlImDeckMax: 1,
        ),
      _karte('estart', [
        '-1',
        '-1',
        '-1',
        '-1',
        '-1',
        '-1',
      ], kategorie: Kategorie.start),
    ],
  },
);

GameBloc _bloc(Kartenset kartenset) => GameBloc(
  kartenset: kartenset,
  aufbauListe: [
    baueZufaelligesDeck(
      id: 'p1',
      name: 'p1',
      alleKarten: kartenset.alleKarten,
      seed: 1,
    ),
    baueZufaelligesDeck(
      id: 'p2',
      name: 'p2',
      alleKarten: kartenset.alleKarten,
      seed: 2,
    ),
  ],
  seed: 5,
);

void main() {
  setUp(() => HydratedBloc.storage = SpeicherImArbeitsspeicher());

  testWidgets(
    'Karte über einem Feld halten zeigt die Punkte-Vorschau; Loslassen legt sie ab',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final bloc = _bloc(_kartenset());
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: SpielScreen(onNeuesSpiel: () {}),
          ),
        ),
      );
      await tester.pump();

      final feld = bloc.state.spiel.aktiverSpieler.spielfelder[0];
      expect(werteFeld(feld, 0).punkte, -6, reason: 'EStart: sechs mal -1');

      // Karte greifen und über dem eigenen Feld halten (noch nicht loslassen).
      final geste = await tester.startGesture(
        tester.getCenter(find.byType(Draggable<Karte>).first),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await geste.moveTo(
        tester.getCenter(find.byKey(const ValueKey('eigenes-feld-0'))),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Drei Löcher legen drei der schwarzen Werte frei: -6 wird zu -3.
      // Angezeigt wird nur vorher -> nachher, ohne Differenz.
      expect(find.textContaining('→'), findsOneWidget);
      expect(find.textContaining('-6'), findsWidgets);
      expect(find.textContaining('-3'), findsWidgets);
      expect(find.textContaining('(+'), findsNothing);

      await geste.up();
      await tester.pump();
      await tester.pump();

      expect(
        bloc.state.spiel.aktiverSpieler.spielfelder[0].stapel.length,
        2,
        reason: 'nach dem Loslassen liegt die Karte auf dem Feld',
      );
      expect(
        find.textContaining('→'),
        findsNothing,
        reason: 'Vorschau verschwindet nach dem Ablegen',
      );
    },
  );
}
