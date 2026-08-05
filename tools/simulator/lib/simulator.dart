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
  final int fuehrungswechsel; // Spieldynamik: wie oft wechselt die Führung?
  final List<int> wertungsWerte; // Punkte je Wertungsphase (Spannungskurve)
  final Map<String, int> gespielteKarten; // Kartenvielfalt

  const Partieergebnis({
    required this.seed,
    required this.zuege,
    required this.abgebrochen,
    required this.gewinnerId,
    required this.startspielerHatGewonnen,
    required this.tiefpunktHeiligkeit,
    required this.punkteJeKategorie,
    required this.punkteJePerson,
    required this.fuehrungswechsel,
    required this.wertungsWerte,
    required this.gespielteKarten,
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
  final wertungsWerte = <int>[];
  final gespielteKarten = <String, int>{};
  var fuehrer = state.spieler
      .reduce((a, b) => a.heiligkeit >= b.heiligkeit ? a : b)
      .id;
  var fuehrungswechsel = 0;

  void zaehleKarteGespielt(String karteId) {
    gespielteKarten.update(karteId, (v) => v + 1, ifAbsent: () => 1);
  }

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
        fuehrungswechsel: fuehrungswechsel,
        wertungsWerte: wertungsWerte,
        gespielteKarten: gespielteKarten,
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

    final aktuellerFuehrer = state.spieler
        .reduce((a, b) => a.heiligkeit >= b.heiligkeit ? a : b)
        .id;
    if (aktuellerFuehrer != fuehrer) {
      fuehrungswechsel++;
      fuehrer = aktuellerFuehrer;
    }

    for (final event in events) {
      switch (event) {
        case KarteGelegt(karteId: final id):
          zaehleKarteGespielt(id);
        case GebietErweitert(karteId: final id):
          zaehleKarteGespielt(id);
        case EvilGespielt(karteId: final id):
          zaehleKarteGespielt(id);
        case SofortGespielt(karteId: final id):
          zaehleKarteGespielt(id);
        case WertungBerechnet(wertung: final wertung):
          wertungsWerte.add(wertung.punkte);
          for (final e in punkteJeKategorie(wertung).entries) {
            kategorieSummen.update(
              e.key,
              (v) => v + e.value,
              ifAbsent: () => e.value,
            );
          }
          for (final e in punkteJePerson(wertung).entries) {
            personSummen.update(
              e.key,
              (v) => v + e.value,
              ifAbsent: () => e.value,
            );
          }
        default:
          break;
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
    fuehrungswechsel: fuehrungswechsel,
    wertungsWerte: wertungsWerte,
    gespielteKarten: gespielteKarten,
  );
}

double median(List<int> werte) {
  if (werte.isEmpty) return 0;
  final sortiert = List<int>.of(werte)..sort();
  final mitte = sortiert.length ~/ 2;
  if (sortiert.length.isOdd) return sortiert[mitte].toDouble();
  return (sortiert[mitte - 1] + sortiert[mitte]) / 2;
}

/// Stichproben-Standardabweichung — Maß für die "Spannungskurve": nahe 0
/// heißt, jede Wertungsphase bringt fast denselben Punktwert (eintönig),
/// sehr hoch heißt stark schwankend (evtl. frustrierend swingy).
double stddev(List<int> werte) {
  if (werte.length < 2) return 0;
  final mittel = werte.reduce((a, b) => a + b) / werte.length;
  final summeQuadrate = werte.fold(
    0.0,
    (s, w) => s + (w - mittel) * (w - mittel),
  );
  return sqrt(summeQuadrate / (werte.length - 1));
}

class SammelErgebnis {
  final int anzahlPartien;
  final int abgebrochen;
  final List<int> zuege;
  final List<int> tiefpunkte;
  final int startspielerSiege;
  final Map<Kategorie, int> kategorieSummen;
  final Map<Person, int> personSummen;
  final List<int> fuehrungswechsel;
  final List<int> alleWertungsWerte;
  final Map<String, int> gespielteKartenGesamt;
  final int kartenpoolGroesse;

  const SammelErgebnis({
    required this.anzahlPartien,
    required this.abgebrochen,
    required this.zuege,
    required this.tiefpunkte,
    required this.startspielerSiege,
    required this.kategorieSummen,
    required this.personSummen,
    required this.fuehrungswechsel,
    required this.alleWertungsWerte,
    required this.gespielteKartenGesamt,
    required this.kartenpoolGroesse,
  });

  int get beendet => anzahlPartien - abgebrochen;
  double get medianZuege => median(zuege);
  double get startspielerWinrate => beendet == 0 ? 0 : startspielerSiege / beendet;
  int get minTiefpunkt => tiefpunkte.isEmpty ? 0 : tiefpunkte.reduce(min);

  double get medianFuehrungswechsel => median(fuehrungswechsel);
  double get wertungsSchwankung => stddev(alleWertungsWerte);

  /// Anteil der Karten aus dem Pool, die in dieser Simulation mindestens
  /// einmal gespielt wurden — niedrig heißt: die Bots nutzen nur einen
  /// kleinen Ausschnitt des Kartensets (wenig Vielfalt in der Praxis).
  double get genutzteKartenvielfalt =>
      kartenpoolGroesse == 0 ? 0 : gespielteKartenGesamt.length / kartenpoolGroesse;

  List<MapEntry<String, int>> meistgespielteKarten({int top = 10}) {
    final sortiert = gespielteKartenGesamt.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortiert.take(top).toList();
  }

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
  final fuehrungswechsel = <int>[];
  final alleWertungsWerte = <int>[];
  final gespielteKartenGesamt = <String, int>{};

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
    fuehrungswechsel.add(ergebnis.fuehrungswechsel);
    alleWertungsWerte.addAll(ergebnis.wertungsWerte);
    for (final e in ergebnis.gespielteKarten.entries) {
      gespielteKartenGesamt.update(e.key, (v) => v + e.value, ifAbsent: () => e.value);
    }
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
    fuehrungswechsel: fuehrungswechsel,
    alleWertungsWerte: alleWertungsWerte,
    gespielteKartenGesamt: gespielteKartenGesamt,
    kartenpoolGroesse: kartenpool.length,
    zuege: zuege,
    tiefpunkte: tiefpunkte,
    startspielerSiege: startspielerSiege,
    kategorieSummen: kategorieSummen,
    personSummen: personSummen,
  );
}
