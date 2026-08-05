import '../engine.dart';
import 'bot.dart';
import 'greedy_bot.dart';

/// Wie [GreedyBot] beim Bauen, spielt aber Evil nur, wenn die Hand komplett
/// mit Evil-Karten verstopft ist (Notausgang). Referenzpunkt, um zu messen,
/// wie viel Aggressivität tatsächlich ausmacht.
///
/// Ganz ohne Notausgang wäre der Bot nicht spielfähig: REGELWERK kennt kein
/// Ablegen, gezogene eigene Evil-Karten lassen sich nur durch Ausspielen
/// wieder los. Ein Bot, der Evil kategorisch verweigert, hortet sie also für
/// immer und blockiert am Ende alle 5 Handplätze — die Partie endet nie.
class DefensivBot implements Bot {
  const DefensivBot();

  static const _greedy = GreedyBot();

  @override
  Zugentscheidung waehleCommand(
    GameState state,
    String spielerId,
    SeedableRng rng,
  ) {
    if (state.phase == ZugPhase.evilSpielen) {
      final spieler = state.spielerMitId(spielerId);
      final nurEvilInHand =
          spieler.hand.isNotEmpty &&
          spieler.hand.every((k) => k.kategorie == Kategorie.evil);
      if (!nurEvilInHand) return (const Passen(), rng);
      // Notausgang: delegiert an GreedyBot, der bestmögliches Ziel wählt.
    }
    return _greedy.waehleCommand(state, spielerId, rng);
  }
}
