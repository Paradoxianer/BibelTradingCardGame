import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:btcg_app/ui/widgets/karten_widget.dart';
import 'package:btcg_app/ui/widgets/loch_stanzung.dart';
import 'package:btcg_app/ui/widgets/slot_layout.dart';
import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const Color _hintergrund = Color(0xFFFF0000);

Karte _karte(List<String> slots) => Karte(
  id: 'k',
  cardId: 'k',
  name: 'k',
  vers: const Vers(stelle: '', text: ''),
  slots: slots.map(SlotSymbol.parse).toList(),
  kategorie: Kategorie.gebet,
  seltenheit: 'haeufig',
  sofort: false,
  effekt: null,
  anzahlImDeckMax: 3,
  pictureLink: '',
);

SlotLayout _layoutFuer(double breite) =>
    SlotLayout(kartenBreite: breite, zelle: breite / 8.2, oben: breite / 40);

/// Rendert die Karte über knallrotem Grund und liest die Farben an den
/// Slot-Mitten aus. Nur wo wirklich ausgestanzt ist, kommt Rot durch.
Future<List<Color>> _farbenAnSlots(
  WidgetTester tester,
  Karte karte,
  double breite,
) async {
  final schluessel = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      home: RepaintBoundary(
        key: schluessel,
        child: ColoredBox(
          color: _hintergrund,
          child: Center(
            child: KartenWidget.handkarte(karte, breite: breite),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));

  late ui.Image bild;
  ByteData? daten;
  await tester.runAsync(() async {
    final grenze =
        schluessel.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    bild = await grenze.toImage();
    daten = await bild.toByteData(format: ui.ImageByteFormat.rawRgba);
  });

  final ecke = tester
      .renderObject<RenderBox>(find.byType(KartenWidget))
      .localToGlobal(Offset.zero);
  final layout = _layoutFuer(breite);
  final bytes = daten!.buffer.asUint8List();

  return [
    for (var i = 0; i < 6; i++)
      () {
        final p = ecke + layout.mitte(i);
        final o = (p.dy.round() * bild.width + p.dx.round()) * 4;
        return Color.fromARGB(
          bytes[o + 3],
          bytes[o],
          bytes[o + 1],
          bytes[o + 2],
        );
      }(),
  ];
}

void main() {
  testWidgets('durch ein Loch scheint der Hintergrund, sonst deckt die Karte', (
    tester,
  ) async {
    final farben = await _farbenAnSlots(
      tester,
      _karte(['x', '1', 'x', '-1', '0', '2']),
      240,
    );

    expect(farben[0], _hintergrund, reason: 'V1 ist ein Loch');
    expect(farben[2], _hintergrund, reason: 'S1 ist ein Loch');
    for (final i in [1, 3, 4, 5]) {
      expect(farben[i], isNot(_hintergrund), reason: 'Slot $i hat kein Loch');
    }
  });

  testWidgets('auch auf kleinen Karten wird gestanzt', (tester) async {
    // Die Handkarten im Spiel sind klein; dort war der Ring zeitweise
    // dünner als ein Pixel und die Stanzung nicht mehr zu erkennen.
    final farben = await _farbenAnSlots(tester, _karte(['x', '1', '1', '1', '1', '1']), 120);
    expect(farben[0], _hintergrund);
    expect(farben[1], isNot(_hintergrund));
  });

  group('SlotLayout', () {
    test('Ring bleibt auch auf kleinen Karten sichtbar dick', () {
      final klein = _layoutFuer(120);
      expect(klein.ringDicke, greaterThanOrEqualTo(1.5));
      expect(klein.lochRadius, greaterThan(0));
      // Auf großen Karten gilt wieder das Originalverhältnis.
      final gross = _layoutFuer(320);
      expect(gross.ringDicke / gross.symbolRadius, closeTo(1 - 121.5 / 143.5, 0.02));
    });

    test('sechs Zellen mittig und gleichmäßig', () {
      final l = _layoutFuer(240);
      final mitten = [for (var i = 0; i < 6; i++) l.mitte(i)];
      for (var i = 1; i < 6; i++) {
        expect(mitten[i].dx - mitten[i - 1].dx, closeTo(l.zelle + SlotLayout.abstand, 0.001));
      }
      expect((mitten.first.dx + mitten.last.dx) / 2, closeTo(120, 0.001));
    });
  });

  test('Stanzung erzeugt je Loch eine eigene Kontur im Clip-Pfad', () {
    final layout = _layoutFuer(120);
    Path pfad(List<int> loecher) => LochStanzung(
      loecher: loecher,
      layout: layout,
      eckenRadius: 8,
    ).getClip(const Size(120, 110));

    expect(pfad([]).computeMetrics().length, 1, reason: 'nur die Kartenform');
    expect(pfad([0, 2, 4]).computeMetrics().length, 4);
  });
}
