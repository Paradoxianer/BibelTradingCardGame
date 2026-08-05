import '../engine.dart';
import 'bot.dart';

/// Spielt in jeder Phase eine zufällig gültige Aktion (oder passt zufällig).
/// Baseline für Simulationsvergleiche gegen [GreedyBot].
class ZufallsBot implements Bot {
  const ZufallsBot();

  @override
  Zugentscheidung waehleCommand(
    GameState state,
    String spielerId,
    SeedableRng rng,
  ) {
    return switch (state.phase) {
      ZugPhase.bauen => _zufallsBau(state, spielerId, rng),
      ZugPhase.evilSpielen => _zufallsEvil(state, spielerId, rng),
      // Kein sofort-Kandidat im Basis-Set (KARTEN_SPEZIFIKATION §5) — Platzhalter.
      ZugPhase.reaktion => (const Passen(), rng),
    };
  }

  Zugentscheidung _zufallsBau(
    GameState state,
    String spielerId,
    SeedableRng rng,
  ) {
    final spieler = state.spielerMitId(spielerId);
    final spielbar = spieler.hand
        .where((k) => k.kategorie != Kategorie.evil)
        .toList();
    if (spielbar.isEmpty) return (const Passen(), rng);

    final (index, rng1) = rng.naechsteZahl(spielbar.length + 1);
    if (index == spielbar.length) return (const Passen(), rng1);

    final karte = spielbar[index];
    if (karte.effekt is Gebietserweiterung) {
      if (spieler.spielfelder.length >= 4) return (const Passen(), rng1);
      return (KarteBauen(feldIndex: 0, karteId: karte.id), rng1);
    }
    final (feldIndex, rng2) = rng1.naechsteZahl(spieler.spielfelder.length);
    return (KarteBauen(feldIndex: feldIndex, karteId: karte.id), rng2);
  }

  Zugentscheidung _zufallsEvil(
    GameState state,
    String spielerId,
    SeedableRng rng,
  ) {
    final ziele = legaleEvilZiele(state, spielerId);
    final spieler = state.spielerMitId(spielerId);
    final evilKarten = spieler.hand
        .where((k) => k.kategorie == Kategorie.evil)
        .toList();
    if (ziele.isEmpty || evilKarten.isEmpty) return (const Passen(), rng);

    final (kartenIndex, rng1) = rng.naechsteZahl(evilKarten.length);
    final (zielIndex, rng2) = rng1.naechsteZahl(ziele.length);
    final (zielSpielerId, feldIndex) = ziele[zielIndex];
    return (
      EvilSpielen(
        zielSpielerId: zielSpielerId,
        zielFeldIndex: feldIndex,
        karteId: evilKarten[kartenIndex].id,
      ),
      rng2,
    );
  }
}
