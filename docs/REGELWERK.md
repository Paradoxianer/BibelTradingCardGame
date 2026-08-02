# Regelwerk v0.9 — BibelTradingCardGame

> **Status:** Regeln vollständig entschieden (§7), Zahlenwerte noch in
> Feinjustierung (Phase 1b, Simulation). Dieses Dokument ist die **Source of
> Truth** für die Spiel-Engine: Jede Regel hier muss eindeutig implementierbar
> sein. Kartendaten und -format: KARTEN_SPEZIFIKATION.md · Effekte: EFFEKTE.md

## 1. Thema & Ziel

Jeder Spieler strebt danach, „durch und durch geheiligt" zu werden (Hebräer 10,10).
Die **Heiligkeit** ist der Punktestand eines Spielers.

- Start-Heiligkeit: **30**
- Siegbedingung: Als Erster **100** Heiligkeit erreichen.
- Untergrenze: Heiligkeit kann nie unter **0** fallen.

Leitmotiv der Mechanik: *„Überwinde das Böse mit Gutem"* (Röm 12,21) — Böses wird
nicht zerstört, sondern überbaut/überdeckt.

## 2. Material

- Pro Spieler ein **Deck aus 35 Karten**, davon **genau 7 Evil-Karten**,
  die alle **unterschiedlich** sein müssen.
- Pro Spieler **3 Spielfelder** (= 3 Ablagestapel) vor sich.
- Die Startkarte **EStart „Alle sind Sünder"** liegt zu Beginn auf Spielfeld 1
  jedes Spielers. Sie zeigt in allen 6 Slots `-1` und hat kein Loch
  (Erläuterung §7).
- Punktezettel bzw. App-Zähler für die Heiligkeit.

## 3. Kartenaufbau (Kurzfassung, Details in KARTEN_SPEZIFIKATION.md)

Jede Karte hat **oben eine Symbolzeile mit 6 Slots**:

| Slot | 1 | 2 | 3 | 4 | 5 | 6 |
|------|---|---|---|---|---|---|
| Person | Vater | Vater | Sohn | Sohn | Hl. Geist | Hl. Geist |

Jeder Slot enthält genau eines von:

- **Bunter Wert** `0 | 1 | 2` — Stärke. Zählt **nur**, wenn er durch ein Loch
  einer darüberliegenden Karte sichtbar ist.
- **Schwarzer Wert** `−1` — Schwäche. Zählt **immer**, sobald er sichtbar ist
  (oberste Karte oder durch Löcher).
- **Loch** `X` (Stanzung) — zeigt den Slot der darunterliegenden Karte.

**Kernprinzip:** Eine ausgespielte Karte zeigt ihre Schwächen sofort; ihre Stärken
entfalten sich erst, wenn eine spätere Karte mit Loch an dieser Position auf sie
gelegt wird. (Mechanik = Botschaft: Gutes trägt Frucht durch das, was darauf
aufbaut; Böses wird durch Überdecken überwunden.)

Weitere Kartenelemente: Name, Bibelvers (Stelle + Text), Kategorie
(Gebet, Glauben, Tun, Lehre, Gottesdienst, Evil), optionaler Effekt,
Sofort-Kennzeichnung (§7 D4).

## 4. Spielaufbau

1. Jeder Spieler mischt sein Deck und legt es verdeckt vor sich.
2. EStart wird auf Spielfeld 1 gelegt (kostet unbedeckt −6/Runde).
3. Jeder Spieler zieht **5 Handkarten**.
4. Startspieler wird zufällig bestimmt.

## 5. Rundenablauf (pro Spieler, im Uhrzeigersinn)

Ein Zug besteht aus diesen Phasen, in fester Reihenfolge:

1. **Bauen:** Der Spieler darf **eine** Karte aus der Hand offen auf eines
   seiner drei Spielfelder legen (immer **obenauf** auf den dortigen Stapel,
   siehe D3).
