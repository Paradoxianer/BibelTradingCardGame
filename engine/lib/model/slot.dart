/// Die 6 Symbolpositionen der Kopfzeile einer Karte (KARTEN_SPEZIFIKATION §1).
/// Reihenfolge ist kanonisch und entspricht der Spaltenreihenfolge im
/// Wertungsalgorithmus (REGELWERK §6).
enum SlotPosition { v1, v2, s1, s2, hg1, hg2 }

const List<SlotPosition> kSlotOrder = SlotPosition.values;
