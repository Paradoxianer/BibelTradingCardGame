import 'package:btcg_app/bloc/spiel_persistenz.dart';
import 'package:btcg_engine/bots/bots.dart';
import 'package:btcg_engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simuliert, wie verschachtelte Maps aus echtem Storage (Hive/IndexedDB)
/// zur Laufzeit typischerweise aussehen: `Map<dynamic, dynamic>` statt
/// `Map<String, dynamic>` wie bei handgebautem JSON. Ein direkter
/// `as Map<String, dynamic>`-Cast auf solche Werte schlägt fehl — genau der
/// Bug, den dieser Helper in einem Regressionstest abdeckt.
dynamic _alsDynamischeStruktur(dynamic value) {
  if (value is Map) {
    return Map<dynamic, dynamic>.fromEntries(
      value.entries.map(
        (e) => MapEntry<dynamic, dynamic>(e.key, _alsDynamischeStruktur(e.value)),
      ),
    );
  }
  if (value is List) {
    return value.map(_alsDynamischeStruktur).toList();
  }
  return value;
}

Karte _karte(
  String id,
  List<String> slots, {
  Kategorie kategorie = Kategorie.gebet,
  int anzahlImDeckMax = 3,
}) => Karte(
  id: id,
  cardId: id,
  name: id,
  vers: const Vers(stelle: '', text: ''),
  slots: slots.map(SlotSymbol.parse).toList(),
  kategorie: kategorie,
  seltenheit: 'haeufig',
  sofort: false,
  effekt: null,
  anzahlImDeckMax: anzahlImDeckMax,
  pictureLink: '',
);

Kartenset _kartenset() {
  final ressourcen = [
    for (var i = 0; i < 20; i++) _karte('r$i', ['x', '1', 'x', '1', 'x', '1']),
  ];
  final evil = [
    for (var i = 0; i < 7; i++)
      _karte(
        'e$i',
        ['-1', '-1', '-1', '-1', '-1', '-1'],
        kategorie: Kategorie.evil,
        anzahlImDeckMax: 1,
      ),
  ];
  final start = _karte('estart', [
    '-1',
    '-1',
    '-1',
    '-1',
    '-1',
    '-1',
  ], kategorie: Kategorie.start);
  return Kartenset(
    set: 'TEST',
    version: '1.0.0',
    tabs: {'R_Test': [...ressourcen, ...evil, start]},
  );
}

