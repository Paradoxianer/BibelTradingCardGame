import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';

// Kopie von legacy/ArtWork/ — siehe Kommentar in data/kartenset_loader.dart
// zum Grund (DWDS unterstützt keine `..`-relativen Assets).
const String _artworkBasis = 'assets/artwork';

/// Overlay „dieser Wert zählt": die beiden Dreiecke, transparent dazwischen.
/// Die Bestands-Tiles `-1` und `x` tragen sie fest eingebaut, weil sie immer
/// zählen; bunte Werte bekommen sie zur Laufzeit, sobald durch ein Loch auf
/// sie geschaut wird (ARCHITEKTUR §3).
const String _markerPfad = '$_artworkBasis/Loch_Marker.png';

String _prefixFuer(SlotPosition pos) => switch (pos) {
  SlotPosition.v1 || SlotPosition.v2 => 'V',
  SlotPosition.s1 || SlotPosition.s2 => 'S',
  SlotPosition.hg1 || SlotPosition.hg2 => 'HG',
};

String tilePfad(SlotPosition pos, SlotSymbol symbol) {
  final wert = switch (symbol) {
    Farbig(wert: final w) => '$w',
    Schwarz() => '-1',
    Loch() => 'x',
  };
  return '$_artworkBasis/${_prefixFuer(pos)}_$wert.png';
}

/// Was in einer Slot-Spalte tatsächlich zu sehen ist.
typedef SlotAnzeige = ({SlotSymbol symbol, bool durchLoch});

/// Die sechs Symbole einer Karte bzw. eines Stapels — **ein** Rendering für
/// Hand- und Feldkarten. Es sind immer genau 6 Zellen sichtbar, nie Lücken
/// (ARCHITEKTUR §3).
class SlotZeile extends StatelessWidget {
  final List<SlotAnzeige> zellen;
  final double groesse;

  const SlotZeile._({required this.zellen, required this.groesse});

  /// Einzelne Karte (Hand): zeigt schlicht ihre eigenen Symbole. Ein Loch
  /// zeigt das Loch-Tile — es liegt ja nichts darunter, durch das man sähe.
  factory SlotZeile.fuerKarte(Karte karte, {double groesse = 26}) => SlotZeile._(
    groesse: groesse,
    zellen: [
      for (final pos in kSlotOrder)
        (symbol: karte.slotAn(pos), durchLoch: false),
    ],
  );

  /// Stapel (Spielfeld): pro Spalte das erste Nicht-Loch-Symbol von oben —
  /// dieselbe Logik wie die Wertung (`sichtbaresSymbolAn`), damit Bild und
  /// Punkte nie auseinanderlaufen. Wurde durch mindestens ein Loch geschaut,
  /// kommt der „zählt"-Marker darüber.
  factory SlotZeile.fuerFeld(Spielfeld feld, {double groesse = 26}) => SlotZeile._(
    groesse: groesse,
    zellen: [
      for (final pos in kSlotOrder)
        switch (sichtbaresSymbolAn(feld, pos)) {
          null => (symbol: const Loch(), durchLoch: false),
          final g => (symbol: g.symbol, durchLoch: g.tiefe > 0),
        },
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < kSlotOrder.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: SizedBox(
              width: groesse,
              height: groesse,
              child: Stack(
                children: [
                  Image.asset(tilePfad(kSlotOrder[i], zellen[i].symbol)),
                  if (zellen[i].durchLoch) Image.asset(_markerPfad),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
