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

      final wahl = _erneuerungWahl(spieler, karte);
      for (var i = 0; i < spieler.spielfelder.length; i++) {
        final neueFelder = List<Spielfeld>.of(spieler.spielfelder);
        neueFelder[i] = neueFelder[i].legeObenauf(karte);
        final kandidat = spieler.copyWith(spielfelder: neueFelder);
        if (karte.effekt is Umordnung) {
          final (umordnung, wert) = _besteUmordnung(state, kandidat, i);
          betrachte(KarteBauen(feldIndex: i, karteId: karte.id, effektWahl: umordnung), wert);
          continue;
        }
        final wert = berechneWertung(state.mitSpieler(kandidat), spielerId).punkte;
        betrachte(KarteBauen(feldIndex: i, karteId: karte.id, effektWahl: wahl), wert);
      }
    }
    return bester ?? const Passen();
  }

  /// `umordnung` (EFFEKTE §2.8, eigene Variante): probiert jede Verschiebung
  /// einer Karte innerhalb eines eigenen Stapels durch — nachdem die
  /// Effektkarte selbst schon auf Feld [gebautAuf] liegt — und nimmt die mit
  /// der besten Wertung. Die Startkarte bleibt unberührt, samt ihrer
  /// Position: verschoben wird nur oberhalb von ihr (EFFEKTE §2.8 "Startkarte
  /// ist ausgenommen", die Engine lehnt alles andere ab).
  (UmordnungWahl, int) _besteUmordnung(GameState state, Spieler nachBau, int gebautAuf) {
    // Kein Gewinn möglich: dann eine erlaubte Nicht-Verschiebung.
    var beste = UmordnungWahl(feldIndex: gebautAuf, vonTiefe: 0, nachTiefe: 0);
    var besterWert = berechneWertung(state.mitSpieler(nachBau), nachBau.id).punkte;
    for (var f = 0; f < nachBau.spielfelder.length; f++) {
      final stapel = nachBau.spielfelder[f].stapel;
      final startIndex = stapel.indexWhere((l) => l.karte.kategorie == Kategorie.start);
      final grenze = startIndex == -1 ? stapel.length : startIndex;
      for (var von = 0; von < grenze; von++) {
        for (var nach = 0; nach < grenze; nach++) {
          if (von == nach) continue;
          final neu = List<Kartenlage>.of(stapel);
          neu.insert(nach, neu.removeAt(von));
          final felder = List<Spielfeld>.of(nachBau.spielfelder);
          felder[f] = Spielfeld(neu);
          final wert = berechneWertung(
            state.mitSpieler(nachBau.copyWith(spielfelder: felder)),
            nachBau.id,
          ).punkte;
          if (wert > besterWert) {
            besterWert = wert;
            beste = UmordnungWahl(feldIndex: f, vonTiefe: von, nachTiefe: nach);
          }
        }
      }
    }
    return (beste, besterWert);
  }

  /// `erneuerung` (EFFEKTE §2.7) ist als Ventil gegen Evil-Handverstopfung
  /// gedacht (REGELWERK D6) — also mischt der Bot genau die Evil-Karten
  /// zurück, die er gerade nicht loswird. Ohne Auswahl würde die Karte
  /// nichts tauschen. Andere Karten tauscht er nicht: ob eine Ressourcenkarte
  /// "schlecht" ist, hängt vom Board ab und ist nicht Teil dieser Messung.
  ErneuerungWahl? _erneuerungWahl(Spieler spieler, Karte karte) {
    final effekt = karte.effekt;
    if (effekt is! Erneuerung) return null;
    final restHand = List<Karte>.of(spieler.hand)..remove(karte);
    final evilIds = restHand
        .where((k) => k.kategorie == Kategorie.evil)
        .take(effekt.menge)
        .map((k) => k.id)
        .toList();
    return ErneuerungWahl(evilIds);
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
