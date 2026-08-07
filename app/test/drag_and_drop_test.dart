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
  vers: const Vers(stelle: '', text: ''),
  slots: slots.map(SlotSymbol.parse).toList(),
  kategorie: kategorie,
  seltenheit: 'haeufig',
  sofort: false,
  effekt: null,
  anzahlImDeckMax: anzahlImDeckMax,
  pictureLink: '',
);

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

  testWidgets('Handkarte per Drag auf ein eigenes Feld ziehen baut sie dort', (
    tester,
  ) async {
    // Grosse Surface, damit Hand und Felder gleichzeitig sichtbar sind.
    tester.view.physicalSize = const Size(1600, 1200);
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

    expect(bloc.state.spiel.phase, ZugPhase.bauen);
    final vorherStapel = bloc.state.spiel.aktiverSpieler.spielfelder[0].stapel.length;

    // Erste spielbare Handkarte greifen und auf das erste Feld ziehen.
    final handkarte = find.byType(Draggable<Karte>).first;
    final ziel = find.byKey(const ValueKey('eigenes-feld-0'));
    final geste = await tester.startGesture(tester.getCenter(handkarte));
    await tester.pump(const Duration(milliseconds: 100));
    await geste.moveTo(tester.getCenter(ziel));
    await tester.pump(const Duration(milliseconds: 100));
    await geste.up();
    await tester.pump();
    await tester.pump();

    expect(
      bloc.state.spiel.aktiverSpieler.spielfelder[0].stapel.length,
      vorherStapel + 1,
      reason: 'Drag&Drop legt die Karte auf das Feld',
    );
  });

  testWidgets('Antippen funktioniert weiterhin parallel zum Ziehen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
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

    final vorher = bloc.state.spiel.aktiverSpieler.spielfelder[0].stapel.length;
    await tester.tap(find.byType(Draggable<Karte>).first);
    await tester.pump();
    expect(bloc.state.ausgewaehlteHandkarte, isNotNull);

    await tester.tap(find.byKey(const ValueKey('eigenes-feld-0')));
    await tester.pump();
    expect(
      bloc.state.spiel.aktiverSpieler.spielfelder[0].stapel.length,
      vorher + 1,
    );
  });
}
