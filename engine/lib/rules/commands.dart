import 'effekt_wahl.dart';

/// Spieler-Aktionen, die die Engine gegen den aktuellen [ZugPhase] validiert
/// (siehe game_state.dart, REGELWERK §5).
sealed class Command {
  const Command();
}

/// Bauen-Phase: eine Handkarte offen auf [feldIndex] legen (immer obenauf).
/// Bei `gebietserweiterung`-Karten wird [feldIndex] ignoriert — die Karte
/// gründet stattdessen ein neues, viertes Feld (EFFEKTE.md §2.3).
class KarteBauen extends Command {
  final int feldIndex;
  final String karteId;
  final EffektWahl? effektWahl;

  const KarteBauen({
    required this.feldIndex,
    required this.karteId,
    this.effektWahl,
  });
}

/// Evil-Phase: eine Evil-Karte auf ein Feld eines Mitspielers legen (D1).
class EvilSpielen extends Command {
  final String zielSpielerId;
  final int zielFeldIndex;
  final String karteId;

  const EvilSpielen({
    required this.zielSpielerId,
    required this.zielFeldIndex,
    required this.karteId,
  });
}

/// Reaktion-Phase: eine `sofort`-Karte als Antwort auf eine Evil-Karte
/// spielen (D4), immer auf das bedrohte Feld.
class SofortReagieren extends Command {
  final String karteId;
  final EffektWahl? effektWahl;

  const SofortReagieren({required this.karteId, this.effektWahl});
}

/// Verzichtet auf die optionale Aktion der aktuellen Phase (Bauen, Evil
/// spielen oder Reagieren).
class Passen extends Command {
  const Passen();
}
