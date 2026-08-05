import 'kategorie.dart';

/// Effekt-Vokabular gemäß docs/EFFEKTE.md §2/§3. `dauer` ist pro Typ fix
/// (siehe EFFEKTE.md §3 Tabelle) und wird deshalb nicht separat gespeichert,
/// sondern aus dem Typ abgeleitet.
enum EffektDauer { solangeOben, sofort, permanent }

sealed class Effekt {
  const Effekt();
  EffektDauer get dauer;
}

/// 2.1 — sichtbare schwarze Werte in [slots] zählen positiv statt negativ.
final class Umkehrung extends Effekt {
  final List<int> slots; // 1-basierte Slot-Positionen, Länge 1-2

  Umkehrung(this.slots)
    : assert(slots.isNotEmpty && slots.length <= 2),
      assert(slots.every((s) => s >= 1 && s <= 6));

  @override
  EffektDauer get dauer => EffektDauer.solangeOben;
}

enum SchutzReichweite { feld, spieler }

/// 2.2 — wehrt die nächste Evil-Karte gegen [reichweite] ab.
final class Schutz extends Effekt {
  final SchutzReichweite reichweite;
  final int ladungen;

  const Schutz({required this.reichweite, this.ladungen = 1})
    : assert(ladungen >= 1);

  @override
  EffektDauer get dauer => EffektDauer.solangeOben;
}

/// 2.3 — fügt dem Spieler ein viertes Spielfeld hinzu (max. 1×/Spieler/Partie).
final class Gebietserweiterung extends Effekt {
  const Gebietserweiterung();

  @override
  EffektDauer get dauer => EffektDauer.permanent;
}

enum ZuwendungArt { karten, heiligkeit }

/// 2.4 — einmaliger Vorteil beim Ausspielen.
final class Zuwendung extends Effekt {
  final ZuwendungArt art;
  final int menge;

  const Zuwendung({required this.art, required this.menge})
    : assert(menge > 0);

  @override
  EffektDauer get dauer => EffektDauer.sofort;
}

/// 2.5 — fester Wertungs-Zuschlag für alle Spieler, solange aktiv.
final class GlobaleAura extends Effekt {
  final int wert;

  const GlobaleAura(this.wert) : assert(wert != 0);

  @override
  EffektDauer get dauer => EffektDauer.solangeOben;
}

/// 2.6 — durchsuche das eigene Deck nach [filter] (null = beliebig, nie evil).
final class Suche extends Effekt {
  final Kategorie? filter;

  const Suche(this.filter) : assert(filter != Kategorie.evil);

  @override
  EffektDauer get dauer => EffektDauer.sofort;
}

/// 2.7 — bis zu [menge] Handkarten zurück ins Deck mischen, ebenso viele ziehen.
final class Erneuerung extends Effekt {
  final int menge;

  const Erneuerung(this.menge) : assert(menge >= 1);

  @override
  EffektDauer get dauer => EffektDauer.sofort;
}

enum UmordnungZiel { eigen, gegner }

/// 2.8 — bewegt genau eine Karte innerhalb eines Stapels an eine andere
/// Position. `gegner` ist Evil-Karten vorbehalten (kommt erst mit EvilDeck).
final class Umordnung extends Effekt {
  final UmordnungZiel ziel;

  const Umordnung(this.ziel);

  @override
  EffektDauer get dauer => EffektDauer.sofort;
}
