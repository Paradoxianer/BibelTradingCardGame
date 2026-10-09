import 'dart:math';

import 'package:btcg_engine/bots/bots.dart';
import 'package:btcg_engine/engine.dart';

/// Ergebnis der gepaarten Effekt-Messung: dieselbe Karte einmal ohne, einmal
/// mit [effekt] — Slots, Kategorie, Deckposition und Seeds bleiben gleich,
/// gemessen wird also nur, was der Effekt selbst bringt.
class EffektwertErgebnis {
  final int stichprobengroesse;
  final double deltaHeiligkeit;
  final double deltaHeiligkeitStreuung;
  final double deltaWinrate;
  final double deltaZuege;

  /// Wie oft der Effekt tatsächlich ausgelöst wurde (Karte gebaut).
  final int einsaetze;

  /// Davon: Einsätze, bei denen der Effekt die Wertung direkt verändert hat.
  final int wirksameEinsaetze;

  /// Punkte, die der Effekt im Zug seines Einsatzes direkt bringt: Wertung
  /// mit Effekt minus Wertung, wenn dieselbe Karte ohne Effekt gelegt worden
  /// wäre. Wird jede Runde erneut gewertet, solange die Auslage so bleibt.
  final List<int> sofortGewinne;

  const EffektwertErgebnis({
    required this.stichprobengroesse,
    required this.deltaHeiligkeit,
    required this.deltaHeiligkeitStreuung,
    required this.deltaWinrate,
    required this.deltaZuege,
    required this.einsaetze,
    required this.wirksameEinsaetze,
    required this.sofortGewinne,
  });

  double get mittlererSofortGewinn =>
      sofortGewinne.isEmpty ? 0 : sofortGewinne.reduce((a, b) => a + b) / sofortGewinne.length;

  int get maxSofortGewinn => sofortGewinne.isEmpty ? 0 : sofortGewinne.reduce(max);

  /// Grobe Heuristik wie in kartenstaerke.dart: Mittelwert mehr als 2
  /// Standardfehler von 0 entfernt.
  bool get vermutlichSignifikant =>
      stichprobengroesse > 1 &&
      deltaHeiligkeit.abs() > 2 * deltaHeiligkeitStreuung / sqrt(stichprobengroesse.toDouble());
}

/// Die Variante von [basis] mit [effekt] — eigene ID, sonst wäre sie per
/// `==` nicht vom Original zu unterscheiden.
Karte karteMitEffekt(Karte basis, Effekt effekt, {String suffix = '-EFF'}) => Karte(
  id: '${basis.id}$suffix',
  cardId: basis.cardId,
  name: basis.name,
  vers: basis.vers,
  slots: basis.slots,
  kategorie: basis.kategorie,
  seltenheit: basis.seltenheit,
  sofort: basis.sofort,
  effekt: effekt,
  anzahlImDeckMax: basis.anzahlImDeckMax,
  pictureLink: basis.pictureLink,
);

typedef _Partie = ({int heiligkeit, bool gewonnen, int zuege, int einsaetze, int wirksam, List<int> gewinne});

_Partie _spiele(SpielerAufbau test, SpielerAufbau referenz, int seed, String effektKarteId) {
  final engine = GameEngine();
  var state = neuesSpiel(spieler: [test, referenz], seed: seed);
  const bot = GreedyBot();
  var rng = SeedableRng.seeded(seed + 1);
  var einsaetze = 0;
  var wirksam = 0;
  final gewinne = <int>[];

  for (var i = 0; i < 20000 && state.spielLaeuft; i++) {
    final handelnderId = state.phase == ZugPhase.reaktion
        ? state.pendingEvilOpferId!
        : state.aktiverSpieler.id;
    final (command, neuerRng) = bot.waehleCommand(state, handelnderId, rng);
    rng = neuerRng;

    // Sofort-Gewinn: Vergleich mit derselben Karte ohne Effekt am selben Ort.
    int? ohneEffekt;
    if (command is KarteBauen && command.karteId == effektKarteId) {
      final s = state.spielerMitId(handelnderId);
      final karte = s.hand.firstWhere((k) => k.id == effektKarteId);
      final felder = List<Spielfeld>.of(s.spielfelder);
      felder[command.feldIndex] = felder[command.feldIndex].legeObenauf(karte);
      ohneEffekt = berechneWertung(state.mitSpieler(s.copyWith(spielfelder: felder)), handelnderId).punkte;
    }

    final (neuerState, _) = engine.apply(state, command);
    if (ohneEffekt != null) {
      final mitEffekt = berechneWertung(neuerState, handelnderId).punkte;
      einsaetze++;
      gewinne.add(mitEffekt - ohneEffekt);
      if (mitEffekt != ohneEffekt) wirksam++;
    }
    state = neuerState;
  }

  return (
    heiligkeit: state.spielerMitId(test.id).heiligkeit,
    gewonnen: state.gewinnerId == test.id,
    zuege: state.zugNummer,
    einsaetze: einsaetze,
    wirksam: wirksam,
    gewinne: gewinne,
  );
}

