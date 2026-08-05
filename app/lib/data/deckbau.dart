import 'dart:math';

import 'package:btcg_engine/engine.dart';

const int kDeckGroesse = 35;
const int kEvilAnzahlImDeck = 7;

/// Baut zufällig ein regelkonformes 35-Karten-Deck (REGELWERK §2): 7
/// unterschiedliche Evil-Karten + 28 Ressourcenkarten (Wiederholungen bis
/// `anzahlImDeckMax`). Bewusst simpel für den Hotseat-Prototyp — ein
/// echter Deckbau-Screen ist ROADMAP Phase 1b/3.
SpielerAufbau baueZufaelligesDeck({
  required String id,
  required String name,
  required List<Karte> alleKarten,
  required Random random,
}) {
  final ressourcen = alleKarten
      .where((k) => k.kategorie != Kategorie.evil && k.kategorie != Kategorie.start)
      .toList();
  final evil = alleKarten.where((k) => k.kategorie == Kategorie.evil).toList()
    ..shuffle(random);
  final eStart = alleKarten.firstWhere((k) => k.kategorie == Kategorie.start);

  final deck = <Karte>[...evil.take(kEvilAnzahlImDeck)];

  final pool = <Karte>[
    for (final karte in ressourcen)
      for (var i = 0; i < karte.anzahlImDeckMax; i++) karte,
  ]..shuffle(random);
  deck.addAll(pool.take(kDeckGroesse - kEvilAnzahlImDeck));

  return SpielerAufbau(id: id, name: name, deck: deck, eStart: eStart);
}
