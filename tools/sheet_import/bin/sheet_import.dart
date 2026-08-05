import 'dart:convert';
import 'dart:io';

import 'package:sheet_import/sheet_import.dart';

void main(List<String> arguments) {
  var eingabePfad = 'docs/Bibelsammelkartenspiel_final.json';
  var ausgabePfad = 'data/sets/base.json';
  var set = 'BASE';
  var version = '0.2.0';

  for (var i = 0; i < arguments.length - 1; i++) {
    switch (arguments[i]) {
      case '--input':
        eingabePfad = arguments[++i];
      case '--output':
        ausgabePfad = arguments[++i];
      case '--set':
        set = arguments[++i];
      case '--version':
        version = arguments[++i];
    }
  }

  final roh = jsonDecode(File(eingabePfad).readAsStringSync()) as Map<String, dynamic>;
  final ergebnis = importiere(roh, set: set);

  if (!ergebnis.istGueltig) {
    stderr.writeln('Import fehlgeschlagen: ${ergebnis.fehler.length} Fehler');
    for (final f in ergebnis.fehler) {
      stderr.writeln('  $f');
    }
    exit(1);
  }

  final json = erzeugeJson(ergebnis, set: set, version: version);
  File(ausgabePfad).writeAsStringSync('$json\n');

  print('Import erfolgreich: $ausgabePfad');
  print('');
  print('Kennzahlen je Kategorie:');
  for (final entry in ergebnis.kennzahlen.entries) {
    final k = entry.value;
    final schnitt = k.anzahl == 0 ? 0.0 : k.wertsumme / k.anzahl;
    final name = entry.key.name.padRight(13);
    final anzahl = k.anzahl.toString().padLeft(3);
    final loecher = k.loecher.toString().padLeft(3);
    final wertsumme = k.wertsumme.toString().padLeft(4);
    print(
      '  $name Karten: $anzahl  Löcher: $loecher  Wertsumme: $wertsumme  '
      'Ø/Karte: ${schnitt.toStringAsFixed(2)}',
    );
  }
}
