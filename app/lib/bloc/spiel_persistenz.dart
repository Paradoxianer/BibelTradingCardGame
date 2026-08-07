import 'package:btcg_engine/bots/bots.dart';
import 'package:btcg_engine/engine.dart';

/// Persistenz über Seed + Command-Verlauf statt über den vollen GameState-
/// Objektgraphen: die Engine ist deterministisch (ARCHITEKTUR §2 —
/// "Gleicher Seed + gleiche Commands = gleiches Spiel"), also reicht es,
/// beim Wiederherstellen den ursprünglichen Deckaufbau neu zu mischen und
/// alle bisherigen Commands erneut anzuwenden.
class GespeichertePartie {
  final List<SpielerAufbau> aufbauListe;
  final int seed;
  final RegelConfig config;
  final Map<String, Bot> botSpieler;
  final int botSeed;
  final List<Command> verlauf;

  const GespeichertePartie({
    required this.aufbauListe,
    required this.seed,
    required this.config,
    required this.botSpieler,
    required this.botSeed,
    required this.verlauf,
  });
}

Map<String, dynamic> gespeichertePartieZuJson({
  required Kartenset kartenset,
  required List<SpielerAufbau> aufbauListe,
  required int seed,
  required RegelConfig config,
  required Map<String, Bot> botSpieler,
  required int botSeed,
  required List<Command> verlauf,
}) => {
  'kartensetSet': kartenset.set,
  'kartensetVersion': kartenset.version,
  'seed': seed,
  'startspielerZiehtNurVier': config.startspielerZiehtNurVier,
  'aufbau': [
    for (final a in aufbauListe)
      {
        'id': a.id,
        'name': a.name,
        'deck': [for (final k in a.deck) k.id],
        'eStart': a.eStart.id,
      },
  ],
  'botSpieler': {for (final e in botSpieler.entries) e.key: botTypName(e.value)},
  'botSeed': botSeed,
  'verlauf': [for (final c in verlauf) commandZuJson(c)],
};

/// Parst eine gespeicherte Partie. Liefert `null`, wenn die Kartendaten sich
/// seit dem Speichern geändert haben (Set/Version passt nicht mehr) oder das
/// JSON sonst nicht zum aktuellen Kartenset passt — dann startet der
/// Aufrufer besser neu, statt mit inkonsistenten Daten weiterzumachen.
GespeichertePartie? parseGespeichertePartie(
  Map<String, dynamic> json,
  Kartenset kartenset,
) {
  try {
    if (json['kartensetSet'] != kartenset.set ||
        json['kartensetVersion'] != kartenset.version) {
      return null;
    }
    final karteNachId = {for (final k in kartenset.alleKarten) k.id: k};
    Karte nachschlagen(String id) {
      final karte = karteNachId[id];
      if (karte == null) throw FormatException('Karte nicht gefunden: $id');
      return karte;
    }

    final aufbauListe = [
      for (final a in json['aufbau'] as List)
        SpielerAufbau(
          id: (a as Map)['id'] as String,
          name: a['name'] as String,
          deck: [for (final id in a['deck'] as List) nachschlagen(id as String)],
          eStart: nachschlagen(a['eStart'] as String),
        ),
    ];

    // `Map<String, dynamic>.from(...)` statt eines direkten `as`-Casts: aus
    // echtem Storage (Hive/IndexedDB) kommen verschachtelte Maps zur
    // Laufzeit oft als `Map<dynamic, dynamic>` zurück, nicht als
    // `Map<String, dynamic>` wie bei handgebautem/jsonDecode-JSON — ein
    // direkter Cast würde dort mit einer TypeError scheitern.
    final botSpielerJson = Map<String, dynamic>.from(json['botSpieler'] as Map);
    final botSpieler = {
      for (final e in botSpielerJson.entries) e.key: botVonName(e.value as String),
    };

    final verlauf = [
      for (final c in json['verlauf'] as List)
        commandVonJson(Map<String, dynamic>.from(c as Map)),
    ];

    return GespeichertePartie(
      aufbauListe: aufbauListe,
      seed: json['seed'] as int,
      config: RegelConfig(
        startspielerZiehtNurVier: json['startspielerZiehtNurVier'] as bool,
      ),
      botSpieler: botSpieler,
      botSeed: json['botSeed'] as int,
      verlauf: verlauf,
    );
  } catch (_) {
    return null;
  }
}

