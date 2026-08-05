import 'dart:math';

import 'package:btcg_engine/bots/bots.dart';
import 'package:btcg_engine/engine.dart';

/// Ob Evil überhaupt gespielt werden darf (REGELWERK §7 Baseline-Messung
/// vergleicht "mit Evil" gegen "ohne Evil" bei sonst identischem Deck).
class SimulatorConfig {
  final bool mitEvil;
  final bool startspielerZiehtNurVier; // D5-Zusatzoption

  const SimulatorConfig({
    this.mitEvil = true,
    this.startspielerZiehtNurVier = false,
  });
}

class Partieergebnis {
  final int seed;
  final int zuege;
  final bool abgebrochen; // Zug-Limit erreicht statt echtem Spielende
  final String? gewinnerId;
  final bool startspielerHatGewonnen;
  final int tiefpunktHeiligkeit;
  final Map<Kategorie, int> punkteJeKategorie;
  final Map<Person, int> punkteJePerson;

  const Partieergebnis({
    required this.seed,
    required this.zuege,
    required this.abgebrochen,
    required this.gewinnerId,
    required this.startspielerHatGewonnen,
    required this.tiefpunktHeiligkeit,
    required this.punkteJeKategorie,
    required this.punkteJePerson,
  });
}

/// Baut das Deck für eine Partie. Bei `mitEvil: false` ganz ohne Evil-Karten
/// (35 Ressourcenkarten statt 28+7) — nur so lässt sich Evils Effekt auf die
/// Partiedauer isoliert messen (REGELWERK §7 Baseline "Partiedauer ohne
/// Evil"). Ein reines Bot-Verhaltens-Flag ("Evil nie spielen") reicht nicht:
/// gezogene, nie spielbare Evil-Karten blockieren dauerhaft Handplätze und
/// stoppen so das Nachziehen, obwohl das Deck noch Karten hätte (Deadlock).
SpielerAufbau _baueDeck({
  required String id,
  required List<Karte> kartenpool,
  required int seed,
  required bool mitEvil,
}) {
  if (mitEvil) {
    return baueZufaelligesDeck(id: id, name: id, alleKarten: kartenpool, seed: seed);
  }
  final ressourcen = kartenpool
      .where((k) => k.kategorie != Kategorie.evil && k.kategorie != Kategorie.start)
      .toList();
  final eStart = kartenpool.firstWhere((k) => k.kategorie == Kategorie.start);
  final pool = [
    for (final karte in ressourcen)
      for (var i = 0; i < karte.anzahlImDeckMax; i++) karte,
  ];
  final (gemischt, _) = mische(pool, SeedableRng.seeded(seed));
  return SpielerAufbau(
    id: id,
    name: id,
    deck: gemischt.take(kDeckGroesse).toList(),
    eStart: eStart,
  );
}

/// Spielt eine einzelne Partie zweier Bots gegeneinander und sammelt dabei
/// Metriken (ROADMAP Phase 1b): Partiedauer, Startspieler-Sieg, Tiefpunkt
/// Heiligkeit, Punktebeitrag je Kategorie/Person über die ganze Partie.
Partieergebnis spielePartieMitMetriken({
  required int seed,
  required List<Karte> kartenpool,
  required Bot bot1,
  required Bot bot2,
  SimulatorConfig config = const SimulatorConfig(),
  int maxCommands = 20000,
}) {
  final aufbau = [
    _baueDeck(id: 'p1', kartenpool: kartenpool, seed: seed, mitEvil: config.mitEvil),
    _baueDeck(id: 'p2', kartenpool: kartenpool, seed: seed + 1, mitEvil: config.mitEvil),
  ];
  var state = neuesSpiel(
    spieler: aufbau,
    seed: seed + 2,
    config: RegelConfig(startspielerZiehtNurVier: config.startspielerZiehtNurVier),
  );
  final startspielerId = state.spieler[0].id;

  final engine = GameEngine();
  final bots = {'p1': bot1, 'p2': bot2};
  var rng = SeedableRng.seeded(seed + 3);

  var tiefpunkt = state.spieler.map((s) => s.heiligkeit).reduce(min);
  final kategorieSummen = <Kategorie, int>{};
  final personSummen = <Person, int>{};

  for (var i = 0; i < maxCommands; i++) {
    if (!state.spielLaeuft) {
      return Partieergebnis(
        seed: seed,
        zuege: state.zugNummer,
        abgebrochen: false,
        gewinnerId: state.gewinnerId,
        startspielerHatGewonnen: state.gewinnerId == startspielerId,
        tiefpunktHeiligkeit: tiefpunkt,
        punkteJeKategorie: kategorieSummen,
        punkteJePerson: personSummen,
      );
    }

    final istEvilPhaseDeaktiviert =
        state.phase == ZugPhase.evilSpielen && !config.mitEvil;
    final handelnderId = state.phase == ZugPhase.reaktion
        ? state.pendingEvilOpferId!
        : state.aktiverSpieler.id;

    final Command command;
    if (istEvilPhaseDeaktiviert) {
      command = const Passen();
    } else {
      final (gewaehlt, neuerRng) = bots[handelnderId]!.waehleCommand(
        state,
        handelnderId,
        rng,
      );
      rng = neuerRng;
      command = gewaehlt;
    }

    final (neuerState, events) = engine.apply(state, command);
    state = neuerState;

    final aktuellesMin = state.spieler.map((s) => s.heiligkeit).reduce(min);
    if (aktuellesMin < tiefpunkt) tiefpunkt = aktuellesMin;

    for (final event in events) {
      if (event is! WertungBerechnet) continue;
      for (final e in punkteJeKategorie(event.wertung).entries) {
        kategorieSummen.update(e.key, (v) => v + e.value, ifAbsent: () => e.value);
      }
      for (final e in punkteJePerson(event.wertung).entries) {
        personSummen.update(e.key, (v) => v + e.value, ifAbsent: () => e.value);
      }
    }
  }

  return Partieergebnis(
    seed: seed,
    zuege: state.zugNummer,
    abgebrochen: true,
    gewinnerId: null,
    startspielerHatGewonnen: false,
    tiefpunktHeiligkeit: tiefpunkt,
    punkteJeKategorie: kategorieSummen,
    punkteJePerson: personSummen,
  );
}

