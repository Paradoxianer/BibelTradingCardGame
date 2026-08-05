/// Kartenkategorien (KARTEN_SPEZIFIKATION §3). `tun` und `lehre` sind im
/// Bestand aktuell unbefüllt (0 Karten) — bewusst noch enthalten, damit
/// Import/Deckbau schon heute damit umgehen können, sobald Karten dazukommen.
enum Kategorie { gebet, glauben, tun, lehre, gottesdienst, evil, start }

Kategorie kategorieVonString(String s) => switch (s) {
  'gebet' => Kategorie.gebet,
  'glauben' => Kategorie.glauben,
  'tun' => Kategorie.tun,
  'lehre' => Kategorie.lehre,
  'gottesdienst' => Kategorie.gottesdienst,
  'evil' => Kategorie.evil,
  'start' => Kategorie.start,
  _ => throw FormatException('Unbekannte Kategorie: "$s"'),
};
