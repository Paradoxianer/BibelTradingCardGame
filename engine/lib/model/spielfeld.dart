import 'karte.dart';

/// Eine Karte in einem Stapel, plus In-Play-Zustand. Aktuell wird nur die
/// Anzahl verbrauchter `schutz`-Ladungen gebraucht (EFFEKTE.md §2.2): der
/// Effekt erlischt nach Verbrauch, auch wenn die Karte oben liegen bleibt.
class Kartenlage {
  final Karte karte;
  final int ladungenVerbraucht;

  const Kartenlage(this.karte, {this.ladungenVerbraucht = 0});

  Kartenlage mitVerbrauchterLadung() =>
      Kartenlage(karte, ladungenVerbraucht: ladungenVerbraucht + 1);
}

/// Ein Ablagestapel (Spielfeld). Index 0 = oberste Karte (D3: neue Karte
/// kommt immer obenauf, kein Umsortieren außer durch `umordnung`, D10).
class Spielfeld {
  final List<Kartenlage> stapel;

  const Spielfeld([this.stapel = const []]);

  bool get istLeer => stapel.isEmpty;

  Kartenlage? get oberste => istLeer ? null : stapel.first;

  Spielfeld legeObenauf(Karte karte) => Spielfeld([Kartenlage(karte), ...stapel]);

  Spielfeld mitStapel(List<Kartenlage> neuerStapel) => Spielfeld(neuerStapel);

  Spielfeld mitOberster(Kartenlage neueOberste) =>
      Spielfeld([neueOberste, ...stapel.skip(1)]);
}
