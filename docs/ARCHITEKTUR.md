# Architektur — BibelTradingCardGame (Flutter)

> Leitplanken für die Implementierung. Kernprinzip: **Die Spiellogik ist eine
> reine, UI-freie Dart-Bibliothek.** Flutter ist nur eine von mehreren
> Oberflächen darüber (App, Simulator, später Server).

## 1. Repository-Layout

```
BibelTradingCardGame/
├── CLAUDE.md                  # Arbeitsanweisungen für Claude Code
├── docs/                      # REGELWERK, KARTEN_SPEZIFIKATION, ARCHITEKTUR, ROADMAP
├── engine/                    # Reines Dart-Package: Spiellogik (kein Flutter-Import!)
│   ├── lib/
│   │   ├── model/             # Karte, Slot, Spielfeld/Stapel, Spieler, GameState
│   │   ├── rules/             # Wertung, Zuglegalität, Phasen, Siegprüfung
│   │   ├── engine.dart        # GameEngine: wendet Commands an, emittiert Events
│   │   └── bots/              # Bot-Strategien (Zufall, Greedy, …)
│   └── test/                  # Regel-Tests, 1:1 aus REGELWERK.md abgeleitet
├── app/                       # Flutter-App (PWA-fähig wie flying_words)
│   └── lib/
│       ├── blocs/             # GameBloc u. a. — dünn, delegiert an engine
│       ├── ui/                # Screens, Karten-Widget, Stapel-/Loch-Darstellung
│       └── data/              # Laden der Sets aus data/, Asset-Zugriff
├── tools/
│   ├── sheet_import/          # CSV (Google Sheet) → data/sets/*.json + Validierung
│   └── simulator/             # CLI: Bot-vs-Bot-Massensimulation für Balancing
├── data/sets/                 # Kartendaten (JSON, Source of Truth zur Laufzeit)
├── assets/                    # Karten-Artwork, Symbol-Tiles
└── legacy/                    # Archivierter Qt/C++-Prototyp + Original-ArtWork
```

Engine, App und Tools als Dart-Workspace/Melos oder schlicht via
`path`-Dependencies — so einfach wie möglich, kein Overengineering.

## 2. Engine-Design

**Zustand:** `GameState` ist unveränderlich (immutable). Enthält: Spieler
(Heiligkeit, Hand, Deck-Rest), je Spieler 3 Stapel (Kartenlisten, Index 0 =
oben), aktive globale Effekte, Rundenzähler, Phase, RNG-Seed.

**Ablauf:** Command → Validierung → neuer `GameState` + Events.

```dart
sealed class Command {}        // KarteBauen(feld, karteId), EvilSpielen(ziel, feld, karteId),
                               // SofortReagieren(...), EvilBegraben() /*D6*/, ZugBeenden()
sealed class GameEvent {}      // KarteGelegt, WertungBerechnet(punkte, details),
                               // HeiligkeitGeaendert, SpielerGewonnen, ...
class GameEngine {
  GameState apply(GameState s, Command c); // wirft RegelVerstoss bei illegalem Zug
}
```

**Determinismus:** Sämtlicher Zufall (Mischen, Ziehen) läuft über einen im
`GameState` mitgeführten seedbaren RNG. Gleicher Seed + gleiche Commands =
gleiches Spiel. Das ist Voraussetzung für Replays, Tests, Simulation und
späteren Server-autoritativen Multiplayer.

**Wertung:** Exakt der Algorithmus aus REGELWERK.md §6, als pure Funktion
`Wertung berechne(GameState, spielerId)` mit Detail-Aufschlüsselung pro
Feld/Slot (die UI zeigt damit an, *woher* Punkte kommen — wichtig fürs
Verständnis der Loch-Mechanik).

**Keine UI-, IO- oder Flutter-Abhängigkeiten in `engine/`.** Kartendaten werden
der Engine als geparste Objekte übergeben; Laden/Parsen macht die App bzw. das Tool.

## 3. App (Phase 1: Hotseat)

- **Flutter Web (PWA) + Android**, Deployment wie flying_words über GitHub Pages.
- State-Management: **BLoC** (bewährtes Muster aus DFL/flying_words).
  `GameBloc` hält den `GameState`, übersetzt UI-Intents in Commands und Events
  in UI-Zustände. Keine Spiellogik im Bloc.
- **Hotseat zuerst:** 2 Spieler an einem Gerät, Übergabe-Screen („Gerät an
  Spieler 2 geben") verdeckt Handkarten. Danach optional Bot-Gegner aus
  `engine/bots/`.
- **Kern-UI-Herausforderung — Loch-Darstellung:** Der Stapel wird als *eine*
  zusammengesetzte Karte gerendert: pro Slot wird das oberste nicht-Loch-Symbol
  angezeigt, mit Tiefen-Hinweis (z. B. leichter Versatz/Schatten der
  darunterliegenden Kartenränder). Beim Legen einer Karte animiert das
  „Durchscheinen" (Symbole der unteren Karte erscheinen in den Löchern).
  Das ist das visuelle Alleinstellungsmerkmal — hierfür früh einen
  UI-Prototyp bauen und testen.
- Persistenz lokaler Spielstände: `HydratedBloc` (bekanntes Muster), kein
  Backend in Phase 1.

## 4. Simulator (Balancing)

CLI in `tools/simulator/`, nutzt dieselbe Engine:

```
dart run simulator --spiele 10000 --bots greedy,greedy --seed 42
```

Erhobene Metriken (Akzeptanzkriterien in ROADMAP.md):

- Partiedauer in Zügen (Verteilung) — Ziel grob 15–25 Züge
- Winrate Startspieler vs. Nachzieher (Ziel ~50 %, prüft D5)
- Häufigkeit Heiligkeit-0-Phasen (Frust-Indikator)
- Punktebeitrag je Kategorie und je Person (V/S/HG) — Dominanz-Erkennung
- Effekt einzelner Regelvarianten (D1A vs. D1B usw.) im A/B-Lauf

## 5. Phase 2 (Ausblick, nicht jetzt bauen)

- Zentraler Server (autoritative Engine-Instanz) für Online-Partien.
- Konten (Google OAuth wie in flying_words), Gast-IDs ohne Registrierung.
- Besitz physischer Karten: Exemplar-ID + TAN-Claiming (KARTEN_SPEZIFIKATION §4),
  Tausch nur für registrierte Konten.
- Die heutige Engine-Reinheit (deterministisch, Command-basiert) macht den
  Server-Einsatz ohne Umbau möglich — deshalb wird sie jetzt so gebaut.

## 6. Teststrategie

1. **Regelwerk-Tests:** Jede Regel aus REGELWERK.md bekommt mindestens einen
   Engine-Test; die Beispiele im Regelwerk sind Golden Tests.
2. **Wertungs-Fixtures:** Handkonstruierte Stapel mit erwarteter Punktzahl
   (insbesondere Loch-Ketten über mehrere Karten, schwarze Werte durch Löcher).
3. **Property-Tests:** Heiligkeit nie < 0; Kartenzahl konstant; Determinismus
   (Seed-Replay ergibt identische Events).
4. **Simulator-Smoke:** 1000 Zufallspartien ohne Exception/Endlosschleife.
