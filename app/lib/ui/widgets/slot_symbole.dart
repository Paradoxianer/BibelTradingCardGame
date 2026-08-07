import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';

import 'slot_layout.dart';

/// Was in einer Slot-Spalte zu sehen ist. [verdeckt] blendet den Wert aus und
/// zeigt nur, ob dort ein Loch ist (REGELWERK D9).
typedef SlotAnzeige = ({SlotPosition pos, SlotSymbol symbol, bool verdeckt});

/// Die sechs Symbole einer Karte, in Anzeigereihenfolge.
List<SlotAnzeige> slotsFuerKarte(Karte karte) => [
  for (final pos in kSlotOrder)
    (pos: pos, symbol: karte.slotAn(pos), verdeckt: false),
];

/// Verdeckte Karte: nur die Stanzungen sind zu sehen, die Werte nicht — eine
/// Stanzung ist auch von hinten ein Loch (REGELWERK D9).
///
/// Die Reihenfolge ist **gespiegelt**: eine umgedrehte Karte zeigt ihre
/// Löcher seitenverkehrt.
List<SlotAnzeige> slotsFuerVerdeckteKarte(Karte karte) => [
  for (final pos in kSlotOrder.reversed)
    (
      pos: pos,
      symbol: karte.slotAn(pos),
      verdeckt: karte.slotAn(pos) is! Loch,
    ),
];

/// Farbe der Person, der ein Slot gehört (aus dem Original-Artwork).
Color personenFarbe(SlotPosition pos) => switch (pos) {
  SlotPosition.v1 || SlotPosition.v2 => const Color(0xFFFF420E), // Vater
  SlotPosition.s1 || SlotPosition.s2 => const Color(0xFF579D1C), // Sohn
  SlotPosition.hg1 || SlotPosition.hg2 => const Color(0xFFFFD320), // Hl. Geist
};

/// Zeichnet die sechs Slot-Symbole einer Karte.
///
/// Gezeichnet statt als Bild geladen: so bleiben die Symbole in jeder Größe
/// scharf, und — wichtiger — Zeichnung und [LochStanzung] rechnen mit
/// **demselben** [SlotLayout]. Ein Loch kann dadurch gar nicht mehr neben
/// seiner Stanzung liegen.
class SlotSymbole extends StatelessWidget {
  final List<SlotAnzeige> zellen;
  final SlotLayout layout;

  const SlotSymbole({super.key, required this.zellen, required this.layout});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _SlotPainter(zellen: zellen, layout: layout));
}

class _SlotPainter extends CustomPainter {
  final List<SlotAnzeige> zellen;
  final SlotLayout layout;

  const _SlotPainter({required this.zellen, required this.layout});

  /// Weiße Kontur, damit die schwarzen Formen auf dunklem Grund stehen.
  static const double _konturAnteil = 0.075;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < zellen.length; i++) {
      _zelle(canvas, zellen[i], layout.mitte(i));
    }
  }

  void _zelle(Canvas canvas, SlotAnzeige zelle, Offset mitte) {
    final r = layout.symbolRadius;
    final kontur = layout.zelle * _konturAnteil;
    final ringDicke = layout.ringDicke;

    if (zelle.verdeckt) {
      // Rückseite: nur die Stanzung ist ablesbar, kein Wert.
      canvas.drawCircle(
        mitte,
        r,
        Paint()..color = Colors.white.withValues(alpha: 0.55),
      );
      return;
    }

    final zaehlt = zelle.symbol is Loch || zelle.symbol is Schwarz;
    if (zaehlt) _dreiecke(canvas, mitte, kontur);

    switch (zelle.symbol) {
      case Loch():
        // Beim Loch nur eine weiße Kontur **außen** um den Ring — eine
        // gefüllte Scheibe würde die Öffnung zusetzen, durch die man sehen
        // soll. Die Mitte bleibt frei und wird aus der Karte gestanzt.
        canvas.drawCircle(
          mitte,
          r + kontur / 2,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = kontur,
        );
        canvas.drawCircle(
          mitte,
          r - ringDicke / 2,
          Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = ringDicke,
        );
      case Schwarz():
        canvas.drawCircle(mitte, r + kontur, Paint()..color = Colors.white);
        canvas.drawCircle(mitte, r, Paint()..color = Colors.black);
        // Minus-Balken.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: mitte,
              width: r * 1.05,
              height: r * 0.30,
            ),
            Radius.circular(r * 0.15),
          ),
          Paint()..color = Colors.white,
        );
      case Farbig(wert: final wert):
        canvas.drawCircle(mitte, r + kontur, Paint()..color = Colors.white);
        canvas.drawCircle(mitte, r, Paint()..color = personenFarbe(zelle.pos));
        canvas.drawCircle(
          mitte,
          r - ringDicke / 2,
          Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = ringDicke,
        );
        _ziffer(canvas, mitte, wert, r);
    }
  }

  /// Die Dreiecke ober- und unterhalb bedeuten „dieser Wert zählt" — sie
  /// tragen `-1` (zählt immer) und das Loch (macht das Zählen möglich).
  void _dreiecke(Canvas canvas, Offset mitte, double kontur) {
    final r = layout.symbolRadius;
    final halbeBasis = layout.zelle * 0.145;
    final spitze = r * 0.98;
    final basis = layout.zelle / 2;

    for (final richtung in [-1.0, 1.0]) {
      final pfad = Path()
        ..moveTo(mitte.dx - halbeBasis, mitte.dy + richtung * basis)
        ..lineTo(mitte.dx + halbeBasis, mitte.dy + richtung * basis)
        ..lineTo(mitte.dx, mitte.dy + richtung * spitze)
        ..close();
      canvas.drawPath(
        pfad,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = kontur * 2
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(pfad, Paint()..color = Colors.black);
    }
  }

  void _ziffer(Canvas canvas, Offset mitte, int wert, double r) {
    final maler = TextPainter(
      text: TextSpan(
        text: '$wert',
        style: TextStyle(
          color: Colors.black,
          fontSize: r * 1.5,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    maler.paint(
      canvas,
      mitte - Offset(maler.width / 2, maler.height / 2),
    );
  }

  @override
  bool shouldRepaint(_SlotPainter alt) =>
      alt.layout.zelle != layout.zelle ||
      alt.layout.oben != layout.oben ||
      alt.layout.kartenBreite != layout.kartenBreite ||
      !_gleich(alt.zellen, zellen);

  static bool _gleich(List<SlotAnzeige> a, List<SlotAnzeige> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].pos != b[i].pos ||
          a[i].symbol != b[i].symbol ||
          a[i].verdeckt != b[i].verdeckt) {
        return false;
      }
    }
    return true;
  }
}
