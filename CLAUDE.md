# CLAUDE.md — BibelTradingCardGame

Sammelkartenspiel mit biblischen Inhalten. Digitale Umsetzung in Flutter mit
reiner Dart-Spiel-Engine; später Online-Multiplayer und physische Karten.

## Maßgebliche Dokumente (vor Änderungen lesen)

- `docs/REGELWERK.md` — **Source of Truth für die Spiellogik.** Offene Punkte
  sind als D1–D8 markiert. Bei Regel-Mehrdeutigkeit: **fragen, nicht raten** —
  und niemals stillschweigend eine D-Entscheidung treffen.
- `docs/KARTEN_SPEZIFIKATION.md` — Kartengeometrie (6 Slots: 2×Vater, 2×Sohn,
  2×Hl. Geist), Slot-Codes (`2|1|0|-1|X`), ID-Schema, JSON-Format.
- `docs/ARCHITEKTUR.md` — Repo-Layout, Engine-Design, Teststrategie.
- `docs/ROADMAP.md` — aktuelle Phase und Definition of Done.

## Arbeitsprinzipien (wichtig)

1. **Minimale, gezielte Änderungen.** Keine ungefragten Refactorings, keine
   Umbenennungen „bei der Gelegenheit", keine wholesale Rewrites. Wenn ein
   größerer Umbau nötig scheint: erst vorschlagen und begründen.
2. **Engine bleibt rein:** `engine/` importiert niemals Flutter, dart:ui oder
   IO. Aller Zufall läuft über den seedbaren RNG im GameState.
3. **Regeländerungen nur über das Regelwerk:** Erst `docs/REGELWERK.md`
   anpassen (bzw. anpassen lassen), dann Code + Tests nachziehen.
4. **Tests zuerst bei Regel-Logik:** Jede Regel aus dem Regelwerk hat einen
   Test in `engine/test/`. Wertungsbeispiele als Fixtures.
5. **Kartendaten sind Daten:** Karten werden in `data/sets/*.json` gepflegt,
   nie im Code hartkodiert (Ausnahme: Test-Fixtures).
6. **Kein Overengineering:**
7. **Multi langauge Support** Die app soll direkt von grund auf auf verschiedensprachigkeit ausgelegt sein

## Struktur & Befehle

```
engine/   reines Dart-Package (btcg_engine)   → cd engine && dart test
app/      Flutter-App (Web/Android, Hotseat)  → cd app && flutter run -d chrome
tools/    sheet_import, simulator             → dart run <tool>
data/     Kartensets (JSON)
legacy/   archivierter Qt-Prototyp — NIEMALS ändern, nur als Referenz lesen
```

- Vor Commits: `dart analyze` + Tests des betroffenen Packages.
- Flutter-Web-Deployment: GitHub Pages (Muster wie im Projekt flying_words).

## Domänen-Schnellreferenz

- Sieg: 100 **Heiligkeit**, Start 30, Untergrenze 0.
- Deck: 35 Karten, davon 7 *unterschiedliche* Evil-Karten.
- 3 Spielfelder = 3 Stapel pro Spieler, neue Karte immer obenauf.
- Wertung pro Slot-Spalte von oben: Löcher (`X`) durchschauen bis zum ersten
  Symbol. Schwarz (`-1`) zählt immer, wenn sichtbar; bunt (`0/1/2`) zählt nur
  durch mindestens ein Loch gesehen. Bunte Werte der obersten Karte zählen NICHT.
- Evil: max. 1/Zug, nur auf Spieler ohne Evil in dieser Runde, verboten in
  Runde 1; Ziel darf mit `sofort`-Karten reagieren.
