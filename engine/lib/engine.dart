import 'dart:math';

import 'model/model.dart';
import 'rules/commands.dart';
import 'rules/effekt_resolver.dart';
import 'rules/events.dart';
import 'rules/regel_verstoss.dart';
import 'rules/schutz.dart';
import 'rules/wertung.dart';

export 'model/model.dart';
export 'rules/commands.dart';
export 'rules/effekt_wahl.dart';
export 'rules/events.dart';
export 'rules/regel_verstoss.dart';
export 'rules/spiel_aufbau.dart';
export 'rules/wertung.dart';

/// Wendet [Command]s auf einen [GameState] an (REGELWERK §5) und liefert den
/// neuen Zustand plus die dabei ausgelösten [GameEvent]s. Wirft
/// [RegelVerstoss] bei illegalen Zügen (ARCHITEKTUR §2).
class GameEngine {
  (GameState, List<GameEvent>) apply(GameState state, Command command) {
    if (!state.spielLaeuft) {
      throw const RegelVerstoss('Die Partie ist bereits beendet.');
    }
    return switch (command) {
      KarteBauen k => _karteBauen(state, k),
      EvilSpielen e => _evilSpielen(state, e),
      SofortReagieren r => _sofortReagieren(state, r),
      Passen _ => _passen(state),
    };
  }

  (GameState, List<GameEvent>) _passen(GameState state) {
    switch (state.phase) {
      case ZugPhase.bauen:
        return (state.copyWith(phase: ZugPhase.evilSpielen), const []);
      case ZugPhase.evilSpielen:
        return _nachEvilPhaseAbschliessen(state, const []);
      case ZugPhase.reaktion:
        return _evilLandet(state, const []);
    }
  }

  (GameState, List<GameEvent>) _karteBauen(GameState state, KarteBauen cmd) {
    if (state.phase != ZugPhase.bauen) {
      throw const RegelVerstoss('Bauen ist in dieser Phase nicht erlaubt.');
    }
    var spieler = state.aktiverSpieler;
    final (karte, neueHand) = _ausHandNehmen(spieler.hand, cmd.karteId);
    if (karte.kategorie == Kategorie.evil) {
      throw const RegelVerstoss(
        'Evil-Karten werden über EvilSpielen ausgespielt.',
      );
    }
    spieler = spieler.copyWith(hand: neueHand);

    final events = <GameEvent>[];
    if (karte.effekt is Gebietserweiterung) {
      if (spieler.spielfelder.length >= 4) {
        throw const RegelVerstoss(
          'Gebietserweiterung ist auf 1x pro Spieler begrenzt.',
        );
      }
      spieler = spieler.copyWith(
        spielfelder: [
          ...spieler.spielfelder,
          Spielfeld([Kartenlage(karte)]),
        ],
      );
      events.add(GebietErweitert(spielerId: spieler.id, karteId: karte.id));
    } else {
      if (cmd.feldIndex < 0 || cmd.feldIndex >= spieler.spielfelder.length) {
        throw const RegelVerstoss('Ungültiger Feldindex.');
      }
      final neueFelder = List<Spielfeld>.of(spieler.spielfelder);
      neueFelder[cmd.feldIndex] = neueFelder[cmd.feldIndex].legeObenauf(karte);
      spieler = spieler.copyWith(spielfelder: neueFelder);
      events.add(
        KarteGelegt(
          spielerId: spieler.id,
          feldIndex: cmd.feldIndex,
          karteId: karte.id,
        ),
      );
    }

    var neuerState = state.mitSpieler(spieler);
    final ergebnis = resolveSofortEffekt(
      spieler: spieler,
      karte: karte,
      rng: neuerState.rng,
      wahl: cmd.effektWahl,
    );
    neuerState = neuerState
        .mitSpieler(ergebnis.spieler)
        .copyWith(rng: ergebnis.rng, phase: ZugPhase.evilSpielen);
    events.addAll(ergebnis.events);

    return (neuerState, events);
  }

