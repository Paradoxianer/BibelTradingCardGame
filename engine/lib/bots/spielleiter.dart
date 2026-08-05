import '../engine.dart';
import 'bot.dart';

class ZugLimitUeberschritten implements Exception {
  final String nachricht;
  const ZugLimitUeberschritten(this.nachricht);

  @override
  String toString() => 'ZugLimitUeberschritten: $nachricht';
}

/// Treibt eine Partie mit Bots bis zum Ende (Sieg oder D2) an. In der
/// Reaktion-Phase entscheidet der Bot des Verteidigers
/// ([GameState.pendingEvilOpferId]), sonst der des aktiven Spielers.
/// [maxCommands] ist eine Sicherheitsbremse gegen Endlosschleifen bei
/// fehlerhaften Bot-Strategien.
GameState spielePartieBisEnde({
  required GameEngine engine,
  required GameState anfangszustand,
  required Map<String, Bot> bots,
  required SeedableRng botRng,
  int maxCommands = 5000,
}) {
  var state = anfangszustand;
  var rng = botRng;

  for (var i = 0; i < maxCommands; i++) {
    if (!state.spielLaeuft) return state;
    final handelnderId = state.phase == ZugPhase.reaktion
        ? state.pendingEvilOpferId!
        : state.aktiverSpieler.id;
    final bot = bots[handelnderId]!;
    final (command, neuerRng) = bot.waehleCommand(state, handelnderId, rng);
    rng = neuerRng;
    final (neuerState, _) = engine.apply(state, command);
    state = neuerState;
  }
  throw ZugLimitUeberschritten('Mehr als $maxCommands Commands ohne Spielende.');
}
