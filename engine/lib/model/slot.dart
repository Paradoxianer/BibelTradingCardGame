/// Die 6 Symbolpositionen der Kopfzeile einer Karte (KARTEN_SPEZIFIKATION §1).
/// Reihenfolge ist kanonisch und entspricht der Spaltenreihenfolge im
/// Wertungsalgorithmus (REGELWERK §6).
enum SlotPosition { v1, v2, s1, s2, hg1, hg2 }

const List<SlotPosition> kSlotOrder = SlotPosition.values;

/// Die drei Personen, denen je zwei Slots zugeordnet sind (KARTEN_SPEZIFIKATION §1).
enum Person { vater, sohn, heiligerGeist }

Person personVon(SlotPosition pos) => switch (pos) {
  SlotPosition.v1 || SlotPosition.v2 => Person.vater,
  SlotPosition.s1 || SlotPosition.s2 => Person.sohn,
  SlotPosition.hg1 || SlotPosition.hg2 => Person.heiligerGeist,
};
