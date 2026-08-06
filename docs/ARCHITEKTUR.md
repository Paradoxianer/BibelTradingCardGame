# Architektur — BibelTradingCardGame (Flutter)

> Leitplanken für die Implementierung. Kernprinzip: **Die Spiellogik ist eine
> reine, UI-freie Dart-Bibliothek.** Flutter ist nur eine von mehreren
> Oberflächen darüber (App, Simulator, später Server).

## 0. Qualitätsanspruch (verbindlich)

Das Spiel soll **junge Menschen für den christlichen Glauben begeistern**.
Daraus folgt ein Anspruch, der über „funktioniert" hinausgeht: Darstellung,
Kartenlayout und Animationen müssen **Oberklasse** sein — auf dem Niveau
kommerzieller Sammelkartenspiele. Der Bibelvers ist dabei kein Beiwerk,
sondern trägt den Inhalt und gehört entsprechend prominent aufs Kartenlayout.

Praktische Konsequenzen für die Implementierung:

- Visuelle Entscheidungen werden **nicht geraten**. Referenz sind die
  Original-Tiles in `legacy/ArtWork/` und die Kartenentwürfe — im Zweifel
  am Asset nachmessen, nicht aus dem Namen einer Datei schließen.
- Ein „technisch korrektes", aber unleserliches oder unschönes Rendering
  gilt als Fehler, nicht als erledigt.
