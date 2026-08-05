import 'package:btcg_engine/engine.dart';

/// UI-Zustand, den [GameBloc] hält: der reine Engine-[GameState] plus
/// ephemere UI-Auswahl (ARCHITEKTUR §3 — "Keine Spiellogik im Bloc").
class GameUiState {
  final GameState spiel;
  final Kartenset kartenset;
  final Karte? ausgewaehlteHandkarte;
  final bool zeigtUebergabe;
  final Wertung? letzteWertung;
  final List<GameEvent> letzteEvents;
  final String? fehler;

  const GameUiState({
    required this.spiel,
    required this.kartenset,
    this.ausgewaehlteHandkarte,
    this.zeigtUebergabe = false,
    this.letzteWertung,
    this.letzteEvents = const [],
    this.fehler,
  });

  GameUiState copyWith({
    GameState? spiel,
    Object? ausgewaehlteHandkarte = _unset,
    bool? zeigtUebergabe,
    Wertung? letzteWertung,
    List<GameEvent>? letzteEvents,
    Object? fehler = _unset,
  }) => GameUiState(
    spiel: spiel ?? this.spiel,
    kartenset: kartenset,
    ausgewaehlteHandkarte: ausgewaehlteHandkarte == _unset
        ? this.ausgewaehlteHandkarte
        : ausgewaehlteHandkarte as Karte?,
    zeigtUebergabe: zeigtUebergabe ?? this.zeigtUebergabe,
    letzteWertung: letzteWertung ?? this.letzteWertung,
    letzteEvents: letzteEvents ?? this.letzteEvents,
    fehler: fehler == _unset ? this.fehler : fehler as String?,
  );
}

const Object _unset = Object();
