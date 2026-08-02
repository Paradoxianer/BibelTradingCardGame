# Kartenspezifikation — BibelTradingCardGame

> **v0.2 — abgeglichen mit den realen Kartendaten** (`Bibelsammelkartenspiel_final.json`,
> 106 Karten, Stand 2026-07). Das Format folgt jetzt den vorhandenen Daten,
> nicht umgekehrt.

## 1. Geometrie

- Kartenformat: Querformat, Referenz-Artwork 1373 × 971 px
  (`legacy/ArtWork/R1301.png` als Layoutvorlage).
- **Symbolzeile oben:** genau **6 Slots**, Kacheln einheitlich
  (Referenz-Tiles 378 × 378 px in `legacy/ArtWork/`).

| Slot-Feld | `V1` | `V2` | `S1` | `S2` | `HG1` | `HG2` |
|---|---|---|---|---|---|---|
| Person | Vater | Vater | Sohn | Sohn | Hl. Geist | Hl. Geist |

Die Feldnamen `V1…HG2` sind aus den Bestandsdaten übernommen und gelten als
kanonisch. Reihenfolge in der Engine: `[V1, V2, S1, S2, HG1, HG2]`.

Festes Raster: Slots aller Karten liegen exakt übereinander, damit Löcher
deckungsgleich sind. Druckparameter/Stanz-Toleranz folgen in Phase 3.

## 2. Slot-Inhalte

| Code | Darstellung | Bedeutung | Wertung |
|------|-------------|-----------|---------|
| `"2"`, `"1"`, `"0"` | Bunter Kreis in Personenfarbe | Stärke | Zählt **nur durch ein Loch** sichtbar |
| `"-1"` | Schwarzer Kreis mit Minus-Strich | Schwäche | Zählt **immer**, sobald sichtbar |
| `"x"` | Stanzung / Loch (Tile `Empty.png`) | Fenster | Zeigt Slot der Karte darunter |

Kleinschreibung `"x"` wie in den Bestandsdaten. Werte sind **Strings**
(Sheet-Export); die Import-Pipeline typisiert sie.

Hinweis Bestand: Die Tiles `V_-1 / S_-1 / HG_-1` und `Evil` sind byte-identisch —
es gibt **ein** einheitliches schwarzes Schwäche-Symbol.

## 3. Kategorien und Bestand

Kategorie = Herkunfts-Tab der Quelldatei:

| Kategorie | Tab | Karten | Bemerkung |
|---|---|---:|---|
| `gebet` | `R_Gebet` | 66 | größter Block, enthält **kein** `-1` |
| `glauben` | `R_Glauben` | 13 | |
| `gottesdienst` | `R_Gottesdienst` | 7 | einzige Ressourcen mit `-1` (5×) |
| `evil` | `EvilDeck` | 19 | ausschließlich `-1` und `x` |
| `start` | `EvilDeck` | 1 | `EStart` |
| `tun` | *fehlt* | 0 | **TODO: Tab R_Tun existiert nicht in den Daten** |
| `lehre` | *fehlt* | 0 | **TODO: Tab R_Lehre existiert nicht in den Daten** |

Gesamt 106 Karten, alle `card_id` eindeutig. Für ein 35-Karten-Deck mit
7 *unterschiedlichen* Evil-Karten reicht der Bestand (19 Evil verfügbar);
die Kategorien sind aber stark ungleich gefüllt.

## 4. ID-Schema

Bestandsformat: `<PREFIX><BLOCK><NR>`, z. B. `RG0101`, `E1201`, `GD1203`, `EStart`.

Beobachtete Belegung:

| Präfix | Block | Kategorie |
|---|---|---|
| `RG` | `01xx` | Gebet |
| `RG` | `11xx` | Glauben |
| `GD` | `12xx` (+ `0102`) | Gottesdienst |
| `E` | `12xx` | Evil |
| `EStart` | — | Startkarte |

**Offene Punkte (kein Regel-, sondern Datenthema):**

1. `RG` bezeichnet sowohl Gebet als auch Glauben — eindeutig ist erst die
   Kombination mit dem Blocknummernbereich. Empfehlung: Präfixe eindeutig
   machen (`RG` = Gebet, `RGL` = Glauben) **oder** dokumentieren, dass allein
   der Block die Kategorie bestimmt. Nicht stillschweigend ändern: IDs können
   bereits auf Artwork/Ausdrucken stehen.
2. `GD0102` fällt aus dem `GD12xx`-Block.
3. Blocknummer `12` wird von Gottesdienst und Evil parallel genutzt.

Für Druck und Besitz-Verifikation (Phase 2/3) wird die Kartentyp-ID um
Set und Exemplar ergänzt:

```
Kartentyp-ID : <SET>-<card_id>            z. B. BASE-RG0101
Exemplar-ID  : <Kartentyp-ID>-<SERIE>     z. B. BASE-RG0101-000042  (nur physisch)
Geheimnis    : TAN, separat, nicht Teil der ID (Rubbelfeld / nur im QR)
```

