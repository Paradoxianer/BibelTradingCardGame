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

  group('kartenDarstellungFuerBildschirm', () {
    test('bleibt unter der Schwelle bei der bisherigen kompakten Ansicht', () {
      final schmal = kartenDarstellungFuerBildschirm(700);
      expect(schmal.ansicht, KartenAnsicht.kompakt);
      expect(schmal.breite, 120);
    });

    test('wechselt ab der Schwelle direkt auf die volle Kartenansicht', () {
      final breit = kartenDarstellungFuerBildschirm(1600);
      expect(breit.ansicht, KartenAnsicht.voll);
      expect(breit.breite, 320);
    });
  });

  testWidgets(
    'Feldkarten zeigen auf einem breiten Bildschirm die volle Ansicht mit Bibeltext',
    (tester) async {
      addTearDown(tester.view.reset);
      final bloc = _bloc(_kartenset());
      addTearDown(bloc.close);

      Future<KartenWidget> ersteFeldkarte(Size groesse) async {
        tester.view.physicalSize = groesse;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(value: bloc, child: SpielScreen(onNeuesSpiel: () {})),
          ),
        );
        await tester.pump();
        final karte = find
            .descendant(
              of: find.byKey(const ValueKey('eigenes-feld-0')),
              matching: find.byType(KartenWidget),
            )
            .first;
        return tester.widget<KartenWidget>(karte);
      }

      final schmal = await ersteFeldkarte(const Size(700, 1400));
      expect(schmal.ansicht, KartenAnsicht.kompakt);
      expect(schmal.breite, 120);

      final breit = await ersteFeldkarte(const Size(1600, 1400));
      expect(breit.ansicht, KartenAnsicht.voll);
      expect(breit.breite, 320);
    },
  );
}
