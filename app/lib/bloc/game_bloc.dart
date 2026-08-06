import 'dart:async';

import 'package:btcg_engine/bots/bots.dart';
import 'package:btcg_engine/engine.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'game_event.dart';
import 'game_ui_state.dart';
import 'spiel_persistenz.dart';

/// Übersetzt UI-Intents in Engine-[Command]s und Engine-[GameEvent]s zurück
/// in UI-Zustand (ARCHITEKTUR §3). Enthält selbst keine Spielregeln — jede
/// Legalitätsprüfung passiert in [GameEngine].
///
/// [botSpieler] ordnet Spieler-IDs Bot-Strategien zu (leer = reines Hotseat).
/// Ist ein Bot am Zug (Bauen/Evil/Reaktion), spielt [GameBloc] ihn
/// automatisch weiter, bis wieder ein Mensch entscheiden muss oder die
/// Partie endet — dafür gibt es keinen eigenen Übergabe-Screen.
///
/// Persistiert sich selbst über [HydratedBloc]: siehe spiel_persistenz.dart
/// für die Seed+Verlauf-Serialisierung. [GameBloc.storageToken] ist der
/// Schlüssel, unter dem der Spielstand liegt — [loescheGespeichertesSpiel]
/// und [gespeichertesSpielVorhanden] arbeiten direkt darauf, ohne dass schon
/// eine Instanz existieren muss.
class GameBloc extends HydratedBloc<GameUiEvent, GameUiState> {
  /// Muss mit dem von [HydratedMixin] intern berechneten `storageToken`
  /// übereinstimmen (Klassenname, da `id`/`storagePrefix` nicht überschrieben
  /// sind) — hier als Konstante, damit nichts an zwei Stellen gepflegt wird.
  static const String speicherSchluessel = 'GameBloc';

  static bool gespeichertesSpielVorhanden() =>
      HydratedBloc.storage.read(speicherSchluessel) != null;

  static Future<void> loescheGespeichertesSpiel() =>
      HydratedBloc.storage.delete(speicherSchluessel);

  final GameEngine _engine = GameEngine();
  final Kartenset kartenset;
  final List<SpielerAufbau> _aufbauListe;
  final int _seed;
  final RegelConfig _config;
  final Map<String, Bot> _botSpieler;
  final int _anfangsBotSeed;
  SeedableRng _botRng;
  final List<Command> _verlauf = [];

  GameBloc({
    required this.kartenset,
    required List<SpielerAufbau> aufbauListe,
    required int seed,
    RegelConfig config = const RegelConfig(),
    Map<String, Bot> botSpieler = const {},
    int botSeed = 0,
  }) : _aufbauListe = aufbauListe,
       _seed = seed,
       _config = config,
       _botSpieler = botSpieler,
       _anfangsBotSeed = botSeed,
       _botRng = SeedableRng.seeded(botSeed),
       super(
         GameUiState(
           spiel: neuesSpiel(spieler: aufbauListe, seed: seed, config: config),
           kartenset: kartenset,
         ),
       ) {
    on<HandkarteAngetippt>(_aufHandkarteAngetippt);
    on<FeldAngetippt>(_aufFeldAngetippt);
    on<EvilZielAngetippt>(_aufEvilZielAngetippt);
    on<PassenAngetippt>(_aufPassenAngetippt);
    on<ReaktionskarteAngetippt>(_aufReaktionskarteAngetippt);
    on<UebergabeBestaetigt>(_aufUebergabeBestaetigt);
    on<BotZugAusloesen>(_aufBotZugAusloesen);
    add(const BotZugAusloesen());
  }

  @override
  Map<String, dynamic>? toJson(GameUiState uiState) {
    if (!uiState.spiel.spielLaeuft) return null; // beendete Partie nicht persistieren
    return gespeichertePartieZuJson(
      kartenset: kartenset,
      aufbauListe: _aufbauListe,
      seed: _seed,
      config: _config,
      botSpieler: _botSpieler,
      botSeed: _anfangsBotSeed,
      verlauf: _verlauf,
    );
  }

  @override
  GameUiState? fromJson(Map<String, dynamic> json) {
    final partie = parseGespeichertePartie(json, kartenset);
    if (partie == null) return null;

    var zustand = neuesSpiel(
      spieler: partie.aufbauListe,
      seed: partie.seed,
      config: partie.config,
    );
    _verlauf.clear();
    for (final command in partie.verlauf) {
      final (neu, _) = _engine.apply(zustand, command);
      zustand = neu;
      _verlauf.add(command);
    }

    return GameUiState(spiel: zustand, kartenset: kartenset);
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
      _verlauf.add(command);
      final (neuerState, neueEvents) = _engine.apply(aktuellerState, command);
      aktuellerState = neuerState;
      alleEvents.addAll(neueEvents);
    }
    return (aktuellerState, alleEvents);
  }

  void _anwenden(Emitter<GameUiState> emit, Command command) {
    try {
      final (nachMenschenzug, eventsMensch) = _engine.apply(state.spiel, command);
      _verlauf.add(command);
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
      if (!neu.spielLaeuft) unawaited(clear());
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
    if (!neu.spielLaeuft) unawaited(clear());
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