Blockchain ist dafür nicht nötig; eine zentrale Besitztabelle genügt
(Begründung siehe ROADMAP Phase 2).

## 5. Datenformat

Die Bestandsstruktur (Objekt mit Tab-Namen → Kartenliste) wird beibehalten,
um die Sheet-Pipeline einfach zu halten. Ergänzt werden nur die Felder, die
das Spiel braucht.

```json
{
  "set": "BASE",
  "version": "0.2.0",
  "tabs": {
    "R_Gebet": [
      {
        "card_id": "RG0101",
        "name": "Gebetsunterstützung",
        "bible_vers": "Philipper 1,19",
        "bible_text": "Denn ich weiß, dass am Ende von allem …",
        "V1": "x", "V2": "x", "S1": "1", "S2": "0", "HG1": "1", "HG2": "0",
        "kategorie": "gebet",
        "seltenheit": "haeufig",
        "sofort": false,
        "effekt": null,
        "anzahlImDeckMax": 3,
        "picture_link": "https://github.com/Paradoxianer/BibelTradingCardGame/raw/master/ArtWork/Placeholder.png"
      }
    ]
  }
}
```

### Felder aus dem Bestand (beibehalten)

`card_id`, `name`, `bible_vers`, `bible_text`, `V1…HG2`, `picture_link`.

### Neue Felder

| Feld | Zweck |
|---|---|
| `kategorie` | s. §3, bisher nur implizit über den Tab |
| `seltenheit` | Diskrete Stufe für Booster/Shop (§7) |
| `sofort` | Reaktionskarte (REGELWERK D4) |
| `effekt` | `null` oder typisiertes Objekt gemäß **docs/EFFEKTE.md** |
| `anzahlImDeckMax` | Deckbau-Limit; Evil immer `1` |

### Abgeleitete Felder (nicht mehr pflegen)

- `strongness` — im Bestand **inkonsistent berechnet**: Für den EvilDeck gilt
  exakt `summe(werte) + 3 × anzahl(löcher)` (20/20 Karten), für die
  Ressourcen-Tabs passt diese Formel bei **keiner** Karte (dort stehen Werte
  wie `9.797958971132712`, offenbar eine andere Sheet-Formel).
  → Nicht importieren. Die Pipeline berechnet Kennzahlen neu und einheitlich.
- `rare` — Fließkommazahl 33,3–90,9 (Evil auch negativ). Nur als **Eingangs-
  signal** für die Einstufung in `seltenheit` verwenden, nicht als Spielwert.
- `effects` — im Bestand bei 105 von 106 Karten leer; einziger Wert
  `"Startkarte"` bei `EStart`. Das Effektsystem (EFFEKTE.md) ist also
  komplett neu zu befüllen, es geht nichts verloren.

### Bekannte Datenfehler (vor Import beheben)

| Fund | Ort |
|---|---|
| Eine Karte ohne Feld `name` | `R_Glauben` |
| `strongness` = `#NUM!` | 1 Karte in `R_Gottesdienst` |
| `rare` = `#NUM!` | 1 Karte in `R_Gottesdienst` |
| Alle `picture_link` zeigen auf `Placeholder.png` | alle Tabs |

## 6. Pipeline: Spreadsheet → JSON

Das Google Sheet bleibt die redaktionelle Quelle. `tools/sheet_import/`
konvertiert den Export und **validiert hart**:

1. `card_id` eindeutig, nicht leer
2. alle 6 Slot-Felder vorhanden, Werte aus `{"2","1","0","-1","x"}`
3. `name`, `bible_vers`, `bible_text` nicht leer
4. keine Sheet-Fehlerwerte (`#NUM!`, `#REF!`, `#DIV/0!`)
5. `effekt` valide gegen das Schema aus EFFEKTE.md
6. Evil-Karten: `anzahlImDeckMax == 1`
7. Report: Kennzahlen je Kategorie (Löcher, Wertsummen, Verteilung) als
   Balancing-Frühwarnung

## 7. Seltenheit (Vorbereitung für Booster/Shop)

Diskrete Stufen statt Fließkommazahl:

`haeufig | selten | episch | einzigartig`

Vergabe redaktionell, gestützt auf das Bestandsfeld `rare` und die
Effektstärke. **Verbindliche Leitplanke: Seltenheit bedeutet Vielfalt, nicht
Spielstärke** — kein Pay-to-win (Details ROADMAP Phase 3).

## 8. Artwork

- Aktuell verweisen alle Karten auf `Placeholder.png`.
- Zielpfad in der App: `assets/karten/<set>/<card_id>.webp`.
- Symbol-Tiles (V/S/HG × Wert, Evil, Empty) aus `legacy/ArtWork/` übernehmen.
- Personenfarben final in Phase 1 festlegen; zusätzlich zur Farbe eine
  Form-/Icon-Unterscheidung je Person (Farbfehlsichtigkeit).