2. **Evil spielen:** Der Spieler darf **zusätzlich eine** Evil-Karte aus der Hand
   auf ein Spielfeld eines Mitspielers legen — aber nur auf einen Spieler, der in
   dieser **Runde** noch keine Evil-Karte erhalten hat. **Der Angreifer wählt
   das Spielfeld des Ziels**; die Karte kommt dort obenauf (D1).
   - **Verboten in der ersten Runde der Partie.**
   - Der betroffene Spieler darf **sofort reagieren**, indem er eine Karte mit
     Sofort-Kennzeichnung aus der Hand spielt *(D4)*.
3. **Wertung:** Die Heiligkeits-Änderung des aktiven Spielers wird berechnet
   (Algorithmus in Abschnitt 6) und seiner Heiligkeit gutgeschrieben bzw.
   abgezogen (Untergrenze 0).
4. **Nachziehen:** Der Spieler zieht vom eigenen Deck auf **5 Handkarten** auf.
   Deck leer: es wird nicht mehr nachgezogen (D2).
5. Der nächste Spieler ist an der Reihe.

Erreicht ein Spieler am Ende seiner Wertungsphase ≥ 100 Heiligkeit, gewinnt er
sofort.

## 6. Wertungsalgorithmus (verbindlich für die Engine)

Gewertet werden **alle drei Spielfelder des aktiven Spielers**, je Spielfeld alle
6 Slot-Spalten. Pro Spalte wird von der obersten Karte abwärts geschaut:

```
punkte = 0
für jedes Spielfeld f (Stapel, oberste Karte = Index 0):
  für jeden Slot s in 1..6:
    tiefe = 0
    solange karte[f][tiefe].slot[s] == LOCH:
      tiefe += 1
      wenn keine Karte mehr: → Spalte zählt 0, weiter mit nächstem Slot
    symbol = karte[f][tiefe].slot[s]
    wenn symbol schwarz (−1):
      punkte += symbol.wert            # immer, wenn sichtbar (auch tiefe == 0)
    sonst wenn tiefe > 0:              # bunter Wert, durch Loch sichtbar
      punkte += symbol.wert
    # bunter Wert auf der obersten Karte (tiefe == 0) zählt NICHT
punkte += summe aller aktiven globalen Karteneffekte
heiligkeit = max(0, heiligkeit + punkte)
```

Konsequenz: Das Board ist ein **wiederkehrender Motor** — dieselbe Auslage wird
jede Runde erneut gewertet. Das ist gewollt, birgt aber Schneeball-Risiko
(→ BALANCING in ROADMAP.md, Simulation vor Feinjustierung der Kartenwerte).

## 7. Entscheidungen

Stand 2026-07-26. **Alle D-Punkte sind entschieden**; offen ist nur noch die
Feinjustierung von Zahlenwerten in Phase 1b (Simulation).

| # | Thema | Entscheidung |
|---|---|---|
| D1 | Evil-Platzierung | **Angreifer wählt** eines der 3 Felder des Ziels, Karte kommt obenauf |
| D2 | Deck leer | Kein Nachziehen mehr; kann niemand mehr handeln, gewinnt die höchste Heiligkeit. Das Deck ist die Partie-Uhr |
| D3 | Stapel | Jedes Feld = ein Stapel, neue Karte immer obenauf, kein Umsortieren (Ausnahme: D10) |
| D4 | Sofort-Karten | Teilmenge der Karten trägt `sofort`; nur als Reaktion auf eine gegen dich gespielte Evil-Karte, auf das betroffene Feld |
| D5 | Startspieler | Kein Evil in Runde 1. Zusatzoption „Startspieler zieht nur 4 Karten" bleibt Simulations-Flag (Messung s. u.) |
| D6 | Evil-Handverstopfung | Keine eigene Sonderregel. Ventil ist der Effekt `erneuerung` (EFFEKTE.md §2.7); Simulation prüft, ob das genügt |
| D7 | EStart | **Aus den Bestandsdaten übernommen:** alle 6 Slots `-1`, keine Löcher (`strongness -6`) |
| D8 | Targeting 3+ Spieler | Regel „nur wer diese Runde noch kein Evil bekam" bleibt; Kingmaking wird zunächst zugelassen und in Phase 1b gemessen |
| D9 | Informationsstand | Hand und Deck sind **verborgen**. Ausliegende Stapel dürfen **jederzeit durchgeblättert** werden (App: Tippen auf den Stapel zeigt alle Karten von oben nach unten) |
| D10 | Umordnung | Bestätigt als einzige Ausnahme von D3: Effekt `umordnung` (EFFEKTE.md §2.8), Gegner-Variante nur auf Evil-Karten |

