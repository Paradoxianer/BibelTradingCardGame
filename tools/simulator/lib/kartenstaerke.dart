import 'dart:math';

import 'package:btcg_engine/bots/bots.dart';
import 'package:btcg_engine/engine.dart';

class KartenstaerkeErgebnis {
  final String cardId;
  final String name;
  final Kategorie kategorie;
  final int stichprobengroesse;
  final double deltaHeiligkeit;
  final double deltaHeiligkeitStreuung; // Stichproben-Std.-Abw. der Paar-Deltas
  final double deltaWinrate;

  const KartenstaerkeErgebnis({
    required this.cardId,
    required this.name,
    required this.kategorie,
    required this.stichprobengroesse,
    required this.deltaHeiligkeit,
    required this.deltaHeiligkeitStreuung,
    required this.deltaWinrate,
  });

  /// Grobe Heuristik, keine echte Signifikanzprüfung: der Mittelwert ist
  /// mehr als 2 Standardfehler von 0 entfernt. Dient nur dazu, im Bericht
  /// zwischen "vermutlich echter Unterschied" und "im Rauschen" zu
  /// unterscheiden — kein Ersatz für einen echten Test.
  bool get vermutlichSignifikant =>
      stichprobengroesse > 1 &&
      deltaHeiligkeit.abs() >
          2 * deltaHeiligkeitStreuung / sqrt(stichprobengroesse.toDouble());
}

/// Tauscht eine zufällige Ressourcenkarte (nicht Evil/Start) im Deck gegen
/// [neueKarte] aus — für den gepaarten "mit vs. ohne"-Vergleich muss sich
/// sonst nichts am Deck ändern.
List<Karte> _ersetzeEineRessourcenkarte(
  List<Karte> deck,
  Karte neueKarte,
  int seed,
) {
  final rng = SeedableRng.seeded(seed);
  final ressourcenIndizes = [
    for (var i = 0; i < deck.length; i++)
      if (deck[i].kategorie != Kategorie.evil && deck[i].kategorie != Kategorie.start)
        i,
  ];
  final (wahlIndex, _) = rng.naechsteZahl(ressourcenIndizes.length);
  final kopie = List<Karte>.of(deck);
  kopie[ressourcenIndizes[wahlIndex]] = neueKarte;
  return kopie;
}

({int heiligkeit, bool hatGewonnen}) _spieleGegenReferenz(
  GameEngine engine,
  SpielerAufbau aufbau,
  SpielerAufbau referenzAufbau,
  int seed, {
  int maxCommands = 20000,
}) {
  var state = neuesSpiel(spieler: [aufbau, referenzAufbau], seed: seed);
  final bots = {aufbau.id: const GreedyBot(), referenzAufbau.id: const GreedyBot()};
  var rng = SeedableRng.seeded(seed + 1);

  for (var i = 0; i < maxCommands; i++) {
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

  final spieler = state.spielerMitId(aufbau.id);
  return (
    heiligkeit: spieler.heiligkeit,
    hatGewonnen: state.gewinnerId == aufbau.id,
  );
}

/// Misst die "Stärke" von [karte] als gepaarte Marginal-Contribution:
/// dasselbe Zufallsdeck (aus [kartenpool] ohne [karte] gebaut) einmal mit
/// [karte] auf einem zufälligen Ressourcenslot, einmal ohne — beide gegen
/// dasselbe [referenzAufbau], mit demselben Folge-Seed (paarweiser
/// Vergleich reduziert Rauschen gegenüber unabhängigen Stichproben).
KartenstaerkeErgebnis bewerteKarte({
  required Karte karte,
  required List<Karte> kartenpool,
  required SpielerAufbau referenzAufbau,
  required int stichprobengroesse,
  required int startSeed,
}) {
  final poolOhneKarte = kartenpool.where((k) => k.id != karte.id).toList();
  final engine = GameEngine();

  var summeMit = 0;
  var summeOhne = 0;
  var siegeMit = 0;
  var siegeOhne = 0;
  final paarDeltas = <int>[];

  for (var i = 0; i < stichprobengroesse; i++) {
    final seed = startSeed + i * 10;
    final basisAufbau = baueZufaelligesDeck(
      id: 'test',
      name: 'test',
      alleKarten: poolOhneKarte,
      seed: seed,
    );
    final mitDeck = _ersetzeEineRessourcenkarte(basisAufbau.deck, karte, seed);
    final aufbauMit = SpielerAufbau(
      id: 'test',
      name: 'test',
      deck: mitDeck,
      eStart: basisAufbau.eStart,
    );

    final spielSeed = seed + 5000;
    final ergebnisMit = _spieleGegenReferenz(engine, aufbauMit, referenzAufbau, spielSeed);
    final ergebnisOhne = _spieleGegenReferenz(engine, basisAufbau, referenzAufbau, spielSeed);

    summeMit += ergebnisMit.heiligkeit;
    summeOhne += ergebnisOhne.heiligkeit;
    paarDeltas.add(ergebnisMit.heiligkeit - ergebnisOhne.heiligkeit);
    if (ergebnisMit.hatGewonnen) siegeMit++;
    if (ergebnisOhne.hatGewonnen) siegeOhne++;
  }

  return KartenstaerkeErgebnis(
    cardId: karte.id,
    name: karte.name,
    kategorie: karte.kategorie,
    stichprobengroesse: stichprobengroesse,
    deltaHeiligkeit: (summeMit - summeOhne) / stichprobengroesse,
    deltaHeiligkeitStreuung: _stichprobenStddev(paarDeltas),
    deltaWinrate: (siegeMit - siegeOhne) / stichprobengroesse,
  );
}

double _stichprobenStddev(List<int> werte) {
  if (werte.length < 2) return 0;
  final mittel = werte.reduce((a, b) => a + b) / werte.length;
  final summeQuadrate = werte.fold(
    0.0,
    (s, w) => s + (w - mittel) * (w - mittel),
  );
  return sqrt(summeQuadrate / (werte.length - 1));
}

/// Bewertet alle Ressourcenkarten (Evil/Start ausgeklammert — andere
/// Mechanik, siehe docs/KARTENSTAERKE.md) gegen ein festes Referenzdeck.
List<KartenstaerkeErgebnis> bewerteAlleKarten({
  required List<Karte> kartenpool,
  required int stichprobengroesse,
  required int startSeed,
  void Function(int fertig, int gesamt)? fortschritt,
}) {
  final referenzAufbau = baueZufaelligesDeck(
    id: 'referenz',
    name: 'referenz',
    alleKarten: kartenpool,
    seed: startSeed - 1,
  );
  final ressourcenKarten = kartenpool
      .where((k) => k.kategorie != Kategorie.evil && k.kategorie != Kategorie.start)
      .toList();

  final ergebnisse = <KartenstaerkeErgebnis>[];
  for (var i = 0; i < ressourcenKarten.length; i++) {
    ergebnisse.add(
      bewerteKarte(
        karte: ressourcenKarten[i],
        kartenpool: kartenpool,
        referenzAufbau: referenzAufbau,
        stichprobengroesse: stichprobengroesse,
        startSeed: startSeed + i * 100000,
      ),
    );
    fortschritt?.call(i + 1, ressourcenKarten.length);
  }
  return ergebnisse;
}
