import 'dart:ui';

/// Wo die sechs Slot-Kreise auf einer Karte sitzen.
///
/// **Eine** Quelle für zwei Dinge, die zwingend deckungsgleich sein müssen:
/// das Zeichnen der Symbole und das Ausstanzen der Löcher. Liefen sie
/// auseinander, säße das Loch neben dem Symbol.
class SlotLayout {
  /// Kartenbreite, auf die sich alle Maße beziehen.
  final double kartenBreite;

  /// Kantenlänge einer Slot-Zelle.
  final double zelle;

  /// Obere Kante der Slot-Zeile innerhalb der Karte.
  final double oben;

  const SlotLayout({
    required this.kartenBreite,
    required this.zelle,
    required this.oben,
  });

  /// Waagerechter Abstand zwischen zwei Zellen (je 1 px Polsterung).
  static const double abstand = 2;

  /// Anteil der Zellbreite, den die durchsichtige Lochmitte einnimmt.
  /// Aus dem Tile gemessen: Innenradius 121,5 von 378 px Kachelbreite.
  static const double _lochRadiusAnteil = 121.5 / 378;

  double get gesamtBreite => 6 * zelle + 5 * abstand;

  double get startX => (kartenBreite - gesamtBreite) / 2;

  /// Mittelpunkt der i-ten Zelle (0 … 5, in Anzeigereihenfolge).
  Offset mitte(int i) => Offset(
    startX + i * (zelle + abstand) + zelle / 2,
    oben + zelle / 2,
  );

  /// Radius der Stanzung — nur die Innenfläche, Ring und Dreiecke bleiben
  /// stehen.
  double get lochRadius => zelle * _lochRadiusAnteil;
}