/// Misst den Wert von [effekt] über [stichprobengroesse] gepaarte Partien.
/// Je Stichprobe: Zufallsdeck aus [kartenpool], eine zufällige
/// Ressourcenkarte darin dient als Basis — einmal unverändert, einmal mit
/// [effekt]. Beide Decks spielen mit demselben Seed gegen dasselbe
/// [referenzAufbau] (Greedy gegen Greedy). Das Testdeck beginnt.
EffektwertErgebnis bewerteEffekt({
  required Effekt effekt,
  required List<Karte> kartenpool,
  required SpielerAufbau referenzAufbau,
  required int stichprobengroesse,
  required int startSeed,
}) {
  var summeMit = 0, summeOhne = 0, siegeMit = 0, siegeOhne = 0, zuegeMit = 0, zuegeOhne = 0;
  var einsaetze = 0, wirksam = 0;
  final deltas = <int>[];
  final gewinne = <int>[];

  for (var i = 0; i < stichprobengroesse; i++) {
    final seed = startSeed + i * 10;
    final basis = baueZufaelligesDeck(id: 'test', name: 'test', alleKarten: kartenpool, seed: seed);
    final ressourcen = [
      for (var j = 0; j < basis.deck.length; j++)
        if (basis.deck[j].kategorie != Kategorie.evil && basis.deck[j].effekt == null) j,
    ];
    final (wahl, _) = SeedableRng.seeded(seed + 7).naechsteZahl(ressourcen.length);
    final position = ressourcen[wahl];
    final variante = karteMitEffekt(basis.deck[position], effekt);
    final mitDeck = List<Karte>.of(basis.deck)..[position] = variante;
    final aufbauMit = SpielerAufbau(id: 'test', name: 'test', deck: mitDeck, eStart: basis.eStart);

    final spielSeed = seed + 5000;
    final mit = _spiele(aufbauMit, referenzAufbau, spielSeed, variante.id);
    final ohne = _spiele(basis, referenzAufbau, spielSeed, variante.id);

    summeMit += mit.heiligkeit;
    summeOhne += ohne.heiligkeit;
    deltas.add(mit.heiligkeit - ohne.heiligkeit);
    if (mit.gewonnen) siegeMit++;
    if (ohne.gewonnen) siegeOhne++;
    zuegeMit += mit.zuege;
    zuegeOhne += ohne.zuege;
    einsaetze += mit.einsaetze;
    wirksam += mit.wirksam;
    gewinne.addAll(mit.gewinne);
  }

  final mittel = deltas.reduce((a, b) => a + b) / deltas.length;
  final streuung = deltas.length < 2
      ? 0.0
      : sqrt(deltas.fold(0.0, (s, d) => s + (d - mittel) * (d - mittel)) / (deltas.length - 1));

  return EffektwertErgebnis(
    stichprobengroesse: stichprobengroesse,
    deltaHeiligkeit: (summeMit - summeOhne) / stichprobengroesse,
    deltaHeiligkeitStreuung: streuung,
    deltaWinrate: (siegeMit - siegeOhne) / stichprobengroesse,
    deltaZuege: (zuegeMit - zuegeOhne) / stichprobengroesse,
    einsaetze: einsaetze,
    wirksameEinsaetze: wirksam,
    sofortGewinne: gewinne,
  );
}