- Neue UI wird im echten Browser angesehen, bevor sie als fertig gilt.

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
(Heiligkeit, Hand, Deck-Rest),je Spieler 3 Stapel (Kartenlisten, Index 0 =
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

- **Flutter Web (PWA) + Android + iOS**, Deployment wie flying_words über
  GitHub Pages (Web). iOS-Build/-Test braucht Xcode auf macOS — auf einer
  Linux-Entwicklungsumgebung kann nur das Projektgerüst gepflegt werden,
  nicht kompiliert/verifiziert werden. Dafür entweder einen Mac oder einen
  Mac-CI-Runner (z. B. Codemagic, GitHub Actions `macos-latest`) einplanen.
- State-Management: **BLoC** (bewährtes Muster aus DFL/flying_words).
  `GameBloc` hält den `GameState`, übersetzt UI-Intents in Commands und Events
  in UI-Zustände. Keine Spiellogik im Bloc.
- **Hotseat zuerst:** 2 Spieler an einem Gerät, Übergabe-Screen („Gerät an
  Spieler 2 geben") verdeckt Handkarten. **Bot-Gegner aus `engine/bots/`**
  (GreedyBot) steht als Solo-Modus zur Verfügung — kein Übergabe-Screen
  nötig, der Bot zieht automatisch, sobald er an der Reihe ist.
- **Kern-UI-Herausforderung — Loch-Darstellung:** Der Stapel wird als *eine*
  zusammengesetzte Karte gerendert, mit Tiefen-Hinweis (leichter
  Versatz/Schatten der darunterliegenden Kartenränder). Beim Legen einer
  Karte animiert das „Durchscheinen". Das ist das visuelle
  Alleinstellungsmerkmal.

  **Verbindliche Regeln der Slot-Darstellung** (aus den Original-Tiles
  abgeleitet, nicht verhandelbar):

  1. Es sind **immer genau 6 Symbolzellen sichtbar** — nie Lücken. Eine
     Spalte, in der nichts zu sehen ist, ist ein Rendering-Fehler.
  2. Pro Spalte wird **eine** Zelle gezeichnet: das erste Nicht-Loch-Symbol
     von oben (`sichtbaresSymbolAn`, dieselbe Logik wie die Wertung, damit
     Bild und Punkte nie auseinanderlaufen).
  3. Wurde dabei durch **mindestens ein Loch** geschaut, liegt zusätzlich der
     **„zählt"-Marker** darüber: je ein Dreieck oben und unten. Ohne ihn ist
     die Loch-Mechanik für Spielende unsichtbar und das Onboarding wirkt
     widersprüchlich (bunter Wert sieht dann genauso aus, ob er zählt oder
     nicht).
  4. Ist eine Spalte über die **gesamte** Stapeltiefe Loch, wird das volle
     Loch-Tile gezeigt (Loch ohne etwas dahinter).

  **Bedeutung der Dreiecke** (aus den Original-Tiles abgelesen): Sie stehen
  für „dieser Wert zählt". Im Bestand tragen sie genau die beiden Symbole,
  die zählen — `-1` (zählt immer, sobald sichtbar) und `x` (das Loch, das
  das Zählen überhaupt ermöglicht). Die bunten Werte `0/1/2` haben sie
  **nicht**, weil sie nur durch ein Loch zählen; sie bekommen die Dreiecke
  deshalb zur Laufzeit genau dann als Overlay, wenn durch ein Loch auf sie
  geschaut wird. Prüfbar über die Bounding-Box: Tiles mit Dreiecken reichen
  über die volle Kachelhöhe (y = 0…378), reine Wertkreise nur y = 46…334.

  Gestaltung des Markers: **nicht pixelgenau festgelegt.** Maßgeblich ist,
  dass alle Tiles **dieselbe Designsprache** haben (gleiche Kreisgröße und
  -position, damit die Spalten sauber untereinanderstehen) und dass klar
  erkennbar ist, **welcher Wert zählt**. Die Dreiecke dürfen dafür gerne
  größer und markanter sein als im Original-Tile.

  Asset-Hinweise: `Empty.png`, `V_x.png`, `S_x.png`, `HG_x.png` sind
  **byte-identisch** — es gibt genau ein Loch-Tile, personenunabhängig
  (ebenso sind `Evil.png` und die drei `*_-1.png` identisch). Das Loch-Tile
  ist **opak** (weiße Fläche mit Schraffur), taugt also nicht als Overlay;
  dafür braucht es einen separaten Marker mit transparenter Innenfläche.
  Orientierungsmaße aus dem Bestand (378×378): Kreis Ø ≈ 287 px, vertikal
  wie die Wert-Tiles zentriert; Dreiecke oben und unten, Spitze zum Ring hin.
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
- **Verborgene Information und Wertung gehören auf den Server.** Im
  Hotseat-Modus liegt der vollständige `GameState` im Client, das ist dort
  unkritisch. Online gilt: der Client ist nicht vertrauenswürdig.

  Serverseitig gehalten und berechnet werden müssen:

  1. **Verdeckte Information** — Deckreihenfolge, fremde Handkarten. Sonst
     lässt sie sich aus dem Client auslesen.
  2. **Die Slot-Werte der Karten** (`x`, `-1`, `0`, `1`, `2`). Ein
     manipulierter Client darf seinen Karten keine besseren Werte andichten
     können.
  3. **Die daraus resultierende Wertung** (Heiligkeits-Änderung pro Zug).
     Der Client zeigt Punkte nur an, er ermittelt sie nicht verbindlich.

  Der Server hält den autoritativen Zustand, schickt jedem Client nur dessen
  Sicht und prüft jeden Command auf Legalität. Beim Entwurf des
  Netzwerkprotokolls ist das die Leitfrage — nachträglich nicht reparierbar.

## 6. Teststrategie

1. **Regelwerk-Tests:** Jede Regel aus REGELWERK.md bekommt mindestens einen
   Engine-Test; die Beispiele im Regelwerk sind Golden Tests.
2. **Wertungs-Fixtures:** Handkonstruierte Stapel mit erwarteter Punktzahl
   (insbesondere Loch-Ketten über mehrere Karten, schwarze Werte durch Löcher).
3. **Property-Tests:** Heiligkeit nie < 0; Kartenzahl konstant; Determinismus
   (Seed-Replay ergibt identische Events).
4. **Simulator-Smoke:** 1000 Zufallspartien ohne Exception/Endlosschleife.
