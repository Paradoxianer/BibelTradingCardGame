import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';

// Kopie von legacy/ArtWork/ — siehe Kommentar in data/kartenset_loader.dart
// zum Grund (DWDS unterstützt keine `..`-relativen Assets).
const String _artworkBasis = 'assets/artwork';

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

/// Was in einer Slot-Spalte tatsächlich zu sehen ist. [verdeckt] blendet den
/// Wert aus und zeigt nur, ob dort ein Loch ist (REGELWERK D9).
typedef SlotAnzeige = ({SlotPosition pos, SlotSymbol symbol, bool verdeckt});

/// Slot einer verdeckten Karte ohne Loch: die Kartenrückseite. Zeigt bewusst
/// keinen Wert, hält aber die Zelle besetzt, damit die Loch-Positionen
/// ablesbar bleiben.
class _VerdeckterSlot extends StatelessWidget {
  const _VerdeckterSlot();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(1),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.indigo.shade100,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.indigo.shade200),
      ),
    ),
  );
}

/// Die sechs Symbole einer Karte bzw. eines Stapels — **ein** Rendering für
/// Hand- und Feldkarten. Es sind immer genau 6 Zellen sichtbar, nie Lücken
/// (ARCHITEKTUR §3).
class SlotZeile extends StatelessWidget {
  final List<SlotAnzeige> zellen;
  final double groesse;

  /// Direkt mit fertigen Zellen — genutzt von [KartenWidget], das die Zellen
  /// über die Factories unten ermittelt und selbst zeichnen lässt.
  const SlotZeile({super.key, required this.zellen, this.groesse = 26});

  const SlotZeile._({required this.zellen, required this.groesse});

  /// Einzelne Karte (Hand): zeigt schlicht ihre eigenen Symbole. Ein Loch
  /// zeigt das Loch-Tile — es liegt ja nichts darunter, durch das man sähe.
  factory SlotZeile.fuerKarte(Karte karte, {double groesse = 26}) => SlotZeile._(
    groesse: groesse,
    zellen: [
      for (final pos in kSlotOrder)
        (pos: pos, symbol: karte.slotAn(pos), verdeckt: false),
    ],
  );

  /// Verdeckte Karte (fremde Hand, oberste Deckkarte): nur die Stanzungen
  /// sind zu sehen, die Werte nicht — eine Stanzung ist auch von hinten ein
  /// Loch (REGELWERK D9).
  ///
  /// Die Reihenfolge ist **gespiegelt**: eine umgedrehte Karte zeigt ihre
  /// Löcher seitenverkehrt, sonst passt das Bild nicht zu einer real
  /// gewendeten Karte.
  factory SlotZeile.fuerVerdeckteKarte(Karte karte, {double groesse = 26}) =>
      SlotZeile._(
        groesse: groesse,
        zellen: [
          for (final pos in kSlotOrder.reversed)
            (
              pos: pos,
              symbol: karte.slotAn(pos),
              verdeckt: karte.slotAn(pos) is! Loch,
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final zelle in zellen)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: SizedBox(
              width: groesse,
              height: groesse,
              // Rückseite: Wert bleibt verborgen, Löcher nicht (D9).
              // Beim Loch-Tile wird die schraffierte Innenfläche von der
              // LochStanzung weggeschnitten; stehen bleiben Ring und
              // Dreiecke, und dort scheint durch, was darunter liegt.
              child: zelle.verdeckt
                  ? const _VerdeckterSlot()
                  : Image.asset(tilePfad(zelle.pos, zelle.symbol)),
            ),
          ),
      ],
    );
  }
}
