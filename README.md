# BibelTradingCardGame

Sammelkartenspiel mit biblischen Inhalten. Digitale Umsetzung in Flutter mit
reiner Dart-Spiel-Engine; später Online-Multiplayer und physische Karten.

## Dokumentation

Source of Truth für Regeln, Kartenformat, Architektur und Fahrplan liegt in
[`docs/`](docs/):

- [`docs/REGELWERK.md`](docs/REGELWERK.md) — Spielregeln
- [`docs/KARTEN_SPEZIFIKATION.md`](docs/KARTEN_SPEZIFIKATION.md) — Kartengeometrie, ID-Schema, JSON-Format
- [`docs/EFFEKTE.md`](docs/EFFEKTE.md) — Effekt-Vokabular
- [`docs/ARCHITEKTUR.md`](docs/ARCHITEKTUR.md) — Repo-Layout, Engine-Design
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — Phasenplan

## Struktur

```
engine/   reines Dart-Package (btcg_engine)   → cd engine && dart test
app/      Flutter-App (Web/Android, Hotseat)  → cd app && flutter run -d chrome
tools/    sheet_import, simulator             → dart run <tool>
data/     Kartensets (JSON)
legacy/   archivierter Qt-Prototyp (Tag: qt-prototype) — nur als Referenz
```

Siehe `CLAUDE.md` für Arbeitsprinzipien.
