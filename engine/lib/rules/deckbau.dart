import '../model/model.dart';
import 'spiel_aufbau.dart';

const int kDeckGroesse = 35;
const int kEvilAnzahlImDeck = 7;

/// Baut zufällig ein regelkonformes 35-Karten-Deck (REGELWERK §2): 7
/// unterschiedliche Evil-Karten + 28 Ressourcenkarten (Wiederholungen bis
/// `anzahlImDeckMax`). Genutzt von App (Hotseat-Prototyp) und Simulator —
/// ein echter Deckbau-Screen ist ROADMAP Phase 3.
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
