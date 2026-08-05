import 'package:btcg_engine/engine.dart';

/// UI-Intents, die [GameBloc] in Engine-[Command]s übersetzt.
sealed class GameUiEvent {
  const GameUiEvent();
}

class HandkarteAngetippt extends GameUiEvent {
  final Karte karte;
  const HandkarteAngetippt(this.karte);
}

class FeldAngetippt extends GameUiEvent {
  final int feldIndex;
  const FeldAngetippt(this.feldIndex);
}

class EvilZielAngetippt extends GameUiEvent {
  final String spielerId;
  final int feldIndex;
  const EvilZielAngetippt({required this.spielerId, required this.feldIndex});
}

class PassenAngetippt extends GameUiEvent {
  const PassenAngetippt();
}

class ReaktionskarteAngetippt extends GameUiEvent {
  final Karte karte;
  const ReaktionskarteAngetippt(this.karte);
}

class UebergabeBestaetigt extends GameUiEvent {
  const UebergabeBestaetigt();
}

/// Internes Kickoff-Event: prüft, ob ein Bot am Zug ist, und lässt ihn
/// spielen. Nötig für den Sonderfall "Bot ist zufällig Startspieler", bei
/// dem noch kein UI-Intent stattgefunden hat, der [GameBloc] sonst zum
/// automatischen Weiterspielen anstößt.
class BotZugAusloesen extends GameUiEvent {
  const BotZugAusloesen();
}
