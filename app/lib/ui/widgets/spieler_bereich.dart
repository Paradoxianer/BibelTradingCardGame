import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';

import 'karten_widget.dart';

/// Ein Spielerbereich — **für jeden Spieler gleich aufgebaut**: Name und
/// Heiligkeit, die drei Spielfelder, der Ziehstapel und die Handkarten.
///
/// Unterschieden wird nur, was die Regeln vorgeben: die eigene Hand liegt
/// offen und die eigenen Felder nehmen Karten an, fremde Handkarten liegen
/// verdeckt (REGELWERK D9) und fremde Felder sind nur Evil-Ziel. Die
/// Anordnung bleibt identisch, damit das Brett symmetrisch wirkt.
class SpielerBereich extends StatelessWidget {
  final Spieler spieler;
  final bool eigen;
  final bool amZug;

  /// Punkte je Spielfeld; leer, wenn sie nicht angezeigt werden sollen.
  final List<int> feldPunkte;

  /// Baut ein Spielfeld. Erlaubt dem Aufrufer, Drag-Ziele und Tap-Verhalten
  /// beizusteuern, ohne dass dieser Bereich die Spiellogik kennen muss.
  final Widget Function(BuildContext, int feldIndex) feldBauen;

  /// Baut eine offene Handkarte (nur im eigenen Bereich genutzt).
  final Widget Function(BuildContext, Karte)? handkarteBauen;

  const SpielerBereich({
    super.key,
    required this.spieler,
    required this.eigen,
    required this.amZug,
    required this.feldBauen,
    this.feldPunkte = const [],
    this.handkarteBauen,
  });

  static const double _feldBreite = 120;
  static const double _kleinBreite = 74;

  @override
  Widget build(BuildContext context) {
    final handBreite = eigen ? _feldBreite : _kleinBreite;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: amZug ? 0.16 : 0.30),
        border: Border.all(
          color: amZug ? Colors.amber.shade700 : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        // Man sitzt sich gegenüber: beim Gegenspieler liegt die Hand auf
        // seiner Seite, also außen — deshalb ist seine Reihenfolge gedreht.
        children: eigen ? _reihen(context, handBreite) : _reihen(context, handBreite).reversed.toList(),
      ),
    );
  }

  List<Widget> _reihen(BuildContext context, double handBreite) => [
    _Kopfzeile(spieler: spieler, amZug: amZug),
    const SizedBox(height: 6),
    // Felder und Ziehstapel mittig — wie auf einem Tisch zwischen den
    // Spielern.
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < spieler.spielfelder.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                feldBauen(context, i),
                if (i < feldPunkte.length) ...[
                  const SizedBox(height: 2),
                  _Punkte(feldPunkte[i]),
                ],
              ],
            ),
          ),
        const SizedBox(width: 12),
        _Ziehstapel(deck: spieler.deck, breite: _kleinBreite),
      ],
    ),
    const SizedBox(height: 8),
    _Hand(
      spieler: spieler,
      eigen: eigen,
      breite: handBreite,
      handkarteBauen: handkarteBauen,
    ),
  ];
}

class _Kopfzeile extends StatelessWidget {
  final Spieler spieler;
  final bool amZug;

  const _Kopfzeile({required this.spieler, required this.amZug});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        spieler.name,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: amZug ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      const SizedBox(width: 10),
      const Icon(Icons.auto_awesome, size: 14, color: Colors.amber),
      const SizedBox(width: 3),
      Text(
        '${spieler.heiligkeit}',
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        'Hand ${spieler.hand.length}',
        style: const TextStyle(fontSize: 11, color: Colors.white70),
      ),
    ],
  );
}

class _Punkte extends StatelessWidget {
  final int wert;
  const _Punkte(this.wert);

  @override
  Widget build(BuildContext context) => Text(
    wert > 0 ? '+$wert' : '$wert',
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: wert > 0
          ? Colors.greenAccent
          : wert < 0
          ? Colors.redAccent
          : Colors.white54,
    ),
  );
}

/// Oberste Deckkarte verdeckt plus Restanzahl. Ein leeres Deck ist sichtbar
/// leer — es wird dann nicht mehr nachgezogen (REGELWERK D2).
class _Ziehstapel extends StatelessWidget {
  final List<Karte> deck;
  final double breite;

  const _Ziehstapel({required this.deck, required this.breite});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (deck.isEmpty)
        Container(
          width: breite,
          height: breite * 0.92,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black12,
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(breite / 14),
          ),
          child: const Text(
            'leer',
            style: TextStyle(fontSize: 10, color: Colors.white54),
          ),
        )
      else
        KartenWidget.verdeckt(deck.first, breite: breite),
      const SizedBox(height: 2),
      Text(
        deck.isEmpty ? 'Deck leer' : '${deck.length} im Deck',
        style: const TextStyle(fontSize: 10, color: Colors.white70),
      ),
    ],
  );
}

class _Hand extends StatelessWidget {
  final Spieler spieler;
  final bool eigen;
  final double breite;
  final Widget Function(BuildContext, Karte)? handkarteBauen;

  const _Hand({
    required this.spieler,
    required this.eigen,
    required this.breite,
    required this.handkarteBauen,
  });

  @override
  Widget build(BuildContext context) {
    if (spieler.hand.isEmpty) {
      return const Center(
        child: Text(
          'keine Handkarten',
          style: TextStyle(fontSize: 11, color: Colors.white54),
        ),
      );
    }
    // Zentriert, solange die Hand hineinpasst; sonst waagerecht scrollbar.
    // Die Mindestbreite sorgt dafür, dass die Zeile den Platz ausfüllt und
    // ihre Karten dadurch mittig stehen.
    return SizedBox(
      height: breite * 0.92 + 6,
      child: LayoutBuilder(
        builder: (context, grenzen) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: grenzen.maxWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final karte in spieler.hand)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: eigen && handkarteBauen != null
                        ? handkarteBauen!(context, karte)
                        : KartenWidget.verdeckt(karte, breite: breite),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
