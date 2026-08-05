import 'dart:io';

import 'package:btcg_engine/engine.dart';
import 'package:simulator/kartenstaerke.dart';

void main(List<String> arguments) {
  var stichproben = 30;
  var seed = 1;
  var inputPfad = '../../data/sets/base.json';

  for (var i = 0; i < arguments.length; i++) {
    switch (arguments[i]) {
      case '--stichproben':
        stichproben = int.parse(arguments[++i]);
      case '--seed':
        seed = int.parse(arguments[++i]);
      case '--input':
        inputPfad = arguments[++i];
    }
  }

  final kartenset = parseKartenset(File(inputPfad).readAsStringSync());

  stderr.writeln(
    'Bewerte Ressourcenkarten ($stichproben Stichproben je Karte, das dauert etwas)...',
  );
  final ergebnisse = bewerteAlleKarten(
    kartenpool: kartenset.alleKarten,
    stichprobengroesse: stichproben,
    startSeed: seed,
    fortschritt: (fertig, gesamt) {
      if (fertig % 10 == 0 || fertig == gesamt) {
        stderr.writeln('  $fertig/$gesamt');
      }
    },
  );

  final sortiert = ergebnisse.toList()
    ..sort((a, b) => b.deltaHeiligkeit.compareTo(a.deltaHeiligkeit));

  final buffer = StringBuffer();
  buffer.writeln('# Kartenstärke — Marginal-Contribution-Analyse');
  buffer.writeln();
  buffer.writeln(
    '> Erzeugt mit `tools/simulator/bin/kartenstaerke.dart` gegen '
    '`data/sets/base.json` (${kartenset.alleKarten.length} Karten). '
    '$stichproben gepaarte Stichproben je Karte, GreedyBot beidseits, '
    'Startseed $seed.',
  );
  buffer.writeln();
  buffer.writeln(
    '**Methodik:** Für jede Ressourcenkarte wird ein zufälliges Deck ohne '
    'sie gebaut ("ohne"), plus eine Variante mit ihr auf einem zufälligen '
    'Ressourcenslot statt einer anderen Karte ("mit") — sonst identisch. '
    'Beide Varianten spielen mit demselben Folge-Seed gegen dasselbe feste '
    'Referenzdeck (gepaarter Vergleich, reduziert Rauschen). '
    '`deltaHeiligkeit`/`deltaWinrate` = Schnitt(mit) − Schnitt(ohne) über '
    'alle Stichproben.',
  );
  buffer.writeln();
  buffer.writeln(
    '**Wichtige Einschränkung — nicht wirklich "wasserdicht":** Das ist eine '
    'Näherung mit einer bestimmten Bot-Heuristik (GreedyBot), einem festen '
    'Referenzdeck und begrenzter Stichprobenzahl. Kartenstärke in diesem '
    'Spiel ist zudem strukturell kontextabhängig (Loch-Ketten, siehe '
    'SIMULATION_PHASE1B.md „Slot-Spezialisierung") — eine Karte ist nur so '
    'viel wert, wie das Deck sie auch sichtbar macht. Für absolute Präzision '
    'bräuchte es eine erschöpfende Analyse aller Deck-Kombinationen, was '
    'praktisch nicht machbar ist. Als *relativer* Vergleich zwischen Karten '
    'ist es trotzdem aussagekräftiger als reines Rohwert-Aufsummieren.',
  );
  buffer.writeln();
  buffer.writeln(
    '**ROADMAP-Leitplanke beachten (KARTEN_SPEZIFIKATION §7):** '
    '"Seltenheit bedeutet Vielfalt, nicht Spielstärke — kein Pay-to-win." '
    'Diese Zahlen sind also kein Vorschlag, starke Karten selten zu machen '
    '(das wäre Pay-to-win) — eher ein Werkzeug, um zu prüfen, dass keine '
    'Karte zu dominant ist, unabhängig von ihrer Seltenheit.',
  );
  buffer.writeln();
  buffer.writeln(
    '`vermutlich signifikant` ist eine grobe Heuristik (Mittelwert > 2 '
    'Standardfehler von 0), kein echter statistischer Test — bei kleinen '
    'Stichproben sind auch als "signifikant" markierte Werte mit Vorsicht '
    'zu lesen.',
  );
  buffer.writeln();
  buffer.writeln('## Ranking (stärkste zuerst)');
  buffer.writeln();
  buffer.writeln(
    '| Karte | Kategorie | Δ Heiligkeit | Streuung (σ) | Δ Winrate | vermutlich signifikant |',
  );
  buffer.writeln('|---|---|---:|---:|---:|---:|');
  for (final e in sortiert) {
    buffer.writeln(
      '| ${e.cardId} (${e.name}) | ${e.kategorie.name} | '
      '${e.deltaHeiligkeit >= 0 ? '+' : ''}${e.deltaHeiligkeit.toStringAsFixed(2)} | '
      '${e.deltaHeiligkeitStreuung.toStringAsFixed(2)} | '
      '${e.deltaWinrate >= 0 ? '+' : ''}${(e.deltaWinrate * 100).toStringAsFixed(1)}% | '
      '${e.vermutlichSignifikant ? 'ja' : 'nein'} |',
    );
  }

  final ausgabePfad = '../../docs/KARTENSTAERKE.md';
  File(ausgabePfad).writeAsStringSync(buffer.toString());

  print('Bericht geschrieben: $ausgabePfad');
  print('');
  print('Top 10 stärkste Karten:');
  for (final e in sortiert.take(10)) {
    print(
      '  ${e.cardId} (${e.name}, ${e.kategorie.name}): '
      'ΔHeiligkeit ${e.deltaHeiligkeit.toStringAsFixed(2)} (σ ${e.deltaHeiligkeitStreuung.toStringAsFixed(2)}), '
      'ΔWinrate ${(e.deltaWinrate * 100).toStringAsFixed(1)}%'
      '${e.vermutlichSignifikant ? ' [signifikant]' : ''}',
    );
  }
  print('');
  print('Bottom 10 schwächste Karten:');
  for (final e in sortiert.reversed.take(10)) {
    print(
      '  ${e.cardId} (${e.name}, ${e.kategorie.name}): '
      'ΔHeiligkeit ${e.deltaHeiligkeit.toStringAsFixed(2)} (σ ${e.deltaHeiligkeitStreuung.toStringAsFixed(2)}), '
      'ΔWinrate ${(e.deltaWinrate * 100).toStringAsFixed(1)}%'
      '${e.vermutlichSignifikant ? ' [signifikant]' : ''}',
    );
  }
}
