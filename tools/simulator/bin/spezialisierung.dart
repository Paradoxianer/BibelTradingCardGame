import 'dart:io';

import 'package:btcg_engine/engine.dart';
import 'package:simulator/spezialisierung.dart';

void main(List<String> arguments) {
  var spiele = 300;
  var seed = 1;
  var inputPfad = '../../data/sets/base.json';

  for (var i = 0; i < arguments.length; i++) {
    switch (arguments[i]) {
      case '--spiele':
        spiele = int.parse(arguments[++i]);
      case '--seed':
        seed = int.parse(arguments[++i]);
      case '--input':
        inputPfad = arguments[++i];
    }
  }

  final kartenset = parseKartenset(File(inputPfad).readAsStringSync());

  print('Slot-Spezialisierungs-Test: $spiele Partien je Person, GreedyBot beidseits');
  print('Spezialist (Deck priorisiert nach Personenstärke) vs. normales Zufallsdeck');
  print('');

  for (final person in Person.values) {
    final ergebnis = vergleicheSpezialisierung(
      kartenpool: kartenset.alleKarten,
      zielPerson: person,
      anzahlPartien: spiele,
      startSeed: seed,
    );
    print('Spezialisiert auf ${person.name}:');
    print('  Winrate Spezialist: ${(ergebnis.spezialistWinrate * 100).toStringAsFixed(1)}%'
        ' (Referenz ohne Vorteil: 50%)');
    print('  Ø Heiligkeit Spezialist: ${ergebnis.avgHeiligkeitSpezialist.toStringAsFixed(1)}'
        '  |  Ø Heiligkeit Normal: ${ergebnis.avgHeiligkeitNormal.toStringAsFixed(1)}');
    print('');
  }
}
