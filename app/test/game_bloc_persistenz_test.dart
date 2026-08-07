import 'package:btcg_app/bloc/game_bloc.dart';
import 'package:btcg_app/bloc/game_event.dart';
import 'package:btcg_engine/engine.dart';
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

Kartenset _kartenset() {
  final ressourcen = [
    for (var i = 0; i < 20; i++) _karte('r$i', ['x', '1', 'x', '1', 'x', '1']),
  ];
  final evil = [
    for (var i = 0; i < 7; i++)
      _karte(
        'e$i',
        ['-1', '-1', '-1', '-1', '-1', '-1'],
        kategorie: Kategorie.evil,
        anzahlImDeckMax: 1,
      ),
  ];
  final start = _karte('estart', [
    '-1',
    '-1',
    '-1',
    '-1',
    '-1',
    '-1',
  ], kategorie: Kategorie.start);
  return Kartenset(
    set: 'TEST',
    version: '1.0.0',
    tabs: {'R_Test': [...ressourcen, ...evil, start]},
  );
}

void main() {
  late SpeicherImArbeitsspeicher storage;

  setUp(() {
    storage = SpeicherImArbeitsspeicher();
    HydratedBloc.storage = storage;
  });

  test('Spielstand wird gespeichert und nach "Neustart" identisch wiederhergestellt', () async {
    final kartenset = _kartenset();
    final aufbau = [
      baueZufaelligesDeck(id: 'p1', name: 'p1', alleKarten: kartenset.alleKarten, seed: 1),
      baueZufaelligesDeck(id: 'p2', name: 'p2', alleKarten: kartenset.alleKarten, seed: 2),
    ];

    final bloc1 = GameBloc(kartenset: kartenset, aufbauListe: aufbau, seed: 5);
    addTearDown(bloc1.close);

    final karte = bloc1.state.spiel.aktiverSpieler.hand.first;
    bloc1.add(HandkarteAngetippt(karte));
    await bloc1.stream.first;
    bloc1.add(const FeldAngetippt(0));
    await bloc1.stream.first;
    bloc1.add(const PassenAngetippt());
    await bloc1.stream.first;

    final vorZustand = bloc1.state.spiel;
    expect(storage.read('GameBloc'), isNotNull, reason: 'sollte nach jedem Zug speichern');

    // "App neu gestartet": neuer Bloc mit ANDEREN Fallback-Werten — wenn
    // die Hydration funktioniert, werden diese Fallbacks verworfen.
    final andereAufbau = [
      baueZufaelligesDeck(id: 'p1', name: 'p1', alleKarten: kartenset.alleKarten, seed: 111),
      baueZufaelligesDeck(id: 'p2', name: 'p2', alleKarten: kartenset.alleKarten, seed: 222),
    ];
    final bloc2 = GameBloc(kartenset: kartenset, aufbauListe: andereAufbau, seed: 999);
    addTearDown(bloc2.close);

    final nachZustand = bloc2.state.spiel;
    expect(
      nachZustand.spieler.map((s) => s.heiligkeit).toList(),
      vorZustand.spieler.map((s) => s.heiligkeit).toList(),
    );
    expect(nachZustand.aktiverIndex, vorZustand.aktiverIndex);
    expect(nachZustand.zugNummer, vorZustand.zugNummer);
    expect(
      nachZustand.spieler[0].spielfelder[0].stapel.map((k) => k.karte.id),
      vorZustand.spieler[0].spielfelder[0].stapel.map((k) => k.karte.id),
    );
  });

  test('beendete Partie wird aus dem Speicher gelöscht', () async {
    // Eigenes, kleineres Kartenset: Ressourcenkarten mit hohem Farbwert und
    // Löchern lassen die Heiligkeit schnell steigen, damit die Partie
    // innerhalb des Testlimits über D2 (Deck leer) oder Sieg endet — reines
    // Passen jede Runde würde nie enden (Hand bleibt voll, Deck leert sich
    // nie, siehe engine/test/property_test.dart für dasselbe Muster).
    final kartenset = Kartenset(
      set: 'TEST',
      version: '1.0.0',
      tabs: {
        'R_Test': [
          for (var i = 0; i < 20; i++) _karte('r$i', ['x', '2', 'x', '2', 'x', '2']),
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
    final aufbau = [
      baueZufaelligesDeck(id: 'p1', name: 'p1', alleKarten: kartenset.alleKarten, seed: 1),
      baueZufaelligesDeck(id: 'p2', name: 'p2', alleKarten: kartenset.alleKarten, seed: 2),
    ];
    final bloc = GameBloc(kartenset: kartenset, aufbauListe: aufbau, seed: 5);
    addTearDown(bloc.close);

    // Immer die erste Nicht-Evil-Handkarte auf Feld 0 bauen, Evil überspringen.
    for (var i = 0; i < 300 && bloc.state.spiel.spielLaeuft; i++) {
      final hand = bloc.state.spiel.aktiverSpieler.hand;
      final spielbar = hand.where((k) => k.kategorie != Kategorie.evil);
      if (spielbar.isNotEmpty) {
        bloc.add(HandkarteAngetippt(spielbar.first));
        await bloc.stream.first;
        bloc.add(const FeldAngetippt(0));
        await bloc.stream.first;
      } else {
        bloc.add(const PassenAngetippt());
        await bloc.stream.first;
      }
      if (i == 0) expect(storage.read('GameBloc'), isNotNull);
      if (!bloc.state.spiel.spielLaeuft) break;
      if (bloc.state.spiel.phase == ZugPhase.evilSpielen) {
        final aktiver = bloc.state.spiel.aktiverSpieler;
        final evilKarte = aktiver.hand.where((k) => k.kategorie == Kategorie.evil).firstOrNull;
        final andererSpieler = bloc.state.spiel.spieler.firstWhere((s) => s.id != aktiver.id);
        final zielLegal =
            bloc.state.spiel.rundeNummer > 1 &&
            !bloc.state.spiel.evilEmpfangenDieseRunde.contains(andererSpieler.id);
        if (evilKarte != null && zielLegal) {
          // Evil loswerden, sonst verstopft es dauerhaft die Hand (dasselbe
          // Muster wie bei DefensivBot, siehe docs/SIMULATION_PHASE1B.md).
          bloc.add(HandkarteAngetippt(evilKarte));
          await bloc.stream.first;
          bloc.add(EvilZielAngetippt(spielerId: andererSpieler.id, feldIndex: 0));
          await bloc.stream.first;
        } else {
          bloc.add(const PassenAngetippt());
          await bloc.stream.first;
        }
      }
    }

    expect(bloc.state.spiel.spielLaeuft, isFalse);
    expect(storage.read('GameBloc'), isNull);
  });
}
