import 'dart:convert';

import 'package:btcg_engine/engine.dart';

class ImportFehler {
  final String kartenId;
  final String nachricht;

  ImportFehler(this.kartenId, this.nachricht);

  @override
  String toString() => '[$kartenId] $nachricht';
}

class KategorieKennzahlen {
  int anzahl = 0;
  int loecher = 0;
  int wertsumme = 0;
}

class ImportErgebnis {
  final Map<String, List<Map<String, dynamic>>> tabs;
  final List<ImportFehler> fehler;
  final Map<Kategorie, KategorieKennzahlen> kennzahlen;

  ImportErgebnis({
    required this.tabs,
    required this.fehler,
    required this.kennzahlen,
  });

  bool get istGueltig => fehler.isEmpty;
}

const Map<String, String> _tabZuKategorie = {
  'R_Gebet': 'gebet',
  'R_Glauben': 'glauben',
  'R_Gottesdienst': 'gottesdienst',
};

const _slotFelder = ['V1', 'V2', 'S1', 'S2', 'HG1', 'HG2'];

/// EStart liegt im Bestand als native Zahlen vor (`-1`), alle anderen Karten
/// als Sheet-Export-Strings (`"-1"`). Beides wird hier vereinheitlicht.
String _slotCode(dynamic wert) => wert is int ? wert.toString() : wert as String;

bool _istSheetFehlerwert(Object? wert) =>
    wert is String && wert.startsWith('#') && wert.endsWith('!');

/// Konvertiert den rohen Sheet-Export (Tab -> card_id -> Felder) nach
/// KARTEN_SPEZIFIKATION §5/§6. `seltenheit` wird per Quartil aus dem
/// Bestandsfeld `rare` abgeleitet — eine Platzhalter-Heuristik (§7 verlangt
/// eine redaktionelle Einstufung, "gestützt auf" `rare`, nicht direkt davon
/// abgeleitet); `sofort` und `anzahlImDeckMax` haben keine Entsprechung im
/// Bestand und werden mit dokumentierten Standardwerten belegt. Beides ist
/// eine spätere redaktionelle/Balancing-Aufgabe (Phase 1b), kein Codethema.
ImportErgebnis importiere(Map<String, dynamic> roh, {required String set}) {
  final fehler = <ImportFehler>[];
  final tabsOut = <String, List<Map<String, dynamic>>>{};
  final kennzahlen = <Kategorie, KategorieKennzahlen>{};
  final gesehenIds = <String>{};

  final alleRareWerte = <double>[];
  for (final tab in roh.values) {
    for (final karte in (tab as Map<String, dynamic>).values) {
      final rare = (karte as Map<String, dynamic>)['rare'];
      if (rare is num && karte['card_id'] != 'EStart') {
        alleRareWerte.add(rare.toDouble());
      }
    }
  }
  alleRareWerte.sort();

  String seltenheitVon(double? rare) {
    if (rare == null || alleRareWerte.isEmpty) return 'haeufig';
    final rang = alleRareWerte.indexOf(rare) / alleRareWerte.length;
    if (rang < 0.25) return 'haeufig';
    if (rang < 0.5) return 'selten';
    if (rang < 0.75) return 'episch';
    return 'einzigartig';
  }

  for (final tabEntry in roh.entries) {
    final tabName = tabEntry.key;
    final karten = tabEntry.value as Map<String, dynamic>;
    final ausgabeListe = <Map<String, dynamic>>[];

    for (final kartenEntry in karten.entries) {
      final rohKarte = kartenEntry.value as Map<String, dynamic>;
      final cardId = rohKarte['card_id'] as String?;
      if (cardId == null || cardId.isEmpty) {
        fehler.add(ImportFehler(kartenEntry.key, 'card_id fehlt oder ist leer'));
        continue;
      }
      if (!gesehenIds.add(cardId)) {
        fehler.add(ImportFehler(cardId, 'card_id ist nicht eindeutig'));
        continue;
      }

      final name = rohKarte['name'] as String?;
      final bibelVers = rohKarte['bible_vers'] as String?;
      final bibelText = rohKarte['bible_text'] as String?;
      if (name == null || name.trim().isEmpty) {
        fehler.add(ImportFehler(cardId, 'name fehlt oder ist leer'));
      }
      if (bibelVers == null || bibelVers.trim().isEmpty) {
        fehler.add(ImportFehler(cardId, 'bible_vers fehlt oder ist leer'));
      }
      if (bibelText == null || bibelText.trim().isEmpty) {
        fehler.add(ImportFehler(cardId, 'bible_text fehlt oder ist leer'));
      }
      if (_istSheetFehlerwert(name) ||
          _istSheetFehlerwert(bibelVers) ||
          _istSheetFehlerwert(bibelText)) {
        fehler.add(ImportFehler(cardId, 'Sheet-Fehlerwert in Text/Namen-Feld'));
      }

      final slots = <SlotSymbol>[];
      var slotFehler = false;
      for (final feld in _slotFelder) {
        final rohWert = rohKarte[feld];
        if (rohWert == null) {
          fehler.add(ImportFehler(cardId, 'Slot $feld fehlt'));
          slotFehler = true;
          continue;
        }
        if (_istSheetFehlerwert(rohWert)) {
          fehler.add(ImportFehler(cardId, 'Sheet-Fehlerwert in $feld: $rohWert'));
          slotFehler = true;
          continue;
        }
        final code = _slotCode(rohWert);
        try {
          slots.add(SlotSymbol.parse(code));
        } catch (_) {
          fehler.add(
            ImportFehler(cardId, 'Ungültiger Slot-Code in $feld: "$code"'),
          );
          slotFehler = true;
        }
      }
      if (slotFehler) continue;

      final istStart = cardId == 'EStart';
      final kategorieStr = istStart
          ? 'start'
          : (_tabZuKategorie[tabName] ?? 'evil');
      final kategorie = kategorieVonString(kategorieStr);

      final anzahlImDeckMax = switch (kategorie) {
        Kategorie.evil => 1,
        Kategorie.start => 1,
        _ => 3, // Platzhalter, Feinjustierung in Phase 1b
      };

      final rare = rohKarte['rare'];
      final seltenheit = istStart
          ? 'einzigartig'
          : seltenheitVon(rare is num ? rare.toDouble() : null);

      final k = kennzahlen.putIfAbsent(kategorie, KategorieKennzahlen.new);
      k.anzahl += 1;
      for (final s in slots) {
        switch (s) {
          case Loch():
            k.loecher += 1;
          case Farbig(wert: final wert):
            k.wertsumme += wert;
          case Schwarz(wert: final wert):
            k.wertsumme += wert;
        }
      }

      ausgabeListe.add({
        'card_id': cardId,
        'name': name,
        'bible_vers': bibelVers,
        'bible_text': bibelText,
        for (final feld in _slotFelder) feld: _slotCode(rohKarte[feld]),
        'kategorie': kategorieStr,
        'seltenheit': seltenheit,
        'sofort': false,
        'effekt': null,
        'anzahlImDeckMax': anzahlImDeckMax,
        'picture_link': rohKarte['picture_link'],
      });
    }

    tabsOut[tabName] = ausgabeListe;
  }

  return ImportErgebnis(tabs: tabsOut, fehler: fehler, kennzahlen: kennzahlen);
}

String erzeugeJson(
  ImportErgebnis ergebnis, {
  required String set,
  required String version,
}) {
  final doc = {'set': set, 'version': version, 'tabs': ergebnis.tabs};
  return const JsonEncoder.withIndent('  ').convert(doc);
}
