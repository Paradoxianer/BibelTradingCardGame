import 'package:btcg_engine/model/model.dart';

/// Baut eine minimale Test-Karte aus Slot-Codes wie im Bestand (§2, z.B.
/// `["x","x","1","0","1","0"]`, Reihenfolge V1,V2,S1,S2,HG1,HG2).
Karte testKarte(
  String id,
  List<String> slotCodes, {
  Effekt? effekt,
  Kategorie kategorie = Kategorie.gebet,
  bool sofort = false,
  int anzahlImDeckMax = 3,
}) {
  return Karte(
    id: id,
    cardId: id,
    name: id,
    vers: const Vers(stelle: '', text: ''),
    slots: slotCodes.map(SlotSymbol.parse).toList(),
    kategorie: kategorie,
    seltenheit: 'haeufig',
    sofort: sofort,
    effekt: effekt,
    anzahlImDeckMax: anzahlImDeckMax,
    pictureLink: '',
  );
}

/// Baut ein Spielfeld aus Karten, oberste zuerst.
Spielfeld testFeld(List<Karte> kartenObenNachUnten) =>
    Spielfeld([for (final k in kartenObenNachUnten) Kartenlage(k)]);

Spieler testSpieler(
  String id, {
  int heiligkeit = kStartHeiligkeit,
  List<Spielfeld>? spielfelder,
  List<Karte> hand = const [],
  List<Karte> deck = const [],
}) => Spieler(
  id: id,
  name: id,
  heiligkeit: heiligkeit,
  hand: hand,
  deck: deck,
  spielfelder: spielfelder ?? const [Spielfeld(), Spielfeld(), Spielfeld()],
);

GameState testState(List<Spieler> spieler, {int aktiverIndex = 0, int seed = 42}) =>
    GameState(
      spieler: spieler,
      aktiverIndex: aktiverIndex,
      rng: SeedableRng.seeded(seed),
    );