  (GameState, List<GameEvent>) _evilSpielen(GameState state, EvilSpielen cmd) {
    if (state.phase != ZugPhase.evilSpielen) {
      throw const RegelVerstoss(
        'Evil spielen ist in dieser Phase nicht erlaubt.',
      );
    }
    if (state.rundeNummer == 1) {
      throw const RegelVerstoss(
        'Evil ist in der ersten Runde der Partie verboten.',
      );
    }
    final angreifer = state.aktiverSpieler;
    if (cmd.zielSpielerId == angreifer.id) {
      throw const RegelVerstoss('Evil kann nicht auf sich selbst gespielt werden.');
    }
    if (state.evilEmpfangenDieseRunde.contains(cmd.zielSpielerId)) {
      throw const RegelVerstoss(
        'Zielspieler hat diese Runde bereits Evil erhalten.',
      );
    }
    final zielIndex = state.spielerIndexVon(cmd.zielSpielerId);
    if (zielIndex == -1) throw const RegelVerstoss('Unbekannter Zielspieler.');
    var ziel = state.spieler[zielIndex];
    if (cmd.zielFeldIndex < 0 || cmd.zielFeldIndex >= ziel.spielfelder.length) {
      throw const RegelVerstoss('Ungültiger Feldindex.');
    }

    final (karte, neueHandAngreifer) = _ausHandNehmen(
      angreifer.hand,
      cmd.karteId,
    );
    if (karte.kategorie != Kategorie.evil) {
      throw const RegelVerstoss(
        'Nur Evil-Karten können über EvilSpielen gespielt werden.',
      );
    }
    var neuerAngreifer = angreifer.copyWith(hand: neueHandAngreifer);
    var neuerState = state.mitSpieler(neuerAngreifer);

    final schutz = findeAktivenSchutz(ziel, cmd.zielFeldIndex);
    if (schutz != null) {
      ziel = verbraucheSchutzLadung(ziel, schutz.feldIndex);
      neuerAngreifer = neuerAngreifer.copyWith(
        hand: [...neuerAngreifer.hand, karte],
      );
      neuerState = neuerState.mitSpieler(neuerAngreifer).mitSpieler(ziel);
      final events = [
        EvilAbgewehrt(
          angreiferId: angreifer.id,
          verteidigerId: ziel.id,
          feldIndex: schutz.feldIndex,
          karteId: karte.id,
        ),
      ];
      return _nachEvilPhaseAbschliessen(neuerState, events);
    }

    final ankunftsEvent = EvilGespielt(
      angreiferId: angreifer.id,
      zielSpielerId: ziel.id,
      zielFeldIndex: cmd.zielFeldIndex,
      karteId: karte.id,
    );

    final hatSofortKarte = ziel.hand.any((k) => k.sofort);
    neuerState = neuerState.copyWith(
      pendingEvilOpferId: ziel.id,
      pendingEvilFeldIndex: cmd.zielFeldIndex,
      pendingEvilKarte: karte,
    );

    if (hatSofortKarte) {
      neuerState = neuerState.copyWith(phase: ZugPhase.reaktion);
      return (neuerState, [ankunftsEvent]);
    }

    return _evilLandet(neuerState, [ankunftsEvent]);
  }

  (GameState, List<GameEvent>) _sofortReagieren(
    GameState state,
    SofortReagieren cmd,
  ) {
    if (state.phase != ZugPhase.reaktion) {
      throw const RegelVerstoss('Keine Reaktion in dieser Phase möglich.');
    }
    final opferId = state.pendingEvilOpferId!;
    final feldIndex = state.pendingEvilFeldIndex!;
    var opfer = state.spielerMitId(opferId);

    final (reaktionsKarte, neueHandOpfer) = _ausHandNehmen(
      opfer.hand,
      cmd.karteId,
    );
    if (!reaktionsKarte.sofort) {
      throw const RegelVerstoss(
        'Nur Karten mit Sofort-Kennzeichnung sind als Reaktion erlaubt.',
      );
    }
    opfer = opfer.copyWith(hand: neueHandOpfer);
    final neueFelder = List<Spielfeld>.of(opfer.spielfelder);
    neueFelder[feldIndex] = neueFelder[feldIndex].legeObenauf(reaktionsKarte);
    opfer = opfer.copyWith(spielfelder: neueFelder);

    var neuerState = state.mitSpieler(opfer);
    final ergebnis = resolveSofortEffekt(
      spieler: opfer,
      karte: reaktionsKarte,
      rng: neuerState.rng,
      wahl: cmd.effektWahl,
    );
    opfer = ergebnis.spieler;
    neuerState = neuerState.mitSpieler(opfer).copyWith(rng: ergebnis.rng);

    final events = <GameEvent>[
      SofortGespielt(spielerId: opfer.id, karteId: reaktionsKarte.id),
      ...ergebnis.events,
    ];

    if (reaktionsKarte.effekt is Schutz) {
      opfer = verbraucheSchutzLadung(opfer, feldIndex);
      final angreifer = neuerState.aktiverSpieler;
      final evilKarte = neuerState.pendingEvilKarte!;
      final angreiferMitKarteZurueck = angreifer.copyWith(
        hand: [...angreifer.hand, evilKarte],
      );
      neuerState = neuerState
          .mitSpieler(opfer)
          .mitSpieler(angreiferMitKarteZurueck)
          .copyWith(
            pendingEvilOpferId: null,
            pendingEvilFeldIndex: null,
            pendingEvilKarte: null,
          );
      events.add(
        EvilAbgewehrt(
          angreiferId: angreifer.id,
          verteidigerId: opfer.id,
          feldIndex: feldIndex,
          karteId: evilKarte.id,
        ),
      );
      return _nachEvilPhaseAbschliessen(neuerState, events);
    }

    return _evilLandet(neuerState, events);
  }

