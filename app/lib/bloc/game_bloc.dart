import 'package:btcg_engine/bots/bots.dart';
import 'package:btcg_engine/engine.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'game_event.dart';
import 'game_ui_state.dart';

/// Übersetzt UI-Intents in Engine-[Command]s und Engine-[GameEvent]s zurück
/// in UI-Zustand (ARCHITEKTUR §3). Enthält selbst keine Spielregeln — jede
/// Legalitätsprüfung passiert in [GameEngine].
///
/// [botSpieler] ordnet Spieler-IDs Bot-Strategien zu (leer = reines Hotseat).
/// Ist ein Bot am Zug (Bauen/Evil/Reaktion), spielt [GameBloc] ihn
/// automatisch weiter, bis wieder ein Mensch entscheiden muss oder die
/// Partie endet — dafür gibt es keinen eigenen Übergabe-Screen.
class GameBloc extends Bloc<GameUiEvent, GameUiState> {
  final GameEngine _engine = GameEngine();
  final Map<String, Bot> _botSpieler;
  SeedableRng _botRng;

  GameBloc({
    required GameState anfangszustand,
    required Kartenset kartenset,
    Map<String, Bot> botSpieler = const {},
    int botSeed = 0,
  }) : _botSpieler = botSpieler,
       _botRng = SeedableRng.seeded(botSeed),
       super(GameUiState(spiel: anfangszustand, kartenset: kartenset)) {
    on<HandkarteAngetippt>(_aufHandkarteAngetippt);
    on<FeldAngetippt>(_aufFeldAngetippt);
    on<EvilZielAngetippt>(_aufEvilZielAngetippt);
    on<PassenAngetippt>(_aufPassenAngetippt);
    on<ReaktionskarteAngetippt>(_aufReaktionskarteAngetippt);
    on<UebergabeBestaetigt>(_aufUebergabeBestaetigt);
    on<BotZugAusloesen>(_aufBotZugAusloesen);
    add(const BotZugAusloesen());
  }

  String _verantwortlicherId(GameState s) =>
      s.phase == ZugPhase.reaktion ? s.pendingEvilOpferId! : s.aktiverSpieler.id;

  /// Lässt Bots so lange automatisch weiterspielen, bis ein Mensch am Zug
  /// ist oder die Partie endet.
  (GameState, List<GameEvent>) _spieleBotsWeiter(
    GameState state,
    List<GameEvent> bisherigeEvents,
  ) {
    var aktuellerState = state;
    final alleEvents = List<GameEvent>.of(bisherigeEvents);
    while (aktuellerState.spielLaeuft &&
        _botSpieler.containsKey(_verantwortlicherId(aktuellerState))) {
      final id = _verantwortlicherId(aktuellerState);
      final (command, neuerRng) = _botSpieler[id]!.waehleCommand(
        aktuellerState,
        id,
        _botRng,
      );
      _botRng = neuerRng;
      final (neuerState, neueEvents) = _engine.apply(aktuellerState, command);
      aktuellerState = neuerState;
      alleEvents.addAll(neueEvents);
    }
    return (aktuellerState, alleEvents);
  }

  void _anwenden(Emitter<GameUiState> emit, Command command) {
    try {
      final (nachMenschenzug, eventsMensch) = _engine.apply(state.spiel, command);
      final (neu, events) = _spieleBotsWeiter(nachMenschenzug, eventsMensch);
      final zugWurdeBeendet = events.any((e) => e is ZugBeendet);
      final wertung = events.whereType<WertungBerechnet>().lastOrNull?.wertung;
      emit(
        state.copyWith(
          spiel: neu,
          letzteEvents: events,
          letzteWertung: wertung ?? state.letzteWertung,
          // Kein Übergabe-Screen gegen einen Bot — es gibt keine zweite
          // Hand zu verdecken.
          zeigtUebergabe: _botSpieler.isEmpty && zugWurdeBeendet && neu.spielLaeuft,
          ausgewaehlteHandkarte: null,
          fehler: null,
        ),
      );
    } on RegelVerstoss catch (e) {
      emit(state.copyWith(fehler: e.nachricht));
    }
  }

  void _aufBotZugAusloesen(BotZugAusloesen event, Emitter<GameUiState> emit) {
    if (_botSpieler.isEmpty) return;
    final (neu, events) = _spieleBotsWeiter(state.spiel, const []);
    if (identical(neu, state.spiel)) return;
    final wertung = events.whereType<WertungBerechnet>().lastOrNull?.wertung;
    emit(
      state.copyWith(
        spiel: neu,
        letzteEvents: events,
        letzteWertung: wertung ?? state.letzteWertung,
      ),
    );
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