double median(List<int> werte) {
  if (werte.isEmpty) return 0;
  final sortiert = List<int>.of(werte)..sort();
  final mitte = sortiert.length ~/ 2;
  if (sortiert.length.isOdd) return sortiert[mitte].toDouble();
  return (sortiert[mitte - 1] + sortiert[mitte]) / 2;
}

class SammelErgebnis {
  final int anzahlPartien;
  final int abgebrochen;
  final List<int> zuege;
  final List<int> tiefpunkte;
  final int startspielerSiege;
  final Map<Kategorie, int> kategorieSummen;
  final Map<Person, int> personSummen;

  const SammelErgebnis({
    required this.anzahlPartien,
    required this.abgebrochen,
    required this.zuege,
    required this.tiefpunkte,
    required this.startspielerSiege,
    required this.kategorieSummen,
    required this.personSummen,
  });

  int get beendet => anzahlPartien - abgebrochen;
  double get medianZuege => median(zuege);
  double get startspielerWinrate => beendet == 0 ? 0 : startspielerSiege / beendet;
  int get minTiefpunkt => tiefpunkte.isEmpty ? 0 : tiefpunkte.reduce(min);

  Map<Kategorie, double> get kategorieAnteile {
    // Nenner ist die Summe der Beträge je Kategorie, nicht der Betrag der
    // Netto-Summe — sonst können sich positive und negative Kategorien
    // gegenseitig aufheben und Anteile über 100% ergeben.
    final gesamt = kategorieSummen.values.fold(0, (a, b) => a + b.abs());
    if (gesamt == 0) return {};
    return {
      for (final e in kategorieSummen.entries) e.key: e.value.abs() / gesamt,
    };
  }

  Map<Person, double> get personAnteile {
    final gesamt = personSummen.values.fold(0, (a, b) => a + b.abs());
    if (gesamt == 0) return {};
    return {
      for (final e in personSummen.entries) e.key: e.value.abs() / gesamt,
    };
  }
}

/// Führt [anzahlPartien] Partien mit fortlaufenden Seeds und frisch erzeugten
/// Bot-Instanzen (Fabrikfunktionen — Bots sind i. d. R. zustandslos, aber so
/// bleibt jede Partie unabhängig) durch und sammelt die Metriken.
SammelErgebnis simuliere({
  required int anzahlPartien,
  required int startSeed,
  required List<Karte> kartenpool,
  required Bot Function() bot1Fabrik,
  required Bot Function() bot2Fabrik,
  SimulatorConfig config = const SimulatorConfig(),
}) {
  final zuege = <int>[];
  final tiefpunkte = <int>[];
  var startspielerSiege = 0;
  var abgebrochen = 0;
  final kategorieSummen = <Kategorie, int>{};
  final personSummen = <Person, int>{};

  for (var i = 0; i < anzahlPartien; i++) {
    final seed = startSeed + i * 10;
    final ergebnis = spielePartieMitMetriken(
      seed: seed,
      kartenpool: kartenpool,
      bot1: bot1Fabrik(),
      bot2: bot2Fabrik(),
      config: config,
    );
    zuege.add(ergebnis.zuege);
    tiefpunkte.add(ergebnis.tiefpunktHeiligkeit);
    if (ergebnis.abgebrochen) {
      abgebrochen++;
      continue;
    }
    if (ergebnis.startspielerHatGewonnen) startspielerSiege++;
    for (final e in ergebnis.punkteJeKategorie.entries) {
      kategorieSummen.update(e.key, (v) => v + e.value, ifAbsent: () => e.value);
    }
    for (final e in ergebnis.punkteJePerson.entries) {
      personSummen.update(e.key, (v) => v + e.value, ifAbsent: () => e.value);
    }
  }

  return SammelErgebnis(
    anzahlPartien: anzahlPartien,
    abgebrochen: abgebrochen,
    zuege: zuege,
    tiefpunkte: tiefpunkte,
    startspielerSiege: startspielerSiege,
    kategorieSummen: kategorieSummen,
    personSummen: personSummen,
  );
}