void main() {
  group('Command <-> JSON', () {
    test('KarteBauen ohne effektWahl', () {
      const command = KarteBauen(feldIndex: 1, karteId: 'x');
      final json = commandZuJson(command);
      final zurueck = commandVonJson(json) as KarteBauen;
      expect(zurueck.feldIndex, 1);
      expect(zurueck.karteId, 'x');
      expect(zurueck.effektWahl, isNull);
    });

    test('EvilSpielen', () {
      const command = EvilSpielen(
        zielSpielerId: 'p2',
        zielFeldIndex: 2,
        karteId: 'e1',
      );
      final zurueck = commandVonJson(commandZuJson(command)) as EvilSpielen;
      expect(zurueck.zielSpielerId, 'p2');
      expect(zurueck.zielFeldIndex, 2);
      expect(zurueck.karteId, 'e1');
    });

    test('Passen', () {
      final zurueck = commandVonJson(commandZuJson(const Passen()));
      expect(zurueck, isA<Passen>());
    });

    test('SofortReagieren mit UmordnungWahl', () {
      final command = SofortReagieren(
        karteId: 'k1',
        effektWahl: UmordnungWahl(feldIndex: 0, vonTiefe: 2, nachTiefe: 0),
      );
      final zurueck = commandVonJson(commandZuJson(command)) as SofortReagieren;
      final wahl = zurueck.effektWahl as UmordnungWahl;
      expect(wahl.feldIndex, 0);
      expect(wahl.vonTiefe, 2);
      expect(wahl.nachTiefe, 0);
    });

    test('KarteBauen mit SucheWahl und ErneuerungWahl', () {
      final such = KarteBauen(
        feldIndex: 0,
        karteId: 'k',
        effektWahl: SucheWahl('gefunden'),
      );
      final zurueckSuche = commandVonJson(commandZuJson(such)) as KarteBauen;
      expect((zurueckSuche.effektWahl as SucheWahl).gefundeneKarteId, 'gefunden');

      final erneu = KarteBauen(
        feldIndex: 0,
        karteId: 'k',
        effektWahl: ErneuerungWahl(['a', 'b']),
      );
      final zurueckErneu = commandVonJson(commandZuJson(erneu)) as KarteBauen;
      expect((zurueckErneu.effektWahl as ErneuerungWahl).handKartenIds, ['a', 'b']);
    });
  });

  group('Bot <-> Name', () {
    test('alle vier Bot-Typen', () {
      expect(botTypName(const GreedyBot()), 'greedy');
      expect(botTypName(const ZufallsBot()), 'zufall');
      expect(botTypName(const DefensivBot()), 'defensiv');
      expect(botTypName(const AnfuehrerBot()), 'anfuehrer');
      expect(botVonName('greedy'), isA<GreedyBot>());
      expect(botVonName('zufall'), isA<ZufallsBot>());
      expect(botVonName('defensiv'), isA<DefensivBot>());
      expect(botVonName('anfuehrer'), isA<AnfuehrerBot>());
    });
  });

  group('GespeichertePartie', () {
    test('Roundtrip ohne bereits gespielte Commands', () {
      final kartenset = _kartenset();
      final aufbauListe = [
        baueZufaelligesDeck(
          id: 'p1',
          name: 'Spieler 1',
          alleKarten: kartenset.alleKarten,
          seed: 1,
        ),
        baueZufaelligesDeck(
          id: 'p2',
          name: 'Spieler 2',
          alleKarten: kartenset.alleKarten,
          seed: 2,
        ),
      ];

      final json = gespeichertePartieZuJson(
        kartenset: kartenset,
        aufbauListe: aufbauListe,
        seed: 42,
        config: const RegelConfig(startspielerZiehtNurVier: true),
        botSpieler: {'p2': const GreedyBot()},
        botSeed: 7,
        verlauf: const [Passen(), KarteBauen(feldIndex: 0, karteId: 'r0')],
      );

      final partie = parseGespeichertePartie(json, kartenset)!;
      expect(partie.seed, 42);
      expect(partie.config.startspielerZiehtNurVier, isTrue);
      expect(partie.botSpieler['p2'], isA<GreedyBot>());
      expect(partie.botSeed, 7);
      expect(partie.verlauf.length, 2);
      expect(partie.aufbauListe.map((a) => a.id), ['p1', 'p2']);
      expect(
        partie.aufbauListe[0].deck.map((k) => k.id),
        aufbauListe[0].deck.map((k) => k.id),
      );
    });

    test(
      'Roundtrip funktioniert auch mit Map<dynamic,dynamic>-Verschachtelung '
      'wie aus echtem Storage (Regressionstest)',
      () {
        // Bug, den dieser Test abdeckt: HydratedBloc.storage.read() liefert
        // verschachtelte Maps zur Laufzeit als Map<dynamic,dynamic>, nicht
        // Map<String,dynamic> — ein direkter `as`-Cast darauf schlägt (leise)
        // fehl. start_screen.dart konvertiert nur die oberste Ebene, genau
        // wie hier nachgebaut.
        final kartenset = _kartenset();
        final aufbauListe = [
          baueZufaelligesDeck(id: 'p1', name: 'p1', alleKarten: kartenset.alleKarten, seed: 1),
          baueZufaelligesDeck(id: 'p2', name: 'p2', alleKarten: kartenset.alleKarten, seed: 2),
        ];
        final json = gespeichertePartieZuJson(
          kartenset: kartenset,
          aufbauListe: aufbauListe,
          seed: 42,
          config: const RegelConfig(),
          botSpieler: {'p2': const GreedyBot()},
          botSeed: 7,
          verlauf: [
            const Passen(),
            KarteBauen(
              feldIndex: 0,
              karteId: 'r0',
              effektWahl: ErneuerungWahl(['r1']),
            ),
          ],
        );

        final dynamischesJson = _alsDynamischeStruktur(json) as Map<dynamic, dynamic>;
        // Nur die oberste Ebene auf String-Keys bringen — exakt das Muster
        // aus start_screen.dart, nicht die vollständige Rekursion, die
        // HydratedMixin intern für den regulären hydrate()-Pfad nutzt.
        final nurObersteEbeneKonvertiert = dynamischesJson.map(
          (k, v) => MapEntry(k as String, v),
        );

        final partie = parseGespeichertePartie(nurObersteEbeneKonvertiert, kartenset);
        expect(partie, isNotNull);
        expect(partie!.botSpieler['p2'], isA<GreedyBot>());
        expect(partie.verlauf.length, 2);
        expect(
          (partie.verlauf[1] as KarteBauen).effektWahl,
          isA<ErneuerungWahl>(),
        );
      },
    );

    test('liefert null bei abweichender Kartenset-Version', () {
      final kartenset = _kartenset();
      final aufbauListe = [
        baueZufaelligesDeck(id: 'p1', name: 'p1', alleKarten: kartenset.alleKarten, seed: 1),
        baueZufaelligesDeck(id: 'p2', name: 'p2', alleKarten: kartenset.alleKarten, seed: 2),
      ];
      final json = gespeichertePartieZuJson(
        kartenset: kartenset,
        aufbauListe: aufbauListe,
        seed: 1,
        config: const RegelConfig(),
        botSpieler: const {},
        botSeed: 0,
        verlauf: const [],
      );

      final andereVersion = Kartenset(
        set: kartenset.set,
        version: '9.9.9',
        tabs: kartenset.tabs,
      );
      expect(parseGespeichertePartie(json, andereVersion), isNull);
    });

    test('liefert null bei kaputtem JSON statt zu werfen', () {
      final kartenset = _kartenset();
      expect(parseGespeichertePartie(<String, dynamic>{}, kartenset), isNull);
    });
  });
}
