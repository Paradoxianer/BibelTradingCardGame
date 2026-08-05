/// Inhalt eines einzelnen Slots (KARTEN_SPEZIFIKATION §2).
sealed class SlotSymbol {
  const SlotSymbol();

  factory SlotSymbol.parse(String code) {
    switch (code.toLowerCase()) {
      case 'x':
        return const Loch();
      case '-1':
        return const Schwarz();
      case '0':
      case '1':
      case '2':
        return Farbig(int.parse(code));
      default:
        throw FormatException('Unbekannter Slot-Code: "$code"');
    }
  }
}

/// Stanzung — zeigt den Slot der darunterliegenden Karte.
final class Loch extends SlotSymbol {
  const Loch();

  @override
  bool operator ==(Object other) => other is Loch;

  @override
  int get hashCode => (Loch).hashCode;
}

/// Bunter Wert (Stärke) — zählt nur, wenn durch ein Loch sichtbar.
final class Farbig extends SlotSymbol {
  final int wert;

  const Farbig(this.wert) : assert(wert >= 0 && wert <= 2);

  @override
  bool operator ==(Object other) => other is Farbig && other.wert == wert;

  @override
  int get hashCode => Object.hash(Farbig, wert);
}

/// Schwarzer Wert (Schwäche, immer -1) — zählt immer, sobald sichtbar.
final class Schwarz extends SlotSymbol {
  const Schwarz();

  int get wert => -1;

  @override
  bool operator ==(Object other) => other is Schwarz;

  @override
  int get hashCode => (Schwarz).hashCode;
}
