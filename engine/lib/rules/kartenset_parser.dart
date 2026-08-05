import 'dart:convert';

import '../model/model.dart';

/// Alle Karten eines Sets (KARTEN_SPEZIFIKATION §5). `tabs` behält die
/// Herkunfts-Struktur, für Deckbau/Simulation reicht meist [alleKarten].
class Kartenset {
  final String set;
  final String version;
  final Map<String, List<Karte>> tabs;
  final List<Karte> alleKarten;

  Kartenset({required this.set, required this.version, required this.tabs})
    : alleKarten = tabs.values.expand((k) => k).toList();
}

/// Parst den Inhalt von `data/sets/*.json` (KARTEN_SPEZIFIKATION §5). Reines
/// Dart, kein I/O — Laden der Datei ist Sache des Aufrufers (App: rootBundle,
/// Simulator: dart:io File), damit die Engine frei von IO/Flutter bleibt.
Kartenset parseKartenset(String jsonText) {
  final json = jsonDecode(jsonText) as Map<String, dynamic>;
  final set = json['set'] as String;
  final tabs = <String, List<Karte>>{
    for (final entry in (json['tabs'] as Map<String, dynamic>).entries)
      entry.key: [
        for (final k in entry.value as List)
          parseKarte(set, k as Map<String, dynamic>),
      ],
  };
  return Kartenset(set: set, version: json['version'] as String, tabs: tabs);
}

const Map<SlotPosition, String> _feldName = {
  SlotPosition.v1: 'V1',
  SlotPosition.v2: 'V2',
  SlotPosition.s1: 'S1',
  SlotPosition.s2: 'S2',
  SlotPosition.hg1: 'HG1',
  SlotPosition.hg2: 'HG2',
};

/// Baut eine [Karte] aus dem Zielformat (KARTEN_SPEZIFIKATION §5). Die
/// Kartentyp-ID folgt §4: `<SET>-<card_id>`.
Karte parseKarte(String set, Map<String, dynamic> json) {
  final cardId = json['card_id'] as String;
  return Karte(
    id: '$set-$cardId',
    cardId: cardId,
    name: json['name'] as String,
    vers: Vers(
      stelle: json['bible_vers'] as String,
      text: json['bible_text'] as String,
    ),
    slots: [
      for (final pos in kSlotOrder)
        SlotSymbol.parse(json[_feldName[pos]] as String),
    ],
    kategorie: kategorieVonString(json['kategorie'] as String),
    seltenheit: json['seltenheit'] as String,
    sofort: json['sofort'] as bool,
    effekt: parseEffekt(json['effekt']),
    anzahlImDeckMax: json['anzahlImDeckMax'] as int,
    pictureLink: json['picture_link'] as String,
  );
}

/// Effekt-Schema nach EFFEKTE.md §3. Aktuell hat keine importierte Karte
/// einen Effekt (siehe KARTEN_SPEZIFIKATION §5, "effects" ist im Bestand
/// fast überall leer) — diese Funktion ist für künftige Kartensets bereit.
Effekt? parseEffekt(dynamic json) {
  if (json == null) return null;
  final map = json as Map<String, dynamic>;
  final typ = map['typ'] as String;
  final parameter = (map['parameter'] as Map<String, dynamic>?) ?? const {};

  return switch (typ) {
    'umkehrung' => Umkehrung((parameter['slots'] as List).cast<int>()),
    'schutz' => Schutz(
      reichweite: parameter['reichweite'] == 'spieler'
          ? SchutzReichweite.spieler
          : SchutzReichweite.feld,
      ladungen: parameter['ladungen'] as int? ?? 1,
    ),
    'gebietserweiterung' => const Gebietserweiterung(),
    'zuwendung' => Zuwendung(
      art: parameter['art'] == 'heiligkeit'
          ? ZuwendungArt.heiligkeit
          : ZuwendungArt.karten,
      menge: parameter['menge'] as int,
    ),
    'globale_aura' => GlobaleAura(parameter['wert'] as int),
    'suche' => Suche(
      switch (parameter['filter']) {
        null || 'beliebig' => null,
        final String f => kategorieVonString(f),
        _ => null,
      },
    ),
    'erneuerung' => Erneuerung(parameter['menge'] as int),
    'umordnung' => Umordnung(
      parameter['ziel'] == 'gegner' ? UmordnungZiel.gegner : UmordnungZiel.eigen,
    ),
    _ => throw FormatException('Unbekannter Effekt-Typ: $typ'),
  };
}
