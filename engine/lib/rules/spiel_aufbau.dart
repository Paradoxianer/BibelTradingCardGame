import '../model/model.dart';

/// Deck eines Spielers vor Spielbeginn: 35 Karten (REGELWERK §2) plus die
/// EStart-Karte, die separat auf Feld 1 gelegt wird (§4) und nicht Teil der
/// gemischten 35 ist.
class SpielerAufbau {
  final String id;
  final String name;
  final List<Karte> deck; // exakt 35 Karten, davon 7 unterschiedliche Evil
  final Karte eStart;

  const SpielerAufbau({
    required this.id,
    required this.name,
    required this.deck,
    required this.eStart,
  });
}

/// Baut den Startzustand nach REGELWERK §4: Decks mischen, EStart auf Feld 1,
/// 5 Handkarten (bzw. 4 für den Startspieler bei aktivem D5-Flag), zufälliger
/// Startspieler.
GameState neuesSpiel({
  required List<SpielerAufbau> spieler,
  required int seed,
  RegelConfig config = const RegelConfig(),
}) {
  assert(spieler.length >= 2);
  var rng = SeedableRng.seeded(seed);

  final (startIndex, rngNachStart) = rng.naechsteZahl(spieler.length);
  rng = rngNachStart;
  final reihenfolge = [
    for (var i = 0; i < spieler.length; i++)
      spieler[(startIndex + i) % spieler.length],
  ];

  final ergebnis = <Spieler>[];
  for (var i = 0; i < reihenfolge.length; i++) {
    final aufbau = reihenfolge[i];
    final (gemischtesDeck, rngNachMischen) = mische(aufbau.deck, rng);
    rng = rngNachMischen;

    final handGroesse = (i == 0 && config.startspielerZiehtNurVier) ? 4 : 5;
    final hand = gemischtesDeck.take(handGroesse).toList();
    final deckRest = gemischtesDeck.skip(handGroesse).toList();

    ergebnis.add(
      Spieler(
        id: aufbau.id,
        name: aufbau.name,
        hand: hand,
        deck: deckRest,
        spielfelder: [
          Spielfeld([Kartenlage(aufbau.eStart)]),
          const Spielfeld(),
          const Spielfeld(),
        ],
      ),
    );
  }

  return GameState(spieler: ergebnis, aktiverIndex: 0, rng: rng, config: config);
}
