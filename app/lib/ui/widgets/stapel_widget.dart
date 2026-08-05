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

/// Bildpfad für den aktuell sichtbaren Slot-Wert — dieselbe "Durchschau"-
/// Logik wie die Wertung (engine/rules/sichtbarkeit.dart), damit UI und
/// Punkte immer zueinander passen.
String tilePfad(SlotPosition pos, ({SlotSymbol symbol, int tiefe})? gefunden) {
  if (gefunden == null) return '$_artworkBasis/Empty.png';
  final prefix = _prefixFuer(pos);
  final wert = switch (gefunden.symbol) {
    Farbig(wert: final w) => '$w',
    Schwarz() => '-1',
    Loch() => throw StateError('sichtbaresSymbolAn liefert nie ein Loch'),
  };
  return '$_artworkBasis/${prefix}_$wert.png';
}

/// Rendert ein Spielfeld als eine zusammengesetzte Karte: pro Slot das
/// oberste nicht-Loch-Symbol, mit Tiefen-Hinweis (gestapelte Kartenränder)
/// und Durchschein-Animation beim Auflegen einer neuen Karte
/// (ARCHITEKTUR §3 — wichtigster UI-Baustein).
class StapelWidget extends StatelessWidget {
  final Spielfeld feld;
  final bool ausgewaehlt;
  final bool hervorgehoben;
  final VoidCallback? onTap;

  const StapelWidget({
    super.key,
    required this.feld,
    this.ausgewaehlt = false,
    this.hervorgehoben = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rahmenFarbe = ausgewaehlt
        ? Colors.amber
        : hervorgehoben
        ? Colors.redAccent
        : Colors.black26;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: rahmenFarbe,
            width: (ausgewaehlt || hervorgehoben) ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SlotZeile(feld: feld),
            const SizedBox(height: 4),
            _KartenkoerperGestapelt(feld: feld),
          ],
        ),
      ),
    );
  }
}

class _SlotZeile extends StatelessWidget {
  final Spielfeld feld;
  const _SlotZeile({required this.feld});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.82, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: Row(
        key: ValueKey(
          '${feld.oberste?.karte.id ?? 'leer'}-${feld.stapel.length}',
        ),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final pos in kSlotOrder)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Image.asset(
                tilePfad(pos, sichtbaresSymbolAn(feld, pos)),
                width: 26,
                height: 26,
              ),
            ),
        ],
      ),
    );
  }
}

class _KartenkoerperGestapelt extends StatelessWidget {
  final Spielfeld feld;
  const _KartenkoerperGestapelt({required this.feld});

  static const double _breite = 96;
  static const double _hoehe = 68;

  @override
  Widget build(BuildContext context) {
    final oben = feld.oberste;
    final versetzteSchichten = (feld.stapel.length - 1).clamp(0, 3);

    return SizedBox(
      width: _breite + versetzteSchichten * 3,
      height: _hoehe + versetzteSchichten * 3,
      child: Stack(
        children: [
          for (var i = versetzteSchichten; i >= 1; i--)
            Positioned(
              left: i * 3.0,
              top: i * 3.0,
              child: Container(
                width: _breite,
                height: _hoehe,
                decoration: BoxDecoration(
                  color: Colors.brown.shade100,
                  border: Border.all(color: Colors.brown.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: _breite,
              height: _hoehe,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black54),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(4),
              child: oben == null
                  ? const Center(
                      child: Text(
                        'leer',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          oben.karte.name,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${feld.stapel.length} Karte(n)',
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
