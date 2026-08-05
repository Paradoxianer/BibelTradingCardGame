import '../model/model.dart';

/// Findet für [feld]/[pos] die sichtbare Karte: schaut von oben durch Löcher,
/// bis ein Nicht-Loch-Symbol auftaucht oder der Stapel endet (dann null).
/// Gemeinsame Grundlage für Wertung (wertung.dart) und UI (die Loch-
/// Darstellung zeigt exakt das, was auch gewertet wird).
({SlotSymbol symbol, int tiefe})? sichtbaresSymbolAn(
  Spielfeld feld,
  SlotPosition pos,
) {
  for (var tiefe = 0; tiefe < feld.stapel.length; tiefe++) {
    final symbol = feld.stapel[tiefe].karte.slotAn(pos);
    if (symbol is! Loch) return (symbol: symbol, tiefe: tiefe);
  }
  return null;
}
