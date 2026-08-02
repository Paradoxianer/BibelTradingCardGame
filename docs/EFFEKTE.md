# Effekte v0.3 — BibelTradingCardGame

> Typisiertes Effekt-Vokabular. Karten dürfen keine freien Regeltexte tragen;
> jeder Effekt ist eine Instanz eines der hier definierten Typen. Neue Typen
> nur über dieses Dokument (Design-Entscheidung), nie direkt im Code.
> Leitgedanke: Jeder Effekt erzählt eine biblische Wahrheit als Regel.

## 1. Grundregeln

1. **Aktivierung (Standard):** Ein Dauereffekt wirkt nur, solange die Karte die
   **oberste** ihres Stapels ist (`dauer: "solange_oben"`). Überbauen aktiviert
   ihre bunten Punkte, beendet aber den Effekt — das ist das zentrale Dilemma
   und gewollt.
2. **Einmal-Effekte** (`dauer: "sofort"`) wirken beim Ausspielen und sind dann
   verbraucht; die Karte bleibt normal als Slot-Träger liegen.
3. **Keine Effekt-Ketten:** Effekte lösen keine weiteren Effekte aus, es gibt
   keinen Stack à la Magic. Einzige Reaktion im Spiel bleibt das
   `sofort`-Merkmal als Antwort auf eine Evil-Karte (REGELWERK D4).
4. **Bezahlte Macht:** Effektkarten tragen im Ausgleich schwächere Slot-Zeilen
   (weniger/niedrigere bunte Werte oder zusätzliche schwarze). Richtwert bis
   zur Simulation: Effektkarte ≈ 2–3 Slot-Punkte unter dem Kategorie-Schnitt.
5. **Sichtbarkeit:** Effekte stehen als Symbol + ein kurzer fester Text auf der
   Karte; der Text ist reine Wiedergabe des Typs, nie eine Sonderregel.

## 2. Effekt-Typen

### 2.1 `umkehrung` — Böses wird zum Guten gewendet
*Gen 50,20; Röm 8,28*

Sichtbare **schwarze** Werte dieses Stapels zählen in der Wertung **positiv**
statt negativ — aber **nur in den angegebenen Slots**.

- `parameter.slots`: Liste der betroffenen Slot-Positionen (1–6).
  Zur Balance bewusst eng: typisch **ein** Slot, maximal zwei benachbarte
  (z. B. `[1]` oder `[1,2]`). Eine Voll-Umkehrung (alle 6) existiert nicht
  im Basis-Set.
- `dauer`: `solange_oben`
- Wertung: Im Algorithmus (REGELWERK §6) wird für diesen Stapel in den
  betroffenen Spalten `punkte += |wert|` statt `punkte += wert` gerechnet,
  wenn das gefundene Symbol schwarz ist.
- Design-Hinweis: Selten und wertvoll; Slot-Wahl macht Varianten möglich
  (V-Umkehrung `[1]`, HG-Umkehrung `[6]` …) ohne neue Regeln.

### 2.2 `schutz` — Anfechtung abgewehrt
*Eph 6,16 (Schild des Glaubens)*

Wehrt die nächste Evil-Karte ab, die gegen dieses Spielfeld (oder den Spieler,
siehe Parameter) gespielt wird. Die Evil-Karte geht zurück auf die Hand des
Angreifers; sein Evil-Spielrecht dieser Runde ist verbraucht.

- `parameter.reichweite`: `"feld"` (nur der eigene Stapel) oder `"spieler"`
  (alle drei Felder; entsprechend teurer).
- `parameter.ladungen`: Anzahl Abwehren, Standard 1; danach erlischt der
  Effekt (Karte bleibt liegen).
- `dauer`: `solange_oben`
- Typischer Träger des `sofort`-Merkmals: als Reaktion direkt unter die
  ankommende Evil-Karte… nein — als Reaktion **auf das bedrohte Feld obenauf**
  gespielt, die Evil-Karte wird abgewehrt (Reihenfolge gemäß REGELWERK D4).

