import '../engine.dart';
import 'bot.dart';

/// Wählt je Phase die Aktion mit dem besten sofortigen Wertungs-Preview:
/// beim Bauen die eigene Punktzahl maximieren, bei Evil die Punktzahl des
/// Ziels minimieren. Kein Blick auf zukünftige Züge (daher "greedy").
class GreedyBot implements Bot {
  const GreedyBot();

  @override
  Zugentscheidung waehleCommand(
    GameState state,
    String spielerId,
    SeedableRng rng,
  ) {
    final command = switch (state.phase) {
      ZugPhase.bauen => _besterBauZug(state, spielerId),
      ZugPhase.evilSpielen => _besterEvilZug(state, spielerId),
      ZugPhase.reaktion => const Passen(),
    };
    return (command, rng);
  }

  /// Spielt immer die Karte mit dem besten Sofort-Wertungs-Preview — auch
  /// wenn keine Karte verbessert oder neutral bleibt. REGELWERKs Loch-
  /// Mechanik belohnt bewusst erst *künftige* Züge (§6: "bunter Wert auf der
  /// obersten Karte zählt NICHT"; Überbauen deckt eigene aufgedeckte Werte
  /// wieder zu). Ein Bot, der nur auf die aktuelle Wertung schaut, findet an
  /// einem lokalen Optimum sonst nie eine Verbesserung und hortet Karten für
  /// immer — dann greift D2 nie und die Partie endet nicht. Also: bei
  /// Gleichstand oder nur verschlechternden Optionen trotzdem die am
  /// wenigsten schlechte spielen (nur "Passen", wenn wirklich keine
  /// Nicht-Evil-Karte in der Hand ist).
  Command _besterBauZug(GameState state, String spielerId) {
    final spieler = state.spielerMitId(spielerId);
    Command? bester;
    var besterWert = -(1 << 30);

    void betrachte(Command kandidat, int wert) {
      if (wert > besterWert) {
        besterWert = wert;
        bester = kandidat;
      }
    }

    for (final karte in spieler.hand.where((k) => k.kategorie != Kategorie.evil)) {
      if (karte.effekt is Gebietserweiterung) {
        if (spieler.spielfelder.length >= 4) continue;
        final kandidat = spieler.copyWith(
          spielfelder: [...spieler.spielfelder, Spielfeld([Kartenlage(karte)])],
        );
        final wert = berechneWertung(state.mitSpieler(kandidat), spielerId).punkte;
        betrachte(KarteBauen(feldIndex: 0, karteId: karte.id), wert);
        continue;
      }

      for (var i = 0; i < spieler.spielfelder.length; i++) {
        final neueFelder = List<Spielfeld>.of(spieler.spielfelder);
        neueFelder[i] = neueFelder[i].legeObenauf(karte);
        final kandidat = spieler.copyWith(spielfelder: neueFelder);
        final wert = berechneWertung(state.mitSpieler(kandidat), spielerId).punkte;
        betrachte(KarteBauen(feldIndex: i, karteId: karte.id), wert);
      }
    }
    return bester ?? const Passen();
  }

  Command _besterEvilZug(GameState state, String spielerId) {
    final ziele = legaleEvilZiele(state, spielerId);
    final spieler = state.spielerMitId(spielerId);
    final evilKarten = spieler.hand
        .where((k) => k.kategorie == Kategorie.evil)
        .toList();
    if (ziele.isEmpty || evilKarten.isEmpty) return const Passen();

    // Welche Evil-Karte gespielt wird, ist für die Wertung irrelevant (keine
    // Effekte im Basis-Set, KARTEN_SPEZIFIKATION §5) — die erste reicht.
    final karte = evilKarten.first;
    (String, int)? besteWahl;
    var minWert = 1 << 30;
    for (final (zielSpielerId, feldIndex) in ziele) {
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
