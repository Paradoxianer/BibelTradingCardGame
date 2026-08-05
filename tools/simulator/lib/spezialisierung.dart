import 'package:btcg_engine/bots/bots.dart';
import 'package:btcg_engine/engine.dart';

/// Rohwert einer Karte für eine Person: Summe der beiden zugehörigen Slots
/// (Loch = 0, Farbig = eigener Wert, Schwarz = -1) — misst, wie viel eine
/// Karte an dieser Person potenziell beiträgt, falls sie irgendwann durch
/// ein Loch sichtbar wird.
int personStaerke(Karte karte, Person person) {
  final positionen = switch (person) {
    Person.vater => const [SlotPosition.v1, SlotPosition.v2],
    Person.sohn => const [SlotPosition.s1, SlotPosition.s2],
    Person.heiligerGeist => const [SlotPosition.hg1, SlotPosition.hg2],
  };
  var summe = 0;
  for (final pos in positionen) {
    switch (karte.slotAn(pos)) {
      case Farbig(wert: final w):
        summe += w;
      case Schwarz(wert: final w):
        summe += w;
      case Loch():
        break;
    }
  }
  return summe;
}

/// Baut ein Deck, das Ressourcenkarten nach Stärke bei [zielPerson]
/// priorisiert (höchste zuerst, bis anzahlImDeckMax), statt zufällig zu
/// wählen — testet die Nutzer-Hypothese "Deck gezielt auf eine Person
/// ausrichten verschafft einen Vorteil".
SpielerAufbau baueSpezialisiertesDeck({
  required String id,
  required List<Karte> kartenpool,
  required Person zielPerson,
  required int seed,
}) {
  final ressourcen =
      kartenpool
          .where(
            (k) => k.kategorie != Kategorie.evil && k.kategorie != Kategorie.start,
          )
          .toList()
        ..sort(
          (a, b) => personStaerke(b, zielPerson).compareTo(personStaerke(a, zielPerson)),
        );

  final evil = kartenpool.where((k) => k.kategorie == Kategorie.evil).toList();
  final (evilGemischt, _) = mische(evil, SeedableRng.seeded(seed));
  final eStart = kartenpool.firstWhere((k) => k.kategorie == Kategorie.start);

  final ressourcenZiel = kDeckGroesse - kEvilAnzahlImDeck;
  final deck = <Karte>[];
  for (final karte in ressourcen) {
    for (var i = 0; i < karte.anzahlImDeckMax && deck.length < ressourcenZiel; i++) {
      deck.add(karte);
    }
    if (deck.length >= ressourcenZiel) break;
  }
  deck.addAll(evilGemischt.take(kEvilAnzahlImDeck));

  return SpielerAufbau(id: id, name: id, deck: deck, eStart: eStart);
}

class SpezialisierungsErgebnis {
  final Person zielPerson;
  final int anzahlPartien;
  final int spezialistSiege;
  final double avgHeiligkeitSpezialist;
  final double avgHeiligkeitNormal;

  const SpezialisierungsErgebnis({
    required this.zielPerson,
    required this.anzahlPartien,
    required this.spezialistSiege,
    required this.avgHeiligkeitSpezialist,
    required this.avgHeiligkeitNormal,
  });

  double get spezialistWinrate =>
      anzahlPartien == 0 ? 0 : spezialistSiege / anzahlPartien;
}

/// Spielt ein auf [zielPerson] spezialisiertes Deck gegen ein normales
/// Zufallsdeck (beide GreedyBot) und vergleicht Sieg-/Heiligkeitsschnitt.
SpezialisierungsErgebnis vergleicheSpezialisierung({
  required List<Karte> kartenpool,
  required Person zielPerson,
  required int anzahlPartien,
  required int startSeed,
  int maxCommands = 20000,
}) {
  final engine = GameEngine();
  var siege = 0;
  var summeSpezialist = 0;
  var summeNormal = 0;

  for (var i = 0; i < anzahlPartien; i++) {
    final seed = startSeed + i * 10;
    final spezialist = baueSpezialisiertesDeck(
      id: 'spezialist',
      kartenpool: kartenpool,
      zielPerson: zielPerson,
      seed: seed,
    );
    final normal = baueZufaelligesDeck(
      id: 'normal',
      name: 'normal',
      alleKarten: kartenpool,
      seed: seed + 1,
    );
    var state = neuesSpiel(spieler: [spezialist, normal], seed: seed + 2);
    final bots = {'spezialist': const GreedyBot(), 'normal': const GreedyBot()};
    var rng = SeedableRng.seeded(seed + 3);

    for (var j = 0; j < maxCommands; j++) {
      if (!state.spielLaeuft) break;
      final handelnderId = state.phase == ZugPhase.reaktion
          ? state.pendingEvilOpferId!
          : state.aktiverSpieler.id;
      final (command, neuerRng) = bots[handelnderId]!.waehleCommand(
        state,
        handelnderId,
        rng,
      );
      rng = neuerRng;
      final (neuerState, _) = engine.apply(state, command);
      state = neuerState;
    }

    summeSpezialist += state.spielerMitId('spezialist').heiligkeit;
    summeNormal += state.spielerMitId('normal').heiligkeit;
    if (state.gewinnerId == 'spezialist') siege++;
  }

  return SpezialisierungsErgebnis(
    zielPerson: zielPerson,
    anzahlPartien: anzahlPartien,
    spezialistSiege: siege,
    avgHeiligkeitSpezialist: summeSpezialist / anzahlPartien,
    avgHeiligkeitNormal: summeNormal / anzahlPartien,
  );
}
