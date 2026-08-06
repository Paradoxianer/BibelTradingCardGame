import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';

import 'slot_zeile.dart';

/// Rendert ein Spielfeld als eine zusammengesetzte Karte: pro Slot das
/// oberste nicht-Loch-Symbol (via [SlotZeile.fuerFeld]), mit Tiefen-Hinweis
/// (gestapelte Kartenränder) und Durchschein-Animation beim Auflegen einer
/// neuen Karte (ARCHITEKTUR §3 — wichtigster UI-Baustein).
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
      child: KeyedSubtree(
        key: ValueKey(
          '${feld.oberste?.karte.id ?? 'leer'}-${feld.stapel.length}',
        ),
        child: SlotZeile.fuerFeld(feld),
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
