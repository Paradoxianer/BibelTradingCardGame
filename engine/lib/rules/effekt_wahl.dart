/// Zusatzangaben, die manche `sofort`-Effekte beim Auflösen brauchen
/// (EFFEKTE.md §2). `zuwendung` braucht keine Wahl (Art/Menge stehen fix
/// auf der Karte).
sealed class EffektWahl {}

/// Für `suche` (§2.6): die gefundene Karte (Kartentyp-ID) aus dem Deck.
class SucheWahl extends EffektWahl {
  final String gefundeneKarteId;
  SucheWahl(this.gefundeneKarteId);
}

/// Für `erneuerung` (§2.7): welche Handkarten zurück ins Deck gemischt werden.
class ErneuerungWahl extends EffektWahl {
  final List<String> handKartenIds;
  ErneuerungWahl(this.handKartenIds);
}

/// Für `umordnung` (§2.8): Feld und Positionen (0-basierte Tiefe, 0 = oben).
class UmordnungWahl extends EffektWahl {
  final int feldIndex;
  final int vonTiefe;
  final int nachTiefe;

  UmordnungWahl({
    required this.feldIndex,
    required this.vonTiefe,
    required this.nachTiefe,
  });
}