  /// Die schwebende Evil-Karte landet obenauf (kein Schutz/keine Reaktion
  /// hat sie abgewehrt).
  (GameState, List<GameEvent>) _evilLandet(
    GameState state,
    List<GameEvent> vorherigeEvents,
  ) {
    final opferId = state.pendingEvilOpferId!;
    final feldIndex = state.pendingEvilFeldIndex!;
    final karte = state.pendingEvilKarte!;
    var opfer = state.spielerMitId(opferId);
    final neueFelder = List<Spielfeld>.of(opfer.spielfelder);
    neueFelder[feldIndex] = neueFelder[feldIndex].legeObenauf(karte);
    opfer = opfer.copyWith(spielfelder: neueFelder);

    final neuerState = state.mitSpieler(opfer).copyWith(
      evilEmpfangenDieseRunde: {...state.evilEmpfangenDieseRunde, opfer.id},
      pendingEvilOpferId: null,
      pendingEvilFeldIndex: null,
      pendingEvilKarte: null,
    );
    return _nachEvilPhaseAbschliessen(neuerState, vorherigeEvents);
  }

  /// Wertung (§6), Siegprüfung, Nachziehen (D2) und Zugwechsel — alles ohne
  /// weitere Spielerentscheidung, daher kein eigenes Command.
  (GameState, List<GameEvent>) _nachEvilPhaseAbschliessen(
    GameState state,
    List<GameEvent> vorherigeEvents,
  ) {
    final events = <GameEvent>[...vorherigeEvents];
    var aktiver = state.aktiverSpieler;

    final wertung = berechneWertung(state, aktiver.id);
    events.add(WertungBerechnet(wertung));
    final altHeiligkeit = aktiver.heiligkeit;
    final neuHeiligkeit = max(0, altHeiligkeit + wertung.punkte);
    aktiver = aktiver.copyWith(heiligkeit: neuHeiligkeit);
    events.add(
      HeiligkeitGeaendert(
        spielerId: aktiver.id,
        alt: altHeiligkeit,
        neu: neuHeiligkeit,
      ),
    );
    var neuerState = state.mitSpieler(aktiver);

    if (neuHeiligkeit >= kSiegHeiligkeit) {
      neuerState = neuerState.copyWith(gewinnerId: aktiver.id);
      events.add(SpielerGewonnen(aktiver.id));
      return (neuerState, events);
    }

    final anzahlZuZiehen = min(
      max(0, 5 - aktiver.hand.length),
      aktiver.deck.length,
    );
    if (anzahlZuZiehen > 0) {
      final gezogen = aktiver.deck.take(anzahlZuZiehen).toList();
      final restDeck = aktiver.deck.skip(anzahlZuZiehen).toList();
      aktiver = aktiver.copyWith(
        hand: [...aktiver.hand, ...gezogen],
        deck: restDeck,
      );
      neuerState = neuerState.mitSpieler(aktiver);
      events.add(
        HandAufgefuellt(spielerId: aktiver.id, anzahl: anzahlZuZiehen),
      );
    }

    final niemandKannHandeln = neuerState.spieler.every(
      (s) => s.hand.isEmpty && s.deck.isEmpty,
    );
    if (niemandKannHandeln) {
      final maxHeiligkeit = neuerState.spieler
          .map((s) => s.heiligkeit)
          .reduce(max);
      final gewinner = neuerState.spieler.firstWhere(
        (s) => s.heiligkeit == maxHeiligkeit,
      );
      neuerState = neuerState.copyWith(gewinnerId: gewinner.id);
      events.add(PartieEndeDeckLeer(gewinner.id));
      return (neuerState, events);
    }

    final naechsterIndex = (neuerState.aktiverIndex + 1) % neuerState.spieler.length;
    final neueRunde = naechsterIndex == 0
        ? neuerState.rundeNummer + 1
        : neuerState.rundeNummer;
    final neuesEvilSet = naechsterIndex == 0
        ? const <String>{}
        : neuerState.evilEmpfangenDieseRunde;
    final naechsterSpielerId = neuerState.spieler[naechsterIndex].id;
    events.add(
      ZugBeendet(spielerId: aktiver.id, naechsterSpielerId: naechsterSpielerId),
    );

    neuerState = neuerState.copyWith(
      aktiverIndex: naechsterIndex,
      phase: ZugPhase.bauen,
      rundeNummer: neueRunde,
      zugNummer: neuerState.zugNummer + 1,
      evilEmpfangenDieseRunde: neuesEvilSet,
    );
    return (neuerState, events);
  }
}

(Karte, List<Karte>) _ausHandNehmen(List<Karte> hand, String karteId) {
  final idx = hand.indexWhere((k) => k.id == karteId);
  if (idx == -1) {
    throw RegelVerstoss('Karte nicht in der Hand: $karteId');
  }
  final neueHand = List<Karte>.of(hand)..removeAt(idx);
  return (hand[idx], neueHand);
}
