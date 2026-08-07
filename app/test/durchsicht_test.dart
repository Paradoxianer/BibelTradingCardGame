import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:btcg_app/bloc/game_bloc.dart';
import 'package:btcg_app/ui/screens/spiel_screen.dart';
import 'package:btcg_app/ui/widgets/karten_widget.dart';
import 'package:btcg_app/ui/widgets/slot_layout.dart';
import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'test_storage.dart';

/// Prüft am **echten Spielbrett**, dass ein Loch tatsächlich durchsichtig ist.
///
/// Der Laborfall (Karte über einfarbigem Grund) war lange grün, obwohl im
/// Spiel nichts durchzuscheinen schien: dort lag hinter den Karten ein heller
/// Bereich, das Loch zeigte also hellgrau und wirkte wie ein weißer Punkt.
/// Deshalb vergleicht dieser Test die Farbe im Loch mit der Farbe **neben**
/// der Karte — beide müssen gleich sein — und stellt zusätzlich sicher, dass
/// sich der Untergrund von der Karte selbst deutlich abhebt.
Karte _k(
  String id,
  List<String> s, {
  Kategorie kat = Kategorie.gebet,
  int max = 3,
}) => Karte(
  id: id,
  cardId: id,
  name: id,
  vers: const Vers(stelle: 'X 1,1', text: 't'),
  slots: s.map(SlotSymbol.parse).toList(),
  kategorie: kat,
  seltenheit: 'haeufig',
  sofort: false,
  effekt: null,
  anzahlImDeckMax: max,
  pictureLink: '',
);

Kartenset _kartenset() => Kartenset(
  set: 'T',
  version: '1',
  tabs: {
    'R': [
      // Jede Handkarte hat ein Loch an V1.
      for (var i = 0; i < 20; i++) _k('r$i', ['x', '1', '1', '1', '1', '1']),
      for (var i = 0; i < 7; i++)
        _k(
          'e$i',
          ['-1', '-1', '-1', '-1', '-1', '-1'],
          kat: Kategorie.evil,
          max: 1,
        ),
      _k('estart', [
        '-1',
        '-1',
        '-1',
        '-1',
        '-1',
        '-1',
      ], kat: Kategorie.start),
    ],
  },
);

double _helligkeit(Color c) => (c.r + c.g + c.b) / 3;

/// Der Bretthintergrund ist ein Verlauf, benachbarte Stellen unterscheiden
/// sich daher minimal. Toleranz von einem Farbschritt.
Matcher _wieFarbe(Color erwartet) => predicate<Color>(
  (c) =>
      (c.r - erwartet.r).abs() < 0.01 &&
      (c.g - erwartet.g).abs() < 0.01 &&
      (c.b - erwartet.b).abs() < 0.01,
  'nahezu $erwartet',
);

void main() {
  setUp(() => HydratedBloc.storage = SpeicherImArbeitsspeicher());

  testWidgets('durch das Loch einer Handkarte sieht man das Spielbrett', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final kartenset = _kartenset();
    final bloc = GameBloc(
      kartenset: kartenset,
      seed: 5,
      aufbauListe: [
        baueZufaelligesDeck(
          id: 'p1',
          name: 'p1',
          alleKarten: kartenset.alleKarten,
          seed: 1,
        ),
        baueZufaelligesDeck(
          id: 'p2',
          name: 'p2',
          alleKarten: kartenset.alleKarten,
          seed: 2,
        ),
      ],
    );
    addTearDown(bloc.close);

    final schluessel = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: schluessel,
          child: BlocProvider.value(
            value: bloc,
            child: SpielScreen(onNeuesSpiel: () {}),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    late ui.Image bild;
    ByteData? daten;
    await tester.runAsync(() async {
      final grenze = schluessel.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      bild = await grenze.toImage();
      daten = await bild.toByteData(format: ui.ImageByteFormat.rawRgba);
    });
    final bytes = daten!.buffer.asUint8List();

    Color farbeAn(Offset p) {
      final o = (p.dy.round() * bild.width + p.dx.round()) * 4;
      return Color.fromARGB(
        bytes[o + 3],
        bytes[o],
        bytes[o + 1],
        bytes[o + 2],
      );
    }

    final karte = find
        .descendant(
          of: find.byType(Draggable<Karte>).first,
          matching: find.byType(KartenWidget),
        )
        .first;
    final box = tester.renderObject<RenderBox>(karte);
    final ecke = box.localToGlobal(Offset.zero);
    final breite = box.size.width;
    final layout = SlotLayout(
      kartenBreite: breite,
      zelle: breite / 8.2,
      oben: breite / 40,
    );

    final imLoch = farbeAn(ecke + layout.mitte(0));
    final nebenDerKarte = farbeAn(ecke + Offset(-8, breite / 2));
    final aufDerKarte = farbeAn(ecke + Offset(breite / 2, breite * 0.55));

    expect(
      imLoch,
      _wieFarbe(nebenDerKarte),
      reason: 'im Loch muss dasselbe zu sehen sein wie neben der Karte',
    );
    expect(
      (_helligkeit(imLoch) - _helligkeit(aufDerKarte)).abs(),
      greaterThan(0.25),
      reason: 'der Untergrund muss sich klar von der Karte abheben, '
          'sonst ist das Loch nicht als Loch erkennbar',
    );
  });
}
