import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';

import 'loch_stanzung.dart';
import 'slot_layout.dart';
import 'slot_zeile.dart';

/// Wie viel einer Karte gezeigt wird. **Kein** zweites Design: in beiden
/// Fällen dieselben Elemente in derselben Gestaltung, nur unterschiedlich
/// dicht angeordnet (ARCHITEKTUR §3).
enum KartenAnsicht {
  /// Hand, Spielfeld, Ziehstapel: Slot-Kreise und Namensleiste liegen auf
  /// dem Artwork, Bibeltext und Effekt entfallen — etwa halbe Höhe.
  kompakt,

  /// Detailansicht: Slot-Zeile, Artwork, Name, Bibeltext mit Versangabe,
  /// Effekt und card_id.
  voll,
}

/// Rahmenfarbe nach Seltenheit — dadurch ist auch in der kompakten Ansicht
/// immer erkennbar, wie selten eine Karte ist (KARTEN_SPEZIFIKATION §7).
Color seltenheitsFarbe(String seltenheit) => switch (seltenheit) {
  'einzigartig' => const Color(0xFFD4AF37), // Gold
  'episch' => const Color(0xFF8E44AD), // Violett
  'selten' => const Color(0xFF2E86C1), // Blau
  _ => const Color(0xFF7F8C8D), // Grau, häufig
};

const String _artworkKlein = 'assets/artwork/Placeholder_klein.jpg';

/// Die **einzige** Kartendarstellung der App — für Handkarten, Spielfelder,
/// Ziehstapel und Rückseiten. Eine physische Karte ist ein Objekt und sieht
/// überall gleich aus; deshalb gibt es genau eine Gestaltung.
class KartenWidget extends StatelessWidget {
  /// `null` = leeres Spielfeld.
  final Karte? karte;

  /// Immer 6 Zellen, in Anzeigereihenfolge.
  final List<SlotAnzeige> slots;

  final KartenAnsicht ansicht;
  final double breite;
  final bool rueckseite;

  const KartenWidget({
    super.key,
    required this.karte,
    required this.slots,
    this.ansicht = KartenAnsicht.kompakt,
    this.breite = 120,
    this.rueckseite = false,
  });

  factory KartenWidget.handkarte(
    Karte karte, {
    Key? key,
    KartenAnsicht ansicht = KartenAnsicht.kompakt,
    double breite = 120,
  }) => KartenWidget(
    key: key,
    karte: karte,
    slots: SlotZeile.fuerKarte(karte).zellen,
    ansicht: ansicht,
    breite: breite,
  );

  /// Verdeckte Karte: fremde Hand oder oberste Deckkarte (REGELWERK D9).
  factory KartenWidget.verdeckt(
    Karte karte, {
    Key? key,
    double breite = 120,
  }) => KartenWidget(
    key: key,
    karte: karte,
    slots: SlotZeile.fuerVerdeckteKarte(karte).zellen,
    breite: breite,
    rueckseite: true,
  );

  static double hoeheFuer(double breite, KartenAnsicht ansicht) =>
      ansicht == KartenAnsicht.voll ? breite * 1.5 : breite * 0.92;

  double get _hoehe => hoeheFuer(breite, ansicht);
  double get _zelle => breite / 8.2;
  double get _eckenRadius => breite / 14;

  SlotLayout get _layout => SlotLayout(
    kartenBreite: breite,
    zelle: _zelle,
    oben: breite / 40,
  );

  @override
  Widget build(BuildContext context) {
    final k = karte;
    if (k == null) return _LeeresFeld(breite: breite, hoehe: _hoehe);

    final loecher = [
      for (var i = 0; i < slots.length; i++)
        if (slots[i].symbol is Loch && !slots[i].verdeckt) i,
    ];

    return SizedBox(
      width: breite,
      height: _hoehe,
      // Erst ausstanzen, dann zeichnen: an den Lochstellen ist die Karte
      // wirklich durchsichtig, dort scheint durch, was darunter liegt.
      child: ClipPath(
        clipper: LochStanzung(
          loecher: loecher,
          layout: _layout,
          eckenRadius: _eckenRadius,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: seltenheitsFarbe(k.seltenheit),
              width: breite / 40,
            ),
            borderRadius: BorderRadius.circular(_eckenRadius),
          ),
          child: ansicht == KartenAnsicht.voll
              ? _VolleKarte(karte: k, slots: slots, breite: breite, layout: _layout)
              : _KompakteKarte(
                  karte: k,
                  slots: slots,
                  breite: breite,
                  layout: _layout,
                  rueckseite: rueckseite,
                ),
        ),
      ),
    );
  }
}

