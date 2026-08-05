import 'package:btcg_engine/engine.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'game_event.dart';
import 'game_ui_state.dart';

/// Übersetzt UI-Intents in Engine-[Command]s und Engine-[GameEvent]s zurück
/// in UI-Zustand (ARCHITEKTUR §3). Enthält selbst keine Spielregeln — jede
/// Legalitätsprüfung passiert in [GameEngine].
class GameBloc extends Bloc<GameUiEvent, GameUiState> {
  final GameEngine _engine = GameEngine();

  GameBloc({required GameState anfangszustand, required Kartenset kartenset})
    : super(GameUiState(spiel: anfangszustand, kartenset: kartenset)) {
    on<HandkarteAngetippt>(_aufHandkarteAngetippt);
    on<FeldAngetippt>(_aufFeldAngetippt);
    on<EvilZielAngetippt>(_aufEvilZielAngetippt);
    on<PassenAngetippt>(_aufPassenAngetippt);
    on<ReaktionskarteAngetippt>(_aufReaktionskarteAngetippt);
    on<UebergabeBestaetigt>(_aufUebergabeBestaetigt);
  }

  void _anwenden(Emitter<GameUiState> emit, Command command) {
    try {
      final (neu, events) = _engine.apply(state.spiel, command);
      final zugWurdeBeendet = events.any((e) => e is ZugBeendet);
      final wertung = events.whereType<WertungBerechnet>().lastOrNull?.wertung;
      emit(
        state.copyWith(
          spiel: neu,
          letzteEvents: events,
          letzteWertung: wertung ?? state.letzteWertung,
          zeigtUebergabe: zugWurdeBeendet && neu.spielLaeuft,
          ausgewaehlteHandkarte: null,
          fehler: null,
        ),
      );
    } on RegelVerstoss catch (e) {
      emit(state.copyWith(fehler: e.nachricht));
    }
  }

  void _aufHandkarteAngetippt(
    HandkarteAngetippt event,
    Emitter<GameUiState> emit,
  ) {
    final istEvilPhase = state.spiel.phase == ZugPhase.evilSpielen;
    final istBauenPhase = state.spiel.phase == ZugPhase.bauen;
    final istEvilKarte = event.karte.kategorie == Kategorie.evil;
    if ((istBauenPhase && !istEvilKarte) || (istEvilPhase && istEvilKarte)) {
      emit(state.copyWith(ausgewaehlteHandkarte: event.karte));
    }
  }

  void _aufFeldAngetippt(FeldAngetippt event, Emitter<GameUiState> emit) {
    final karte = state.ausgewaehlteHandkarte;
    if (karte == null || state.spiel.phase != ZugPhase.bauen) return;
    _anwenden(emit, KarteBauen(feldIndex: event.feldIndex, karteId: karte.id));
  }

  void _aufEvilZielAngetippt(
    EvilZielAngetippt event,
    Emitter<GameUiState> emit,
  ) {
    final karte = state.ausgewaehlteHandkarte;
    if (karte == null || state.spiel.phase != ZugPhase.evilSpielen) return;
    _anwenden(
      emit,
      EvilSpielen(
        zielSpielerId: event.spielerId,
        zielFeldIndex: event.feldIndex,
        karteId: karte.id,
      ),
    );
  }

  void _aufPassenAngetippt(PassenAngetippt event, Emitter<GameUiState> emit) {
    _anwenden(emit, const Passen());
  }

  void _aufReaktionskarteAngetippt(
    ReaktionskarteAngetippt event,
    Emitter<GameUiState> emit,
  ) {
    _anwenden(emit, SofortReagieren(karteId: event.karte.id));
  }

  void _aufUebergabeBestaetigt(
    UebergabeBestaetigt event,
    Emitter<GameUiState> emit,
  ) {
    emit(state.copyWith(zeigtUebergabe: false));
  }
}
