import 'effekt.dart';
import 'kategorie.dart';
import 'slot.dart';
import 'slot_symbol.dart';

class Vers {
  final String stelle;
  final String text;

  const Vers({required this.stelle, required this.text});
}

/// Ein Kartentyp (nicht ein physisches Exemplar). Decks/Hände können
/// mehrfach dieselbe [Karte]-Instanz enthalten (bis zu [anzahlImDeckMax]).
class Karte {
  final String id; // Kartentyp-ID inkl. Set, z.B. BASE-RG0101
  final String cardId; // Bestands-ID, z.B. RG0101
  final String name;
  final Vers vers;
  final List<SlotSymbol> slots; // Länge 6, Reihenfolge kSlotOrder
  final Kategorie kategorie;
  final String seltenheit;
  final bool sofort;
  final Effekt? effekt;
  final int anzahlImDeckMax;
  final String pictureLink;

  Karte({
    required this.id,
    required this.cardId,
    required this.name,
    required this.vers,
    required this.slots,
    required this.kategorie,
    required this.seltenheit,
    required this.sofort,
    required this.effekt,
    required this.anzahlImDeckMax,
    required this.pictureLink,
  }) : assert(slots.length == 6);

  SlotSymbol slotAn(SlotPosition pos) => slots[pos.index];

  bool get hatLoch => slots.any((s) => s is Loch);

  @override
  bool operator ==(Object other) => other is Karte && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Karte($id, $name)';
}