/// Ein Spielfeld: die Karten liegen **wirklich** übereinander, exakt
/// deckungsgleich (die Slots aller Karten sitzen an derselben Stelle,
/// KARTEN_SPEZIFIKATION §1). Was durch ein Loch zu sehen ist, ergibt sich
/// dadurch von selbst aus der Stapelung — es muss nicht ausgerechnet werden.
class StapelWidget extends StatelessWidget {
  final Spielfeld feld;
  final double breite;

  const StapelWidget({super.key, required this.feld, this.breite = 120});

  @override
  Widget build(BuildContext context) {
    final hoehe = KartenWidget.hoeheFuer(breite, KartenAnsicht.kompakt);
    if (feld.istLeer) return _LeeresFeld(breite: breite, hoehe: hoehe);

    return SizedBox(
      width: breite,
      height: hoehe,
      child: Stack(
        children: [
          // Unterste Karte zuerst, oberste zuletzt.
          for (final lage in feld.stapel.reversed)
            Positioned.fill(
              child: KartenWidget.handkarte(lage.karte, breite: breite),
            ),
        ],
      ),
    );
  }
}

/// Leeres Spielfeld — kein Karton, nur ein Ablageplatz auf dem Brett.
class _LeeresFeld extends StatelessWidget {
  final double breite;
  final double hoehe;

  const _LeeresFeld({required this.breite, required this.hoehe});

  @override
  Widget build(BuildContext context) => Container(
    width: breite,
    height: hoehe,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white38, width: breite / 40),
      borderRadius: BorderRadius.circular(breite / 14),
    ),
    child: const Text(
      'leer',
      style: TextStyle(fontSize: 10, color: Colors.white54),
    ),
  );
}

/// Kompakt: Artwork als Fläche, Slot-Kreise oben darauf, Namensleiste unten
/// darauf. Dieselben Elemente wie in der Vollansicht, nur verdichtet.
class _KompakteKarte extends StatelessWidget {
  final Karte karte;
  final List<SlotAnzeige> slots;
  final double breite;
  final SlotLayout layout;
  final bool rueckseite;

  const _KompakteKarte({
    required this.karte,
    required this.slots,
    required this.breite,
    required this.layout,
    required this.rueckseite,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (rueckseite) const _Rueckseitenmuster() else const _Artwork(),
        _SlotBand(slots: slots, layout: layout, breite: breite),
        if (!rueckseite)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _Namensleiste(karte: karte, breite: breite),
          ),
      ],
    );
  }
}

/// Voll: Slot-Zeile, Artwork, Name, Bibeltext mit Versangabe, Effekt, card_id.
class _VolleKarte extends StatelessWidget {
  final Karte karte;
  final List<SlotAnzeige> slots;
  final double breite;
  final SlotLayout layout;

  const _VolleKarte({
    required this.karte,
    required this.slots,
    required this.breite,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final klein = TextStyle(fontSize: breite / 26, color: Colors.grey.shade700);
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: layout.oben + layout.zelle + breite / 40),
            AspectRatio(aspectRatio: 1373 / 971, child: const _Artwork()),
            _Namensleiste(karte: karte, breite: breite),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(breite / 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          karte.vers.text,
                          style: TextStyle(fontSize: breite / 24, height: 1.25),
                        ),
                      ),
                    ),
                    Text(
                      karte.vers.stelle,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: breite / 24,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: breite / 40),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            karte.effekt == null
                                ? ''
                                : karte.effekt.runtimeType.toString(),
                            style: klein,
                          ),
                        ),
                        Text(karte.cardId, style: klein),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        _SlotBand(slots: slots, layout: layout, breite: breite),
      ],
    );
  }
}

/// Die Slot-Zeile an genau der Stelle, an der auch gestanzt wird.
class _SlotBand extends StatelessWidget {
  final List<SlotAnzeige> slots;
  final SlotLayout layout;
  final double breite;

  const _SlotBand({
    required this.slots,
    required this.layout,
    required this.breite,
  });

  @override
  Widget build(BuildContext context) => Positioned(
    top: layout.oben,
    left: layout.startX,
    child: SlotZeile(zellen: slots, groesse: layout.zelle),
  );
}

class _Namensleiste extends StatelessWidget {
  final Karte karte;
  final double breite;

  const _Namensleiste({required this.karte, required this.breite});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: breite / 26,
        vertical: breite / 40,
      ),
      color: Colors.white.withValues(alpha: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            karte.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: breite / 13,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          if (karte.vers.stelle.isNotEmpty)
            Text(
              karte.vers.stelle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: breite / 17,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
        ],
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork();

  @override
  Widget build(BuildContext context) => Image.asset(
    _artworkKlein,
    fit: BoxFit.cover,
    errorBuilder: (context, fehler, spur) =>
        ColoredBox(color: Colors.blueGrey.shade100),
  );
}

class _Rueckseitenmuster extends StatelessWidget {
  const _Rueckseitenmuster();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.indigo.shade300, Colors.indigo.shade700],
      ),
    ),
  );
}
