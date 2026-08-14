import '../model/model.dart';
import 'spiel_aufbau.dart';

const int kDeckGroesse = 35;
const int kEvilAnzahlImDeck = 7;

/// Baut zufällig ein regelkonformes 35-Karten-Deck (REGELWERK §2): 7
/// unterschiedliche Evil-Karten + 28 Ressourcenkarten (Wiederholungen bis
/// `anzahlImDeckMax`). Genutzt von Simulator, Bot-Gegner und als
/// Schnellstart-Fallback in der App, wenn (noch) kein eigenes Deck
/// gespeichert ist (Deckbau-Screen, Issue #17).
SpielerAufbau baueZufaelligesDeck({
  required String id,
  required String name,
  required List<Karte> alleKarten,
  required int seed,
}) {
  var rng = SeedableRng.seeded(seed);

  final ressourcen = alleKarten
      .where((k) => k.kategorie != Kategorie.evil && k.kategorie != Kategorie.start)
      .toList();
  final eStart = alleKarten.firstWhere((k) => k.kategorie == Kategorie.start);

  final (evilGemischt, rng1) = mische(
    alleKarten.where((k) => k.kategorie == Kategorie.evil).toList(),
    rng,
  );
  rng = rng1;

  final pool = <Karte>[
    for (final karte in ressourcen)
      for (var i = 0; i < karte.anzahlImDeckMax; i++) karte,
  ];
  final (poolGemischt, rng2) = mische(pool, rng);
  rng = rng2;

  final deck = <Karte>[
    ...evilGemischt.take(kEvilAnzahlImDeck),
    ...poolGemischt.take(kDeckGroesse - kEvilAnzahlImDeck),
  ];

  return SpielerAufbau(id: id, name: name, deck: deck, eStart: eStart);
}

/// Prüft ein selbst zusammengestelltes Deck gegen REGELWERK §2. Leere Liste
/// heißt gültig — sonst je Verstoß ein für Spieler:innen lesbarer Satz, damit
/// der Deckbau-Screen sie direkt anzeigen kann.
List<String> pruefeDeck(List<Karte> deck) {
  final fehler = <String>[];

  if (deck.any((k) => k.kategorie == Kategorie.start)) {
    fehler.add('Die Startkarte gehört nicht ins Deck, sie liegt automatisch aus.');
  }

  final evil = deck.where((k) => k.kategorie == Kategorie.evil).toList();
  if (evil.length != kEvilAnzahlImDeck) {
    fehler.add('${evil.length} von genau $kEvilAnzahlImDeck Evil-Karten.');
  }
  if (evil.map((k) => k.id).toSet().length != evil.length) {
    fehler.add('Evil-Karten müssen alle unterschiedlich sein.');
  }

  final anzahlJeId = <String, int>{};
  for (final karte in deck) {
    anzahlJeId[karte.id] = (anzahlJeId[karte.id] ?? 0) + 1;
  }
  final karteNachId = {for (final k in deck) k.id: k};
  for (final eintrag in anzahlJeId.entries) {
    final karte = karteNachId[eintrag.key]!;
    if (eintrag.value > karte.anzahlImDeckMax) {
      fehler.add(
        '"${karte.name}" ${eintrag.value}× im Deck, erlaubt sind höchstens '
        '${karte.anzahlImDeckMax}.',
      );
    }
  }

  if (deck.length != kDeckGroesse) {
    fehler.add('${deck.length} von genau $kDeckGroesse Karten.');
  }

  return fehler;
}
