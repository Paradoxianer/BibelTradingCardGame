import 'wertung.dart';

sealed class GameEvent {
  const GameEvent();
}

class KarteGelegt extends GameEvent {
  final String spielerId;
  final int feldIndex;
  final String karteId;
  const KarteGelegt({
    required this.spielerId,
    required this.feldIndex,
    required this.karteId,
  });
}

class GebietErweitert extends GameEvent {
  final String spielerId;
  final String karteId;
  const GebietErweitert({required this.spielerId, required this.karteId});
}

class EvilGespielt extends GameEvent {
  final String angreiferId;
  final String zielSpielerId;
  final int zielFeldIndex;
  final String karteId;
  const EvilGespielt({
    required this.angreiferId,
    required this.zielSpielerId,
    required this.zielFeldIndex,
    required this.karteId,
  });
}

class EvilAbgewehrt extends GameEvent {
  final String angreiferId;
  final String verteidigerId;
  final int feldIndex;
  final String karteId;
  const EvilAbgewehrt({
    required this.angreiferId,
    required this.verteidigerId,
    required this.feldIndex,
    required this.karteId,
  });
}

class SofortGespielt extends GameEvent {
  final String spielerId;
  final String karteId;
  const SofortGespielt({required this.spielerId, required this.karteId});
}

class EffektAusgeloest extends GameEvent {
  final String spielerId;
  final String karteId;
  final String beschreibung;
  const EffektAusgeloest({
    required this.spielerId,
    required this.karteId,
    required this.beschreibung,
  });
}

class WertungBerechnet extends GameEvent {
  final Wertung wertung;
  const WertungBerechnet(this.wertung);
}

class HeiligkeitGeaendert extends GameEvent {
  final String spielerId;
  final int alt;
  final int neu;
  const HeiligkeitGeaendert({
    required this.spielerId,
    required this.alt,
    required this.neu,
  });
}

class HandAufgefuellt extends GameEvent {
  final String spielerId;
  final int anzahl;
  const HandAufgefuellt({required this.spielerId, required this.anzahl});
}

class ZugBeendet extends GameEvent {
  final String spielerId;
  final String naechsterSpielerId;
  const ZugBeendet({required this.spielerId, required this.naechsterSpielerId});
}

class SpielerGewonnen extends GameEvent {
  final String spielerId;
  const SpielerGewonnen(this.spielerId);
}

/// D2: Deck leer bei allen Spielern, niemand kann mehr handeln.
class PartieEndeDeckLeer extends GameEvent {
  final String gewinnerId;
  const PartieEndeDeckLeer(this.gewinnerId);
}
