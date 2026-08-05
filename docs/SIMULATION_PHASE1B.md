# Simulationsbericht — Phase 1b (Bot-Massensimulation)

> Stand: 2026-08-05. Erzeugt mit `tools/simulator` gegen `data/sets/base.json`
> (106 Karten, Set BASE). Ergänzt die Baseline-Messung in REGELWERK.md §7 um
> mehr Bot-Stile und dient als Diskussionsgrundlage für Phase 1b — **kein
> Ersatz für die dort vorgesehenen Playtests mit echten Menschen** und keine
> Freigabe einer D-Entscheidung.

## Methodik

- **Engine:** `btcg_engine`, deterministisch, seedbar. Jede Partie: 300
  Durchläufe, Startseed 1, Schrittweite 10 zwischen Partien.
- **Decks:** je Partie zufällig aus dem vollen Kartenpool gebaut (28
  Ressourcen + 7 unterschiedliche Evil, REGELWERK §2), unabhängig pro Spieler.
- **Reaktion-Phase:** kein Bot reagiert aktiv (im Bestand hat keine Karte
  `sofort: true` — siehe „Bekannte Grenzen" unten).
- **Abbruchsicherung:** Partien, die nach 20.000 Commands nicht enden,
  zählen als „abgebrochen", nicht als Fehler. In allen Läufen unten: 0
  Abbrüche.

## Bot-Übersicht (`engine/lib/bots/`)

| Bot | Bauen | Evil |
|---|---|---|
| `ZufallsBot` | zufällige Handkarte auf zufälliges Feld (oder zufällig passen) | zufällige Evil-Karte auf zufälliges legales Ziel (oder passen) |
| `GreedyBot` | Karte/Feld mit bestem Sofort-Wertungs-Preview, auch bei Gleichstand/Verschlechterung (siehe Erkenntnis 1) | Ziel, das den größten Schaden anrichtet |
| `DefensivBot` | wie Greedy | passt immer — außer die Hand ist komplett mit Evil verstopft (Notausgang, siehe Erkenntnis 2) |
| `AnfuehrerBot` | wie Greedy | greift immer den Spieler mit der höchsten Heiligkeit an (Kingmaking-Test, D8) — **bei 2 Spielern identisch zu Greedy**, Unterschied zeigt sich erst bei 3+ Spielern |

## Ergebnisse (mit Evil, sofern nicht anders vermerkt)

| Paarung | Variante | Partiedauer (Median) | Startspieler-Winrate | Tiefpunkt Heiligkeit | Dominanz Kategorie | Dominanz Person |
|---|---|---:|---:|---:|---|---|
| Greedy vs. Greedy | Basis | 31 | 52,7% | 0 | gebet 63,5% | Vater 45,2% |
| Greedy vs. Greedy | ohne Evil | 21 | 61,0% | 27 | gebet 78,3% | Vater 44,5% |
| Greedy vs. Greedy | D5 (Startspieler 4 Karten) | 31 | 53,7% | 0 | gebet 63,4% | Vater 45,0% |
| Zufall vs. Zufall | Basis | 72 | 47,0% | 0 | evil 49,3% | Sohn 51,7%* |
| Zufall vs. Zufall | ohne Evil | 46 | 52,0% | 0 | gebet 63,5% | Vater 58,7% |
| Greedy vs. Zufall | Basis | 28 | 50,0% | 0 | gebet 42,5% | Vater 54,1% |
| Defensiv vs. Defensiv | Basis | 23 | 59,0% | 22 | gebet 75,5% | Vater 45,0% |
| Defensiv vs. Greedy | Basis | 23 | 51,0% | 0 | gebet 67,2% | Vater 45,5% |
| Defensiv vs. Greedy | ohne Evil | 21 | 61,0% | 27 | gebet 78,3% | Vater 44,5% |
| Anführer vs. Greedy | Basis | 31 | 52,7% | 0 | gebet 63,5% | Vater 45,2% |
| Anführer vs. Defensiv | Basis | 24 | 50,0% | 0 | gebet 66,4% | Vater 45,3% |
| Anführer vs. Anführer | Basis | 31 | 52,7% | 0 | gebet 63,5% | Vater 45,2% |

*„Dominanz Person" bei Zufall vs. Zufall ist mit Vorsicht zu lesen: die
Summen sind hier überwiegend negativ (Evil dominiert), „Anteil" meint den
Anteil am Betrag, nicht am Nutzen.

**Zielwerte (ROADMAP Phase 1b / REGELWERK §7):** Partiedauer 15–25 Züge,
Startspieler-Winrate 48–52%, Tiefpunkt nie 0, Dominanz je Kategorie/Person
< 35%.

## Zwei nicht-triviale Erkenntnisse

**1. Ein rein auf die aktuelle Wertung schauender Bot hortet Karten für
immer.** REGELWERK §6 belohnt bewusst erst *künftige* Züge ("bunter Wert auf
der obersten Karte zählt NICHT"). Ein Bot, der nur bei echter Verbesserung
baut, findet an einem lokalen Optimum nie eine — die Hand wird nie leer, D2
greift nie, die Partie endet nicht. `GreedyBot` baut deshalb auch bei
Gleichstand oder Verschlechterung, wenn nichts Besseres existiert.

**2. Reine Pazifisten würden ihre eigenen Evil-Karten nie wieder los.**
REGELWERK kennt kein Ablegen — eine gezogene eigene Evil-Karte verlässt die
Hand nur durchs Ausspielen. Ein Bot, der Evil kategorisch verweigert, verstopft
irgendwann alle 5 Handplätze mit unspielbaren Evil-Karten und blockiert damit
auch das Nachziehen der übrigen (spielbaren) Kartenarten. `DefensivBot` hat
deshalb einen Notausgang: Evil nur, wenn die Hand komplett damit verstopft
ist. Das ist ein Befund über die Regeln selbst, kein Bot-Artefakt — für
Menschen dürfte das kaum auffallen (niemand spielt buchstäblich für immer
passiv), ist aber relevant für D6 (Evil-Handverstopfung) und die
`erneuerung`-Effektkarte als Ventil.

## Bewertung gegen die Zielwerte

- **Startspieler-Winrate liegt mit Evil bereits nahe am Zielkorridor**
  (52,7% Greedy/Greedy, 50,0% Greedy/Zufall) — knapp über der oberen Grenze,
  aber deutlich näher als die 56% aus der ursprünglichen Baseline.
  **D5 ändert praktisch nichts** (53,7% statt 52,7%, im Rauschen bei n=300).
- **Partiedauer liegt bei Greedy-Bots durchgängig über dem Zielkorridor**
  (31 statt 15–25 Züge). Das ist am ehesten ein Artefakt der eigenen
  Bot-Heuristik (andere Spielweise als die ursprüngliche Baseline), nicht
  notwendigerweise ein Regelproblem.
- **Kategorie-Dominanz ist der auffälligste Befund:** `gebet` trägt in jeder
  Variante 60–78% der Punkte — weit über 35%. Deckt sich mit der
  Kartenverteilung (66 von 106 Karten sind `gebet`) und dürfte sich mit den
  fehlenden Kategorien `tun`/`lehre` entschärfen, sobald die existieren.
- **Tiefpunkt 0 wird mit Evil erreicht, ohne Evil nie** — das Nulldrücken
  hängt an Evil bzw. an aggressiver Spielweise, nicht an EStart allein.
- **AnfuehrerBot zeigt bei 2 Spielern keinen Unterschied zu GreedyBot**
  (Kingmaking-Verhalten braucht 3+ Spieler — am Engine-Test bestätigt,
  in der aktuellen 2-Spieler-CLI aber nicht sichtbar).
- **Slot-Spezialisierung ist mindestens für eine Person (Sohn) eine stark
  dominante Strategie** (71,7% Winrate) — siehe eigener Abschnitt unten.
  Das ist neben der Kategorie-Dominanz der zweite konkrete
  Balancing-Hinweis aus dieser Runde.

## Spieldynamik (Greedy vs. Greedy, Basis, n=300)

Zusätzliche Metriken zur Frage „ist es abwechslungsreich/spannend genug":

| Metrik | Wert |
|---|---|
| Führungswechsel je Partie (Median) | 3,0 |
| Schwankung der Wertung je Zug (Std.-Abw.) | 4,66 |
| Genutzte Kartenvielfalt | 98,1% (104/106 Karten mind. 1× gespielt) |
| Meistgespielte Karten | fast ausschließlich Evil-Karten (E1208: 161×, E1215/E1211/E1219: je 156×, E1201: 153×) |

**Lesart:** Die Kartenvielfalt ist hoch — die Bots nutzen praktisch das ganze
Set, kein Zeichen für "totes Gewicht" im Kartenpool. Die Führung wechselt im
Schnitt 3× pro Partie, also nicht spannungslos-statisch, aber auch kein
Ping-Pong. Auffällig: Die *häufigsten* Einzelkarten sind fast alle Evil —
das folgt daraus, dass **jedes** Deck alle 7 seiner Evil-Karten fast
zwangsläufig einsetzt (GreedyBot spielt Evil immer, wenn legal), während
sich die 28 Ressourcenplätze über 86 mögliche Ressourcenkarten verteilen.
Kein Hinweis auf eine einzelne "Pflichtkarte" unter den Ressourcenkarten.

## Slot-Spezialisierung: lohnt sich ein Deck auf eine Person zuschneiden?

Nutzer-Hypothese: gezieltes Deckbuilding auf eine Person (z. B. Vater/V1+V2)
könnte einen Vorteil verschaffen — zumal Vater in der normalen Simulation
bereits ~45% der Punkte trägt. Getestet mit `bin/spezialisierung.dart`:
Ressourcenkarten werden nach Rohwert für die Zielperson sortiert und
priorisiert ins Deck genommen (statt zufällig), Evil bleibt unverändert;
GreedyBot auf beiden Seiten, 300 Partien je Person gegen ein normales
Zufallsdeck.

| Spezialisiert auf | Winrate Spezialist | Ø Heiligkeit Spezialist | Ø Heiligkeit Normal |
|---|---:|---:|---:|
| Vater | **36,0%** | 78,2 | 92,4 |
| Sohn | **71,7%** | 95,9 | 75,4 |
| Heiliger Geist | 51,3% | 86,1 | 85,7 |

**Überraschung: Die Hypothese trifft zu, aber nicht so wie erwartet.**
Sohn-Spezialisierung ist eine deutlich dominante Strategie (71,7% statt
50%), Vater-Spezialisierung dagegen **schadet** (36,0% — schlechter als
Zufall!), obwohl Vater in normalem Spiel am meisten zur Wertung beiträgt.

Wahrscheinliche Erklärung (nicht abschließend bewiesen): Die Sortierung
optimiert nur auf *rohen Slot-Wert*, nicht auf *Löcher*. Da bunte Werte auf
der obersten Karte nie zählen (REGELWERK §6), ist eine Karte nur dann etwas
wert, wenn später eine andere Karte mit Loch an derselben Position draufkommt.
Karten mit hohem Vater-Rohwert sind im Bestand tendenziell genau die Karten
*ohne* Loch an V1/V2 — die Sortierung wählt also bevorzugt Karten, deren
eigener Vater-Wert kaum je sichtbar wird, und verdrängt dabei die
Loch-Karten, die diesen Wert überhaupt freilegen könnten. Ob das bei Sohn
zufällig andersrum ist oder ob da ein echter Unterschied im Kartendesign
steckt, wäre mit `tools/simulator/bin/spezialisierung.dart` (Kartenliste je
Deck ausgeben) weiter nachzuvollziehen.

**Einordnung:** Das ist ein echter, reproduzierbarer Befund mit der
aktuellen Bot-Heuristik und den aktuellen 106 Karten — aber die
Deckbau-Heuristik hier ist bewusst naiv (nur Rohwert, keine Loch-Rücksicht).
Eine raffiniertere Spezialisierung (die auch Löcher einpreist) könnte andere
Ergebnisse liefern. Für die Balance-Diskussion heißt das trotzdem: **Es gibt
mindestens eine Person (Sohn), bei der simples "stärkste Karten zuerst"
schon einen großen Vorteil bringt** — das ist ein Datenpunkt, dem die
Kartenwerte-Feinjustierung (ROADMAP Phase 1b Schritt 4) Beachtung schenken
sollte.

## Bekannte Grenzen

- **Keine Effektkarten im Bestand** (alle 106 Karten: `effekt: null`) — die
  Effekt-Resolver der Engine sind getestet, aber diese Simulation sagt
  nichts über `umkehrung`, `schutz`, `suche` usw. aus, weil keine Karte sie
  trägt.
- **Keine `sofort`-Karten im Bestand** — die Reaktion-Phase kommt in dieser
  Simulation nie zum Einsatz.
- Bot-Heuristiken sind Näherungen, keine optimalen Spieler — absolute Zahlen
  (bes. Partiedauer) sind zwischen unterschiedlichen Bot-Designs nicht
  direkt vergleichbar.
- `seltenheit`/`anzahlImDeckMax` im importierten Kartenset sind selbst
  Platzhalter (siehe Commit „sheet_import-Pipeline") — die Deckzusammen-
  setzung dieser Simulation trägt diese Unschärfe mit.

## Reproduktion

```bash
cd tools/simulator
dart run bin/simulator.dart --spiele 300 --seed 1 --bot1 greedy --bot2 greedy
dart run bin/simulator.dart --spiele 300 --seed 1 --bot1 greedy --bot2 greedy --ohne-evil
dart run bin/simulator.dart --spiele 300 --seed 1 --bot1 greedy --bot2 greedy --startspieler-vier
# --bot1/--bot2: greedy | zufall | defensiv | anfuehrer

dart run bin/spezialisierung.dart --spiele 300 --seed 1
```
