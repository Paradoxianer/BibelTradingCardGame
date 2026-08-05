import 'dart:io';

import 'package:btcg_engine/bots/bots.dart';
import 'package:btcg_engine/engine.dart';
import 'package:simulator/simulator.dart';

Bot _botFuer(String name) => switch (name) {
  'greedy' => const GreedyBot(),
  'zufall' => const ZufallsBot(),
  _ => throw ArgumentError('Unbekannter Bot: $name (erwartet: greedy|zufall)'),
};

void main(List<String> arguments) {
  var spiele = 300;
  var seed = 42;
  var bot1 = 'greedy';
  var bot2 = 'greedy';
  var mitEvil = true;
  var startspielerVier = false;
  var inputPfad = '../../data/sets/base.json';

  for (var i = 0; i < arguments.length; i++) {
    switch (arguments[i]) {
      case '--spiele':
        spiele = int.parse(arguments[++i]);
      case '--seed':
        seed = int.parse(arguments[++i]);
      case '--bot1':
        bot1 = arguments[++i];
      case '--bot2':
        bot2 = arguments[++i];
      case '--ohne-evil':
        mitEvil = false;
      case '--startspieler-vier':
        startspielerVier = true;
      case '--input':
        inputPfad = arguments[++i];
    }
  }

  final jsonText = File(inputPfad).readAsStringSync();
  final kartenset = parseKartenset(jsonText);

  final config = SimulatorConfig(
    mitEvil: mitEvil,
    startspielerZiehtNurVier: startspielerVier,
  );

  final ergebnis = simuliere(
    anzahlPartien: spiele,
    startSeed: seed,
    kartenpool: kartenset.alleKarten,
    bot1Fabrik: () => _botFuer(bot1),
    bot2Fabrik: () => _botFuer(bot2),
    config: config,
  );

  print('Simulation: $spiele Partien, $bot1 vs. $bot2, '
      'Evil ${mitEvil ? "an" : "aus"}, '
      'D5 (Startspieler 4 Karten) ${startspielerVier ? "an" : "aus"}');
  print('Kartenpool: ${kartenset.alleKarten.length} Karten (Set ${kartenset.set})');
  print('');
  print('Beendet: ${ergebnis.beendet}/${ergebnis.anzahlPartien}'
      ' (abgebrochen: ${ergebnis.abgebrochen})');
  print('Partiedauer (Züge): Median ${ergebnis.medianZuege.toStringAsFixed(1)}, '
      'Min ${ergebnis.zuege.isEmpty ? '-' : ergebnis.zuege.reduce((a, b) => a < b ? a : b)}, '
      'Max ${ergebnis.zuege.isEmpty ? '-' : ergebnis.zuege.reduce((a, b) => a > b ? a : b)}');
  print('Startspieler-Winrate: ${(ergebnis.startspielerWinrate * 100).toStringAsFixed(1)}%'
      ' (Zielwert 48-52%)');
  print('Tiefpunkt Heiligkeit (Minimum über alle Partien): ${ergebnis.minTiefpunkt}');
  print('');
  print('Punktebeitrag je Kategorie (Anteil am Gesamtbetrag, Zielwert < 35%):');
  final kategorieAnteile = ergebnis.kategorieAnteile.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final e in kategorieAnteile) {
    print('  ${e.key.name.padRight(13)} ${(e.value * 100).toStringAsFixed(1)}%'
        ' (Summe ${ergebnis.kategorieSummen[e.key]})');
  }
  print('');
  print('Punktebeitrag je Person (Zielwert < 35%):');
  final personAnteile = ergebnis.personAnteile.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final e in personAnteile) {
    print('  ${e.key.name.padRight(13)} ${(e.value * 100).toStringAsFixed(1)}%'
        ' (Summe ${ergebnis.personSummen[e.key]})');
  }
}
