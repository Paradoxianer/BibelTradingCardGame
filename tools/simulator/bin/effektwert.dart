import 'dart:io';

import 'package:btcg_engine/engine.dart';
import 'package:simulator/effektwert.dart';

/// Gepaarte Messung, was ein einzelner Effekt wert ist (z. B. #5 umordnung).
/// dart run bin/effektwert.dart --effekt umordnung --spiele 1000
void main(List<String> arguments) {
  var spiele = 1000;
  var seed = 42;
  var effektName = 'umordnung';
  var inputPfad = '../../data/sets/base.json';

  for (var i = 0; i < arguments.length; i++) {
    switch (arguments[i]) {
      case '--spiele':
        spiele = int.parse(arguments[++i]);
      case '--seed':
        seed = int.parse(arguments[++i]);
      case '--effekt':
        effektName = arguments[++i];
      case '--input':
        inputPfad = arguments[++i];
    }
  }

  final Effekt effekt = switch (effektName) {
    'umordnung' => const Umordnung(UmordnungZiel.eigen),
    'erneuerung' => const Erneuerung(2),
    _ => throw ArgumentError('Unbekannter Effekt: $effektName (erwartet: umordnung|erneuerung)'),
  };

  final kartenset = parseKartenset(File(inputPfad).readAsStringSync());
  final referenz = baueZufaelligesDeck(
    id: 'referenz',
    name: 'referenz',
    alleKarten: kartenset.alleKarten,
    seed: seed - 1,
  );

  final e = bewerteEffekt(
    effekt: effekt,
    kartenpool: kartenset.alleKarten,
    referenzAufbau: referenz,
    stichprobengroesse: spiele,
    startSeed: seed,
  );

  print('Effektwert "$effektName": $spiele gepaarte Partien (Greedy vs. Greedy, eine Karte im Deck)');
  print('');
  print('Einsätze: ${e.einsaetze} (wirksam, d. h. Wertung verändert: ${e.wirksameEinsaetze})');
  print('Sofort-Gewinn je Einsatz: Ø ${e.mittlererSofortGewinn.toStringAsFixed(2)} Punkte, '
      'max ${e.maxSofortGewinn}');
  print('Δ Heiligkeit am Partieende: ${e.deltaHeiligkeit.toStringAsFixed(2)} '
      '(Std.-Abw. ${e.deltaHeiligkeitStreuung.toStringAsFixed(1)}, '
      '${e.vermutlichSignifikant ? "vermutlich echt" : "im Rauschen"})');
  print('Δ Siegquote: ${(e.deltaWinrate * 100).toStringAsFixed(1)} Prozentpunkte');
  print('Δ Partiedauer: ${e.deltaZuege.toStringAsFixed(2)} Züge');
}