String botTypName(Bot bot) => switch (bot) {
  GreedyBot() => 'greedy',
  ZufallsBot() => 'zufall',
  DefensivBot() => 'defensiv',
  AnfuehrerBot() => 'anfuehrer',
  _ => throw ArgumentError('Unbekannter Bot-Typ: ${bot.runtimeType}'),
};

Bot botVonName(String name) => switch (name) {
  'greedy' => const GreedyBot(),
  'zufall' => const ZufallsBot(),
  'defensiv' => const DefensivBot(),
  'anfuehrer' => const AnfuehrerBot(),
  _ => throw ArgumentError('Unbekannter Bot-Typ: $name'),
};

Map<String, dynamic> commandZuJson(Command command) => switch (command) {
  KarteBauen(feldIndex: final f, karteId: final k, effektWahl: final w) => {
    'typ': 'karteBauen',
    'feldIndex': f,
    'karteId': k,
    'effektWahl': effektWahlZuJson(w),
  },
  EvilSpielen(
    zielSpielerId: final z,
    zielFeldIndex: final f,
    karteId: final k,
  ) =>
    {
      'typ': 'evilSpielen',
      'zielSpielerId': z,
      'zielFeldIndex': f,
      'karteId': k,
    },
  SofortReagieren(karteId: final k, effektWahl: final w) => {
    'typ': 'sofortReagieren',
    'karteId': k,
    'effektWahl': effektWahlZuJson(w),
  },
  Passen() => {'typ': 'passen'},
};

Command commandVonJson(Map<String, dynamic> json) => switch (json['typ']) {
  'karteBauen' => KarteBauen(
    feldIndex: json['feldIndex'] as int,
    karteId: json['karteId'] as String,
    effektWahl: effektWahlVonJson(json['effektWahl']),
  ),
  'evilSpielen' => EvilSpielen(
    zielSpielerId: json['zielSpielerId'] as String,
    zielFeldIndex: json['zielFeldIndex'] as int,
    karteId: json['karteId'] as String,
  ),
  'sofortReagieren' => SofortReagieren(
    karteId: json['karteId'] as String,
    effektWahl: effektWahlVonJson(json['effektWahl']),
  ),
  'passen' => const Passen(),
  _ => throw FormatException('Unbekannter Command-Typ: ${json['typ']}'),
};

Map<String, dynamic>? effektWahlZuJson(EffektWahl? wahl) => switch (wahl) {
  null => null,
  SucheWahl(gefundeneKarteId: final id) => {
    'typ': 'suche',
    'gefundeneKarteId': id,
  },
  ErneuerungWahl(handKartenIds: final ids) => {
    'typ': 'erneuerung',
    'handKartenIds': ids,
  },
  UmordnungWahl(
    feldIndex: final f,
    vonTiefe: final von,
    nachTiefe: final nach,
  ) =>
    {'typ': 'umordnung', 'feldIndex': f, 'vonTiefe': von, 'nachTiefe': nach},
};

EffektWahl? effektWahlVonJson(dynamic json) {
  if (json == null) return null;
  // Map<String, dynamic>.from(...): siehe Kommentar in parseGespeichertePartie.
  final map = Map<String, dynamic>.from(json as Map);
  return switch (map['typ']) {
    'suche' => SucheWahl(map['gefundeneKarteId'] as String),
    'erneuerung' => ErneuerungWahl((map['handKartenIds'] as List).cast<String>()),
    'umordnung' => UmordnungWahl(
      feldIndex: map['feldIndex'] as int,
      vonTiefe: map['vonTiefe'] as int,
      nachTiefe: map['nachTiefe'] as int,
    ),
    _ => throw FormatException('Unbekannter EffektWahl-Typ: ${map['typ']}'),
  };
}
