import '../model/model.dart';
import 'sichtbarkeit.dart';

/// Wertung einer einzelnen Slot-Spalte in einem Spielfeld.
class SlotWertung {
  final SlotPosition slot;
  final int tiefe; // Anzahl durchschauter Löcher; 0 = oberste Karte
  final int punkte;
  final Karte? quellKarte; // Karte, deren Symbol sichtbar war (null = Loch bis zum Ende)

  const SlotWertung({
    required this.slot,
    required this.tiefe,
    required this.punkte,
    this.quellKarte,
  });
}

/// Wertung eines Spielfelds über alle 6 Slot-Spalten.
class FeldWertung {
  final int feldIndex;
  final List<SlotWertung> slots;

  const FeldWertung({required this.feldIndex, required this.slots});

  int get punkte => slots.fold(0, (summe, s) => summe + s.punkte);
}

/// Wertung eines Spielers für einen Zug (REGELWERK §6), mit Aufschlüsselung
/// pro Feld/Slot (ARCHITEKTUR §2 — UI zeigt, woher Punkte kommen).
class Wertung {
  final String spielerId;
  final List<FeldWertung> felder;
  final int globalerZuschlag;

  const Wertung({
    required this.spielerId,
    required this.felder,
    required this.globalerZuschlag,
  });

  int get punkte =>
      felder.fold(0, (summe, f) => summe + f.punkte) + globalerZuschlag;
}

/// Punktebeitrag je Kategorie (ROADMAP Phase 1b — Dominanz-Erkennung,
/// Zielwert: keine Kategorie > ~35 % des Gesamtbeitrags).
Map<Kategorie, int> punkteJeKategorie(Wertung wertung) {
  final ergebnis = <Kategorie, int>{};
  for (final feld in wertung.felder) {
    for (final slot in feld.slots) {
      final karte = slot.quellKarte;
      if (karte == null || slot.punkte == 0) continue;
      ergebnis.update(
        karte.kategorie,
        (v) => v + slot.punkte,
        ifAbsent: () => slot.punkte,
      );
    }
  }
  return ergebnis;
}

/// Punktebeitrag je Person (Vater/Sohn/Hl. Geist), gleiche Zielsetzung.
Map<Person, int> punkteJePerson(Wertung wertung) {
  final ergebnis = <Person, int>{};
  for (final feld in wertung.felder) {
    for (final slot in feld.slots) {
      if (slot.punkte == 0) continue;
      final person = personVon(slot.slot);
      ergebnis.update(
        person,
        (v) => v + slot.punkte,
        ifAbsent: () => slot.punkte,
      );
    }
  }
  return ergebnis;
}

bool _umkehrungAktiv(Spielfeld feld, SlotPosition pos) {
  final oben = feld.oberste?.karte;
  final effekt = oben?.effekt;
  if (effekt is! Umkehrung) return false;
  return effekt.slots.contains(pos.index + 1);
}

int _globalerZuschlag(GameState state) {
  var summe = 0;
  for (final spieler in state.spieler) {
    for (final feld in spieler.spielfelder) {
      final effekt = feld.oberste?.karte.effekt;
      if (effekt is GlobaleAura) summe += effekt.wert;
    }
  }
  return summe;
}

/// Wertet ein einzelnes Spielfeld (REGELWERK §6, ohne globale Effekte).
///
/// Eigenständig aufrufbar, damit die UI auch ein *hypothetisches* Feld
/// bewerten kann — etwa für die Vorschau „was brächte diese Karte hier?":
/// `werteFeld(feld.legeObenauf(karte), i).punkte`.
FeldWertung werteFeld(Spielfeld feld, int feldIndex) {
  final slotWertungen = <SlotWertung>[];

  for (final pos in kSlotOrder) {
    final gefunden = sichtbaresSymbolAn(feld, pos);
    if (gefunden == null) {
      slotWertungen.add(SlotWertung(slot: pos, tiefe: 0, punkte: 0));
      continue;
    }
    final (symbol: symbol, tiefe: tiefe) = gefunden;
    int punkte;
    switch (symbol) {
      case Schwarz():
        punkte = _umkehrungAktiv(feld, pos) ? 1 : symbol.wert;
      case Farbig(wert: final wert):
        punkte = tiefe > 0 ? wert : 0;
      case Loch():
        punkte = 0; // unerreichbar, sichtbaresSymbolAn liefert nie ein Loch
    }
    slotWertungen.add(
      SlotWertung(
        slot: pos,
        tiefe: tiefe,
        punkte: punkte,
        quellKarte: feld.stapel[tiefe].karte,
      ),
    );
  }

  return FeldWertung(feldIndex: feldIndex, slots: slotWertungen);
}

/// Pure Funktion nach REGELWERK §6. Wertet alle Spielfelder von [spielerId].
Wertung berechneWertung(GameState state, String spielerId) {
  final spieler = state.spielerMitId(spielerId);
  return Wertung(
    spielerId: spielerId,
    felder: [
      for (var i = 0; i < spieler.spielfelder.length; i++)
        werteFeld(spieler.spielfelder[i], i),
    ],
    globalerZuschlag: _globalerZuschlag(state),
  );
}