### 2.3 `gebietserweiterung` — Raum wird weit
*1 Chr 4,10 (Gebet des Jabez)*

Fügt dem Spieler ein **viertes Spielfeld** hinzu. Die Effektkarte selbst wird
die **unterste Karte** dieses neuen Feldes — der Effekt ist damit strukturell
und dauerhaft, die Frage „was passiert beim Überbauen" stellt sich nicht.

- `parameter`: keine.
- `dauer`: `permanent` (einzige Ausnahme von Regel 1, da die Karte das Feld *ist*).
- Limit: maximal **eine** Gebietserweiterung pro Spieler und Partie.

### 2.4 `zuwendung` — Empfangen
*Mt 7,7 („Bittet, so wird euch gegeben")*

Einmaliger Vorteil beim Ausspielen.

- `parameter.art`: `"karten"` oder `"heiligkeit"`
- `parameter.menge`: ganze Zahl > 0 (Richtwert: 2 Karten oder 3 Heiligkeit;
  Feinjustierung per Simulation)
- `dauer`: `sofort`

### 2.5 `globale_aura` — Wirkung auf alle
*Mt 5,16 („Lasst euer Licht leuchten vor den Leuten")*

Fester Wertungs-Zuschlag für **alle** Spieler, solange aktiv (das ist der
Platzhalter „globale Effekte" im Wertungsalgorithmus REGELWERK §6).

- `parameter.wert`: ganze Zahl (positiv = Segen für alle; negative Auren sind
  Evil-Karten vorbehalten und kommen erst mit dem EvilDeck-Import).
- `dauer`: `solange_oben`
- Design-Hinweis: bewusst symmetrisch — thematisch (Segen strahlt aus) und
  ein natürlicher Aufhol-Dämpfer ist es nicht; Balancing beobachten.
- evtl gekoppelt an Slots (1.Slot von allen Spielern bring +1 (könnte für manche negativ sein für andere sehr positiv))

### 2.6 `suche` — Gezielt finden (Tutor)
*Lk 15,8–9 (die verlorene Drachme: „…kehrt das Haus und sucht mit Fleiß, bis sie ihn findet")*

Durchsuche dein Deck nach einer Karte, die dem Filter entspricht, nimm sie auf
die Hand, mische danach das Deck.

- `parameter.filter`: `"beliebig"` oder eine Kategorie
  (`gebet|glauben|tun|lehre|gottesdienst`). Evil ist nie suchbar.
- `dauer`: `sofort`
- Design-Hinweis: Klassischer „Tutor" — macht Decks konsistenter und ist
  erfahrungsgemäß stärker als er aussieht. Enger Filter = fairer. Kein
  Suchen im gegnerischen Deck.

### 2.7 `erneuerung` — Zurück ins Deck
*Klgl 3,22–23 („…seine Barmherzigkeit hat noch kein Ende, sondern sie ist alle Morgen neu")*

Mische bis zu X Karten aus deiner **Hand** zurück in dein Deck und ziehe
ebenso viele nach.

- `parameter.menge`: int ≥ 1 (Richtwert 2–3)
- `dauer`: `sofort`
- Design-Hinweise:
  - Wichtigstes Ventil gegen Evil-Handverstopfung (REGELWERK D6) — ggf. macht
    diese Karte die Sonderregel D6-A überflüssig; per Simulation prüfen.
  - Wechselwirkung mit D2 (Deck als Partie-Uhr): `erneuerung` verlängert die
    Partie um bis zu `menge` Züge. Deshalb `menge` klein halten und Karte
    auf `anzahlImDeckMax: 1–2` begrenzen.
  - Ein **pures Neu-Mischen des Decks** ist bewusst kein eigener Effekt: Da
    die Deck-Reihenfolge ohnehin verborgen ist, hätte es keine Spielwirkung.
    Es ist als Bestandteil von `suche` und `erneuerung` enthalten und würde
    erst relevant, falls je ein Effekt Deck-Karten aufdeckt (dann hier ergänzen).

### 2.8 `umordnung` — Eine Karte im Stapel versetzen
*Eigenvariante: 1 Kor 14,40 („Lasst aber alles ehrbar und ordentlich zugehen") ·
Gegnervariante: Lk 22,31 („Satan hat begehrt, euch zu sieben wie den Weizen")*

Bewege genau **eine** Karte innerhalb eines Stapels an eine andere Position
(nicht zwischen Stapeln). Sichtbarkeiten und damit die Wertung können dadurch
komplett kippen.

- `parameter.ziel`: `"eigen"` oder `"gegner"`.
  Die **Gegner-Variante ist Evil-Karten vorbehalten** („sieben wie den Weizen")
  und kommt erst mit dem EvilDeck-Import (§5) — im Basis-Set existiert nur
  `"eigen"`.
- `dauer`: `sofort`
- Design-Hinweise:
  - Wichtig (Startkarte - ist ausgenommen (Evil))
  - Dies ist die **einzige sanktionierte Ausnahme** von der eingefrorenen
    Stapel-Reihenfolge (REGELWERK D3-A) — genau der dort erwähnte „seltene
    Karteneffekt". Entsprechend: `anzahlImDeckMax: 1`, hohe Effektkosten.
  - Wirkung ist schwer abschätzbar (eine Verschiebung kann mehrere Slot-Spalten
    gleichzeitig drehen) → Pflichtkandidat für die Simulation in Phase 1b.
  - Das bloße **Durchschauen** eines Stapels ist bewusst kein Effekt, sondern
    hängt an der offenen Regelfrage D9 (ist Stapelinhalt öffentliche
    Information?). Fällt D9 auf „verdeckt", wird hier ein eigener
    Aufdeck-Effekt ergänzt.



## 3. JSON-Schema (`effekt`-Feld, KARTEN_SPEZIFIKATION §5)

```json
"effekt": null
```
oder
```json
"effekt": {
  "typ": "umkehrung | schutz | gebietserweiterung | zuwendung | globale_aura | suche | erneuerung | umordnung",
  "dauer": "solange_oben | sofort | permanent",
  "parameter": { }
}
```

Gültige `parameter` je Typ (alles andere ist ein Validierungsfehler der
Import-Pipeline):

| typ | parameter | dauer (fix) |
|---|---|---|
| `umkehrung` | `slots`: Array 1–6, Länge 1–2 | `solange_oben` |
| `schutz` | `reichweite`: feld\|spieler; `ladungen`: int ≥ 1 | `solange_oben` |
| `gebietserweiterung` | — | `permanent` |
| `zuwendung` | `art`: karten\|heiligkeit; `menge`: int ≥ 1 | `sofort` |
| `globale_aura` | `wert`: int ≠ 0 | `solange_oben` |
| `suche` | `filter`: beliebig\|<kategorie> (nie evil) | `sofort` |
| `erneuerung` | `menge`: int ≥ 1 | `sofort` |
| `umordnung` | `ziel`: eigen\|gegner (gegner nur Evil, ab EvilDeck) | `sofort` |

## 4. Beispielkarten

```json
{
  "id": "BASE-L2001",
  "name": "Gott gedachte es gut zu machen",
  "kategorie": "lehre",
  "vers": { "stelle": "1. Mose 50,20", "text": "Ihr gedachtet es böse mit mir zu machen, aber Gott gedachte es gut zu machen." },
  "slots": ["X", "0", "1", "0", "X", "0"],
  "sofort": false,
  "effekt": { "typ": "umkehrung", "dauer": "solange_oben", "parameter": { "slots": [1] } },
  "anzahlImDeckMax": 1
}
```

```json
{
  "id": "BASE-G3001",
  "name": "Schild des Glaubens",
  "kategorie": "glauben",
  "vers": { "stelle": "Epheser 6,16", "text": "Vor allen Dingen aber ergreift den Schild des Glaubens, mit dem ihr auslöschen könnt alle feurigen Pfeile des Bösen." },
  "slots": ["0", "X", "1", "X", "0", "0"],
  "sofort": true,
  "effekt": { "typ": "schutz", "dauer": "solange_oben", "parameter": { "reichweite": "feld", "ladungen": 1 } },
  "anzahlImDeckMax": 2
}
```

```json
{
  "id": "BASE-R1002",
  "name": "Gebet des Jabez",
  "kategorie": "gebet",
  "vers": { "stelle": "1. Chronik 4,10", "text": "…dass du mein Gebiet erweitern wolltest…" },
  "slots": ["0", "X", "0", "X", "1", "0"],
  "sofort": false,
  "effekt": { "typ": "gebietserweiterung", "dauer": "permanent", "parameter": {} },
  "anzahlImDeckMax": 1
}
```

```json
{
  "id": "BASE-R1003",
  "name": "Bittet, so wird euch gegeben",
  "kategorie": "gebet",
  "vers": { "stelle": "Matthäus 7,7", "text": "Bittet, so wird euch gegeben; suchet, so werdet ihr finden; klopfet an, so wird euch aufgetan." },
  "slots": ["0", "1", "X", "0", "1", "X"],
  "sofort": false,
  "effekt": { "typ": "zuwendung", "dauer": "sofort", "parameter": { "art": "karten", "menge": 2 } },
  "anzahlImDeckMax": 2
}
```

```json
{
  "id": "BASE-T4001",
  "name": "Lasst euer Licht leuchten",
  "kategorie": "tun",
  "vers": { "stelle": "Matthäus 5,16", "text": "So lasst euer Licht leuchten vor den Leuten, damit sie eure guten Werke sehen und euren Vater im Himmel preisen." },
  "slots": ["0", "X", "0", "1", "X", "1"],
  "sofort": false,
  "effekt": { "typ": "globale_aura", "dauer": "solange_oben", "parameter": { "wert": 1 } },
  "anzahlImDeckMax": 1
}
```

```json
{
  "id": "BASE-G3002",
  "name": "Die verlorene Drachme",
  "kategorie": "glauben",
  "vers": { "stelle": "Lukas 15,8-9", "text": "…zündet sie nicht ein Licht an und kehrt das Haus und sucht mit Fleiß, bis sie ihn findet?" },
  "slots": ["0", "X", "0", "0", "X", "1"],
  "sofort": false,
  "effekt": { "typ": "suche", "dauer": "sofort", "parameter": { "filter": "gebet" } },
  "anzahlImDeckMax": 1
}
```

```json
{
  "id": "BASE-R1004",
  "name": "Alle Morgen neu",
  "kategorie": "gebet",
  "vers": { "stelle": "Klagelieder 3,22-23", "text": "Die Güte des HERRN ist's, dass wir nicht gar aus sind, seine Barmherzigkeit hat noch kein Ende, sondern sie ist alle Morgen neu." },
  "slots": ["X", "0", "1", "X", "0", "0"],
  "sofort": false,
  "effekt": { "typ": "erneuerung", "dauer": "sofort", "parameter": { "menge": 2 } },
  "anzahlImDeckMax": 1
}
```

*(Slot-Zeilen und Werte der Beispiele sind Platzhalter auf „bewusst schwach"-
Niveau gemäß §1.4 — Feinjustierung erst in Phase 1b per Simulation.)*

## 5. Engine-Hinweise

- `umkehrung` und `globale_aura` greifen ausschließlich in der Wertungsfunktion.
- `schutz` greift als Interceptor im Command `EvilSpielen` bzw. in der
  Reaktionsphase — kein allgemeines Trigger-System bauen (YAGNI), zwei
  konkrete Haken genügen für v0.1.
- `gebietserweiterung` verändert die Struktur des `GameState` (Feldliste
  statt festem 3er-Array modellieren).
- Evil-Karten mit Effekten (z. B. negative Auren) sind für v0.1 **explizit
  ausgeklammert** und kommen mit dem EvilDeck-Import als eigene Erweiterung
  dieses Dokuments.
