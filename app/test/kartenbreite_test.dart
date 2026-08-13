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

  group('feldBreiteFuerBildschirm', () {
    test('bleibt auf Handy-Breiten bei der bisherigen kompakten Größe', () {
      expect(feldBreiteFuerBildschirm(360), 120);
      expect(feldBreiteFuerBildschirm(600), 120);
    });

    test('wächst zwischen 600 und 1100 Richtung echter Kartengröße', () {
      final mitte = feldBreiteFuerBildschirm(850);
      expect(mitte, greaterThan(120));
      expect(mitte, lessThan(180));
    });

    test('erreicht ab 1100 die volle Zielgröße und wächst nicht weiter', () {
      expect(feldBreiteFuerBildschirm(1100), 180);
      expect(feldBreiteFuerBildschirm(2000), 180);
    });
  });

  testWidgets(
    'Feldkarten sind auf einem breiten Bildschirm größer als auf einem schmalen',
    (tester) async {
      addTearDown(tester.view.reset);
      final bloc = _bloc(_kartenset());
      addTearDown(bloc.close);

      Future<double> breiteDerErstenFeldkarte(Size groesse) async {
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
        return tester.getSize(karte).width;
      }

      // 400px ist schmaler, als die Feldreihe selbst bei kompakter
      // Kartengröße braucht — das ist ein vorbestehendes Layout-Problem für
      // sehr schmale Bildschirme (nicht Gegenstand dieses Features) und
      // würde hier nur einen Overflow im Testbaum auslösen. 700px ist knapp
      // über der kompakten Schwelle (600) und bleibt overflow-frei.
      final schmal = await breiteDerErstenFeldkarte(const Size(700, 1400));
      final breit = await breiteDerErstenFeldkarte(const Size(1600, 1400));

      expect(breit, 180);
      expect(schmal, greaterThanOrEqualTo(120));
      expect(schmal, lessThan(breit));
    },
  );
}
