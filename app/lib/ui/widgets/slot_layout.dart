import 'dart:math' as math;
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

  /// Die Geometrie für eine Karte gegebener Breite — **einzige** Quelle für
  /// [KartenWidget] und für Tests, die reale Pixel nachmessen. Zwei separate
  /// Berechnungen derselben Formel liefen schon zweimal auseinander (Ring zu
  /// dünn, Dreiecke vom Kartenrand angeschnitten), weil eine Kopie geändert
  /// wurde und die andere nicht.
  factory SlotLayout.fuerKarte(double breite) {
    final zelle = breite / 8.2;
    return SlotLayout(
      kartenBreite: breite,
      zelle: zelle,
      // Etwas mehr als die Rahmenbreite (breite/40): sitzt die Slot-Zeile
      // direkt darauf, schneidet der Kartenrahmen die Dreieck-Spitzen an.
      oben: breite / 40 + zelle * 0.12,
    );
  }

  /// Waagerechter Abstand zwischen zwei Zellen (je 1 px Polsterung).
  static const double abstand = 2;

  /// Maße aus dem Original-Artwork (378 px Kachel): Außenradius des Kreises
  /// 143,5 und Innenradius des Rings 121,5 — daraus ergibt sich auch die
  /// Ringdicke.
  static const double _symbolRadiusAnteil = 143.5 / 378;
  static const double _lochRadiusAnteil = 121.5 / 378;

  double get gesamtBreite => 6 * zelle + 5 * abstand;

  double get startX => (kartenBreite - gesamtBreite) / 2;

  /// Mittelpunkt der i-ten Zelle (0 … 5, in Anzeigereihenfolge).
  Offset mitte(int i) => Offset(
    startX + i * (zelle + abstand) + zelle / 2,
    oben + zelle / 2,
  );

  /// Außenradius des gezeichneten Kreises.
  double get symbolRadius => zelle * _symbolRadiusAnteil;

  /// Dicke des schwarzen Rings.
  ///
  /// Das Original-Verhältnis (22 von 143,5 Radius) ergibt auf kleinen Karten
  /// einen Ring unter einem Pixel — dort ist dann nicht mehr zu erkennen,
  /// dass es sich um ein Loch handelt. Deshalb eine Untergrenze.
  static const double _mindestRing = 1.6;

  double get ringDicke =>
      math.max(symbolRadius * (1 - _lochRadiusAnteil / _symbolRadiusAnteil),
          _mindestRing);

  /// Radius der Stanzung — nur die Innenfläche, der Ring bleibt stehen.
  double get lochRadius => symbolRadius - ringDicke;
}
