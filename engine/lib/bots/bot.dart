import '../engine.dart';

typedef Zugentscheidung = (Command command, SeedableRng rng);

/// Eine Bot-Strategie entscheidet je Zug-Phase, welchen Command sie spielt.
/// Reine Engine-Funktion (ARCHITEKTUR §1) — Zufall läuft über den
/// mitgegebenen [SeedableRng], damit Simulationsläufe reproduzierbar bleiben.
abstract interface class Bot {
  Zugentscheidung waehleCommand(
    GameState state,
    String spielerId,
    SeedableRng rng,
  );
}

/// Legale Evil-Ziele für [angreiferId] (D1/D8): kein Ziel in Runde 1, sonst
/// jedes Feld jedes Mitspielers, der diese Runde noch kein Evil erhalten hat.
List<(String spielerId, int feldIndex)> legaleEvilZiele(
  GameState state,
  String angreiferId,
) {
  if (state.rundeNummer == 1) return const [];
  final ziele = <(String, int)>[];
  for (final spieler in state.spieler) {
    if (spieler.id == angreiferId) continue;
    if (state.evilEmpfangenDieseRunde.contains(spieler.id)) continue;
    for (var i = 0; i < spieler.spielfelder.length; i++) {
      ziele.add((spieler.id, i));
    }
  }
  return ziele;
}
