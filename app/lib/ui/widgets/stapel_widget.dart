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

  /// Punkte, die dieses Feld aktuell pro Runde einbringt. `null` blendet die
  /// Anzeige aus (z. B. beim Onboarding-Demo-Stapel).
  final int? punkte;

  /// Karte, die gerade über dem Feld schwebt (Drag&Drop). Zeigt dann die
  /// Vorschau, wie sich [punkte] beim Ablegen ändern würde.
  final Karte? vorschauKarte;

  const StapelWidget({
    super.key,
    required this.feld,
    this.ausgewaehlt = false,
    this.hervorgehoben = false,
    this.onTap,
    this.punkte,
    this.vorschauKarte,
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
            if (punkte != null) ...[
              const SizedBox(height: 4),
              _PunkteAnzeige(
                punkte: punkte!,
                nachher: vorschauKarte == null
                    ? null
                    : werteFeld(feld.legeObenauf(vorschauKarte!), 0).punkte,
              ),
            ],
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

/// Punkte pro Runde für ein Feld. Liegt eine Karte im Drag über dem Feld,
/// wird zusätzlich gezeigt, worauf der Wert beim Ablegen springen würde.
class _PunkteAnzeige extends StatelessWidget {
  final int punkte;
  final int? nachher;

  const _PunkteAnzeige({required this.punkte, this.nachher});

  static Color _farbe(int wert) => switch (wert) {
    > 0 => Colors.green.shade700,
    < 0 => Colors.red.shade700,
    _ => Colors.grey.shade600,
  };

  static String _mitVorzeichen(int wert) => wert > 0 ? '+$wert' : '$wert';

  @override
  Widget build(BuildContext context) {
    const stil = TextStyle(fontSize: 12, fontWeight: FontWeight.bold);
    if (nachher == null) {
      return Text(
        _mitVorzeichen(punkte),
        style: stil.copyWith(color: _farbe(punkte)),
      );
    }
    final differenz = nachher! - punkte;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _mitVorzeichen(punkte),
          style: stil.copyWith(
            color: Colors.grey,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        const Text('  →  ', style: TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          _mitVorzeichen(nachher!),
          style: stil.copyWith(color: _farbe(nachher!)),
        ),
        Text(
          ' (${_mitVorzeichen(differenz)})',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _farbe(differenz),
          ),
        ),
      ],
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
