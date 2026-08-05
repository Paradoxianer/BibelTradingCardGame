import 'dart:math';

import '../model/model.dart';
import 'effekt_wahl.dart';
import 'events.dart';
import 'regel_verstoss.dart';

class EffektErgebnis {
  final Spieler spieler;
  final SeedableRng rng;
  final List<GameEvent> events;

  const EffektErgebnis({
    required this.spieler,
    required this.rng,
    required this.events,
  });
}

/// Löst den `sofort`-Effekt von [karte] aus (EFFEKTE.md §2), sofern
/// vorhanden. Effekte mit anderer `dauer` (solange_oben, permanent) werden
/// nicht hier behandelt — die wirken passiv über den Spielzustand
/// (Wertung: wertung.dart, schutz: schutz.dart, gebietserweiterung: engine.dart).
EffektErgebnis resolveSofortEffekt({
  required Spieler spieler,
  required Karte karte,
  required SeedableRng rng,
  EffektWahl? wahl,
}) {
  final effekt = karte.effekt;
  if (effekt == null || effekt.dauer != EffektDauer.sofort) {
    return EffektErgebnis(spieler: spieler, rng: rng, events: const []);
  }

  switch (effekt) {
    case Zuwendung(art: final art, menge: final menge):
      if (art == ZuwendungArt.heiligkeit) {
        final alt = spieler.heiligkeit;
        final neu = max(0, alt + menge);
        return EffektErgebnis(
          spieler: spieler.copyWith(heiligkeit: neu),
          rng: rng,
          events: [
            EffektAusgeloest(
              spielerId: spieler.id,
              karteId: karte.id,
              beschreibung: 'zuwendung: +$menge Heiligkeit',
            ),
          ],
        );
      }
      final anzahl = min(menge, spieler.deck.length);
      final gezogen = spieler.deck.take(anzahl).toList();
      final restDeck = spieler.deck.skip(anzahl).toList();
      return EffektErgebnis(
        spieler: spieler.copyWith(
          hand: [...spieler.hand, ...gezogen],
          deck: restDeck,
        ),
        rng: rng,
        events: [
          EffektAusgeloest(
            spielerId: spieler.id,
            karteId: karte.id,
            beschreibung: 'zuwendung: +$anzahl Karten',
          ),
        ],
      );

    case Suche(filter: final filter):
      final w = wahl as SucheWahl?;
      if (w == null) {
        throw const RegelVerstoss('suche benötigt eine Kartenauswahl');
      }
      final index = spieler.deck.indexWhere((k) => k.id == w.gefundeneKarteId);
      if (index == -1) {
        throw const RegelVerstoss('Gesuchte Karte nicht im Deck');
      }
      final gefunden = spieler.deck[index];
      if (filter != null && gefunden.kategorie != filter) {
        throw const RegelVerstoss('Gefundene Karte erfüllt den Filter nicht');
      }
      final restDeck = List<Karte>.of(spieler.deck)..removeAt(index);
      final (gemischt, neuerRng) = mische(restDeck, rng);
      return EffektErgebnis(
        spieler: spieler.copyWith(
          hand: [...spieler.hand, gefunden],
          deck: gemischt,
        ),
        rng: neuerRng,
        events: [
          EffektAusgeloest(
            spielerId: spieler.id,
            karteId: karte.id,
            beschreibung: 'suche: ${gefunden.id} gefunden',
          ),
        ],
      );

    case Erneuerung(menge: final menge):
      final ids = (wahl as ErneuerungWahl?)?.handKartenIds ?? const [];
      if (ids.length > menge) {
        throw const RegelVerstoss('Zu viele Karten für erneuerung gewählt');
      }
      final neueHand = List<Karte>.of(spieler.hand);
      final zurueck = <Karte>[];
      for (final id in ids) {
        final idx = neueHand.indexWhere((k) => k.id == id);
        if (idx == -1) {
          throw RegelVerstoss('Karte nicht in Hand: $id');
        }
        zurueck.add(neueHand.removeAt(idx));
      }
      final (gemischtesDeck, rngNachMischen) = mische([
        ...spieler.deck,
        ...zurueck,
      ], rng);
      final anzahlZiehen = min(ids.length, gemischtesDeck.length);
      final gezogen = gemischtesDeck.take(anzahlZiehen).toList();
      final restDeck = gemischtesDeck.skip(anzahlZiehen).toList();
      return EffektErgebnis(
        spieler: spieler.copyWith(
          hand: [...neueHand, ...gezogen],
          deck: restDeck,
        ),
        rng: rngNachMischen,
        events: [
          EffektAusgeloest(
            spielerId: spieler.id,
            karteId: karte.id,
            beschreibung: 'erneuerung: ${ids.length} Karte(n) getauscht',
          ),
        ],
      );

    case Umordnung(ziel: final ziel):
      if (ziel == UmordnungZiel.gegner) {
        throw const RegelVerstoss(
          'Gegner-Umordnung ist Evil-Karten vorbehalten',
        );
      }
      final w = wahl as UmordnungWahl?;
      if (w == null) {
        throw const RegelVerstoss('umordnung benötigt eine Positionswahl');
      }
      final feld = spieler.spielfelder[w.feldIndex];
      final stapel = List<Kartenlage>.of(feld.stapel);
      if (w.vonTiefe < 0 ||
          w.vonTiefe >= stapel.length ||
          w.nachTiefe < 0 ||
          w.nachTiefe >= stapel.length) {
        throw const RegelVerstoss('Ungültige Position für umordnung');
      }
      final bewegt = stapel.removeAt(w.vonTiefe);
      stapel.insert(w.nachTiefe, bewegt);
      final neueFelder = List<Spielfeld>.of(spieler.spielfelder);
      neueFelder[w.feldIndex] = Spielfeld(stapel);
      return EffektErgebnis(
        spieler: spieler.copyWith(spielfelder: neueFelder),
        rng: rng,
        events: [
          EffektAusgeloest(
            spielerId: spieler.id,
            karteId: karte.id,
            beschreibung:
                'umordnung: Feld ${w.feldIndex}, ${w.vonTiefe} -> ${w.nachTiefe}',
          ),
        ],
      );

    case Umkehrung():
    case Schutz():
    case GlobaleAura():
    case Gebietserweiterung():
      throw StateError('${effekt.runtimeType} hat dauer != sofort');
  }
}
