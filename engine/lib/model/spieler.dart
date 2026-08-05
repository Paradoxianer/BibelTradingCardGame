import 'karte.dart';
import 'spielfeld.dart';

/// Start-Heiligkeit (REGELWERK §1).
const int kStartHeiligkeit = 30;

/// Siegbedingung (REGELWERK §1).
const int kSiegHeiligkeit = 100;

/// Standardanzahl Spielfelder; kann durch `gebietserweiterung` auf 4 wachsen.
const int kStandardSpielfelder = 3;

class Spieler {
  final String id;
  final String name;
  final int heiligkeit;
  final List<Karte> hand;
  final List<Karte> deck; // verdeckt; index 0 = oberste/nächste Karte
  final List<Spielfeld> spielfelder;

  const Spieler({
    required this.id,
    required this.name,
    this.heiligkeit = kStartHeiligkeit,
    this.hand = const [],
    this.deck = const [],
    this.spielfelder = const [Spielfeld(), Spielfeld(), Spielfeld()],
  });

  bool get hatGewonnen => heiligkeit >= kSiegHeiligkeit;

  bool get hatGebietserweiterung => spielfelder.length > kStandardSpielfelder;

  Spieler copyWith({
    int? heiligkeit,
    List<Karte>? hand,
    List<Karte>? deck,
    List<Spielfeld>? spielfelder,
  }) => Spieler(
    id: id,
    name: name,
    heiligkeit: heiligkeit ?? this.heiligkeit,
    hand: hand ?? this.hand,
    deck: deck ?? this.deck,
    spielfelder: spielfelder ?? this.spielfelder,
  );
}
