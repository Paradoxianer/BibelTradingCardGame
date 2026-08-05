import '../model/model.dart';

/// Sucht eine aktive `schutz`-Deckung, die [zielFeldIndex] abwehren würde
/// (EFFEKTE.md §2.2): zuerst Reichweite `feld` auf dem Zielfeld selbst,
/// sonst Reichweite `spieler` auf irgendeinem Feld.
({int feldIndex, Kartenlage lage})? findeAktivenSchutz(
  Spieler spieler,
  int zielFeldIndex,
) {
  final zielOben = spieler.spielfelder[zielFeldIndex].oberste;
  if (zielOben != null) {
    final e = zielOben.karte.effekt;
    if (e is Schutz &&
        e.reichweite == SchutzReichweite.feld &&
        zielOben.ladungenVerbraucht < e.ladungen) {
      return (feldIndex: zielFeldIndex, lage: zielOben);
    }
  }
  for (var i = 0; i < spieler.spielfelder.length; i++) {
    final oben = spieler.spielfelder[i].oberste;
    if (oben == null) continue;
    final e = oben.karte.effekt;
    if (e is Schutz &&
        e.reichweite == SchutzReichweite.spieler &&
        oben.ladungenVerbraucht < e.ladungen) {
      return (feldIndex: i, lage: oben);
    }
  }
  return null;
}

Spieler verbraucheSchutzLadung(Spieler spieler, int feldIndex) {
  final feld = spieler.spielfelder[feldIndex];
  final neueOberste = feld.oberste!.mitVerbrauchterLadung();
  final neueFelder = List.of(spieler.spielfelder);
  neueFelder[feldIndex] = feld.mitOberster(neueOberste);
  return spieler.copyWith(spielfelder: neueFelder);
}
