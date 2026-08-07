import 'package:flutter/rendering.dart';

import 'slot_layout.dart';

/// Stanzt die Löcher wirklich aus der Karte heraus.
///
/// Bis hierher war ein Loch nur gemalt; dadurch sah man an der Stelle den
/// weißen Karton statt dessen, was darunter liegt. Mit dieser Ausstanzung
/// wird die Karte dort tatsächlich durchsichtig — im Stapel scheint die
/// Karte darunter durch, sonst das Spielbrett. Genau wie bei einer echten
/// gestanzten Karte (ARCHITEKTUR §3).
class LochStanzung extends CustomClipper<Path> {
  /// Indizes (0 … 5) der Zellen, die ein Loch tragen.
  final List<int> loecher;
  final SlotLayout layout;
  final double eckenRadius;

  const LochStanzung({
    required this.loecher,
    required this.layout,
    required this.eckenRadius,
  });

  @override
  Path getClip(Size size) {
    final karte = Path()..addRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(eckenRadius),
      ),
    );
    if (loecher.isEmpty) return karte;

    final stanzungen = Path();
    for (final i in loecher) {
      stanzungen.addOval(
        Rect.fromCircle(center: layout.mitte(i), radius: layout.lochRadius),
      );
    }
    return Path.combine(PathOperation.difference, karte, stanzungen);
  }

  @override
  bool shouldReclip(LochStanzung alt) =>
      alt.eckenRadius != eckenRadius ||
      alt.layout.zelle != layout.zelle ||
      alt.layout.oben != layout.oben ||
      alt.layout.kartenBreite != layout.kartenBreite ||
      !_gleich(alt.loecher, loecher);

  static bool _gleich(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