### Erläuterung zu D7 — „Alle sind Sünder"

EStart zeigt in allen sechs Slots `-1` und hat **kein** Loch. Wirkung:

- Unbedeckt kostet EStart **−6 Heiligkeit pro Runde**.
- Legt man eine Karte darauf, zählen nur noch die `-1`, die durch deren Löcher
  scheinen — der Schaden sinkt auf −(Anzahl Löcher).
- Mit jeder weiteren Schicht wird es unwahrscheinlicher, dass eine Spalte
  durchgehend aus Löchern besteht. Sünde verschwindet also nicht, sie wird
  **überbaut** — Mechanik und Botschaft fallen zusammen (Röm 12,21).
- Vollständig zudecken können EStart nur lochfreie Karten; davon gibt es im
  Bestand genau zwei (`RG1103`, `RG1108`). Das ist als seltener Glücksfall
  in Ordnung, sollte aber beim Ergänzen von `R_Tun`/`R_Lehre` bewusst
  mitgestaltet werden.

### Baseline-Messung (Prototyp-Simulation auf den echten Kartendaten)

Grobe Vorabsimulation mit Greedy-Bots, 300 Partien je Variante,
Decks aus dem Bestand (28 Ressourcen + 7 verschiedene Evil):

| Kennzahl | Ergebnis | Zielwert |
|---|---|---|
| Partiedauer mit Evil | Median **16 Züge** (9–26) | 15–25 ✅ |
| Partiedauer ohne Evil | Median 11 Züge | — (zeigt: Evil verlängert um ~5 Züge) |
| Startspieler-Winrate | **56 %** | 48–52 % ⚠️ → D5-Zusatzoption prüfen |
| Tiefpunkt Heiligkeit | Median 29, nie 0 erreicht | kein Frust-Aus ✅ |
| Ertrag pro Zug | Zug 1: −1,4 → Zug 8: +7,9 → Plateau ~+8 | Schneeball vorhanden, aber **gedeckelt** ✅ |

Lesart: Die Eröffnung ist trotz EStart nicht erdrückend (ab Zug 2 positiv),
und der Schneeball läuft nicht davon, weil 3 Felder × 6 Slots den Ertrag
natürlich begrenzen. Der einzige klare Ausreißer ist der Startspielervorteil.

*Diese Zahlen sind eine Vorabschätzung mit vereinfachten Bots (keine
Effekte, keine Sofort-Reaktionen) und ersetzen die Simulation aus Phase 1b nicht.*

## 8. Begriffe (Glossar)

| Begriff | Bedeutung |
|---|---|
| Heiligkeit | Punktestand eines Spielers (0–100) |
| Spielfeld | Einer der 3 Ablagestapel eines Spielers |
| Slot | Eine der 6 Symbolpositionen in der Kopfzeile einer Karte |
| Loch / Stanzung (`X`) | Ausgestanzter Slot, zeigt die Karte darunter |
| Evil-Karte | Negative Karte, wird Mitspielern zugespielt |
| Sofort | Merkmal: als Reaktion außerhalb des eigenen Zugs spielbar |
| EStart | Startkarte „Alle sind Sünder" auf Feld 1, 6× `-1`, lochfrei |
