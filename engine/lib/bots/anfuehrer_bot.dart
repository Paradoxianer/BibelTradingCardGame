import '../engine.dart';
import 'bot.dart';
import 'greedy_bot.dart';

/// Wie [GreedyBot] beim Bauen, greift bei Evil aber immer den Spieler mit
/// der höchsten Heiligkeit an ("Anführer") statt den Zug mit dem größten
/// Schaden zu wählen — testet Kingmaking-Dynamiken (REGELWERK D8).
class AnfuehrerBot implements Bot {
  const AnfuehrerBot();

  static const _greedy = GreedyBot();

  @override
  Zugentscheidung waehleCommand(
    GameState state,
    String spielerId,
    SeedableRng rng,
  ) {
    if (state.phase == ZugPhase.evilSpielen) {
      return (_evilGegenAnfuehrer(state, spielerId), rng);
    }
    return _greedy.waehleCommand(state, spielerId, rng);
  }

  Command _evilGegenAnfuehrer(GameState state, String spielerId) {
    final ziele = legaleEvilZiele(state, spielerId);
    final spieler = state.spielerMitId(spielerId);
    final evilKarten = spieler.hand
        .where((k) => k.kategorie == Kategorie.evil)
        .toList();
    if (ziele.isEmpty || evilKarten.isEmpty) return const Passen();

    final zielSpielerIds = ziele.map((z) => z.$1).toSet();
    final anfuehrerId = zielSpielerIds
        .map((id) => state.spielerMitId(id))
        .reduce((a, b) => a.heiligkeit >= b.heiligkeit ? a : b)
        .id;

    final karte = evilKarten.first;
    final feldZiele = ziele.where((z) => z.$1 == anfuehrerId).toList();
    (String, int)? besteWahl;
    var minWert = 1 << 30;
    for (final (zielSpielerId, feldIndex) in feldZiele) {
      final ziel = state.spielerMitId(zielSpielerId);
      final neueFelder = List<Spielfeld>.of(ziel.spielfelder);
      neueFelder[feldIndex] = neueFelder[feldIndex].legeObenauf(karte);
      final kandidat = ziel.copyWith(spielfelder: neueFelder);
      final wert = berechneWertung(state.mitSpieler(kandidat), zielSpielerId).punkte;
      if (wert < minWert) {
        minWert = wert;
        besteWahl = (zielSpielerId, feldIndex);
      }
    }
    final (zielId, feldIndex) = besteWahl!;
    return EvilSpielen(
      zielSpielerId: zielId,
      zielFeldIndex: feldIndex,
      karteId: karte.id,
    );
  }
}
