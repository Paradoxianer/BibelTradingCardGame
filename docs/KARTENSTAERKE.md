# Kartenstärke — Marginal-Contribution-Analyse

> Erzeugt mit `tools/simulator/bin/kartenstaerke.dart` gegen `data/sets/base.json` (106 Karten). 30 gepaarte Stichproben je Karte, GreedyBot beidseits, Startseed 1.

**Methodik:** Für jede Ressourcenkarte wird ein zufälliges Deck ohne sie gebaut ("ohne"), plus eine Variante mit ihr auf einem zufälligen Ressourcenslot statt einer anderen Karte ("mit") — sonst identisch. Beide Varianten spielen mit demselben Folge-Seed gegen dasselbe feste Referenzdeck (gepaarter Vergleich, reduziert Rauschen). `deltaHeiligkeit`/`deltaWinrate` = Schnitt(mit) − Schnitt(ohne) über alle Stichproben.

**Wichtige Einschränkung — nicht wirklich "wasserdicht":** Das ist eine Näherung mit einer bestimmten Bot-Heuristik (GreedyBot), einem festen Referenzdeck und begrenzter Stichprobenzahl. Kartenstärke in diesem Spiel ist zudem strukturell kontextabhängig (Loch-Ketten, siehe SIMULATION_PHASE1B.md „Slot-Spezialisierung") — eine Karte ist nur so viel wert, wie das Deck sie auch sichtbar macht. Für absolute Präzision bräuchte es eine erschöpfende Analyse aller Deck-Kombinationen, was praktisch nicht machbar ist. Als *relativer* Vergleich zwischen Karten ist es trotzdem aussagekräftiger als reines Rohwert-Aufsummieren.

**ROADMAP-Leitplanke beachten (KARTEN_SPEZIFIKATION §7):** "Seltenheit bedeutet Vielfalt, nicht Spielstärke — kein Pay-to-win." Diese Zahlen sind also kein Vorschlag, starke Karten selten zu machen (das wäre Pay-to-win) — eher ein Werkzeug, um zu prüfen, dass keine Karte zu dominant ist, unabhängig von ihrer Seltenheit.

`vermutlich signifikant` ist eine grobe Heuristik (Mittelwert > 2 Standardfehler von 0), kein echter statistischer Test — bei kleinen Stichproben sind auch als "signifikant" markierte Werte mit Vorsicht zu lesen.

## Ranking (stärkste zuerst)

| Karte | Kategorie | Δ Heiligkeit | Streuung (σ) | Δ Winrate | vermutlich signifikant |
|---|---|---:|---:|---:|---:|
| BASE-RG0143 (Gebet um Heilung) | gebet | +5.13 | 10.19 | +10.0% | ja |
| BASE-RG1113 (Glauben bringt Ewiges Leben) | glauben | +3.87 | 12.31 | +6.7% | nein |
| BASE-RG0153 (Gebet weil Du gesegnet bist) | gebet | +2.73 | 8.17 | +0.0% | nein |
| BASE-RG0119 (Gesetz und Gebet) | gebet | +2.33 | 6.68 | +10.0% | nein |
| BASE-RG0114 (Reue) | gebet | +2.10 | 7.38 | +0.0% | nein |
| BASE-RG1108 (Habt Glauben) | glauben | +2.00 | 5.72 | +0.0% | nein |
| BASE-RG0164 (Gebet eines Gerechten) | gebet | +2.00 | 8.33 | +3.3% | nein |
| BASE-RG0140 (Gebet um Entscheidung) | gebet | +1.93 | 6.29 | +0.0% | nein |
| BASE-RG0166 (Bete Gott an) | gebet | +1.90 | 9.66 | +0.0% | nein |
| BASE-RG0108 (Zu Gott schreien) | gebet | +1.63 | 9.03 | +3.3% | nein |
| BASE-RG0150 (Eigenes Urteil Gebet mit Kopfbedeckung) | gebet | +1.57 | 9.68 | +0.0% | nein |
| BASE-RG0117 (Weinendes Gebet) | gebet | +1.53 | 7.33 | +10.0% | nein |
| BASE-RG0155 (Der Geist betet zum Vater) | gebet | +1.53 | 5.55 | -3.3% | nein |
| BASE-RG1109 (Dem Glauben folgen Zeichen) | glauben | +1.50 | 6.45 | +0.0% | nein |
| BASE-RG0159 (Gebet für die Regierung) | gebet | +1.50 | 5.61 | +3.3% | nein |
| BASE-RG0127 (Gebet gibt Kraft) | gebet | +1.30 | 5.71 | +0.0% | nein |
| BASE-RG0147 (Gebt und Vison) | gebet | +1.23 | 9.42 | +0.0% | nein |
| BASE-GD1201 (Gott dienen) | gottesdienst | +1.20 | 7.74 | +13.3% | nein |
| BASE-RG0135 (Keine Versuchung) | gebet | +1.17 | 6.94 | +6.7% | nein |
| BASE-RG1104 (Dem Glauben entsprechend) | glauben | +1.10 | 3.53 | +0.0% | nein |
| BASE-RG0104 (Gebet im Verborgenen) | gebet | +0.97 | 8.86 | -6.7% | nein |
| BASE-RG0141 (Gebet der Geistlichen Leiter) | gebet | +0.97 | 8.68 | +0.0% | nein |
| BASE-RG0131 (Gebet und vergeben) | gebet | +0.93 | 4.55 | +3.3% | nein |
| BASE-RG0109 (Gott die Ehre geben) | gebet | +0.87 | 7.93 | +0.0% | nein |
| BASE-RG0133 (Immer beten) | gebet | +0.87 | 4.12 | +0.0% | nein |
| BASE-RG0154 (Gebet um zurechtrücken :)) | gebet | +0.87 | 6.60 | -3.3% | nein |
| BASE-RG0139 (Anhaltendes Gebet) | gebet | +0.83 | 5.58 | +0.0% | nein |
| BASE-RG0144 (Vision beim Gebet) | gebet | +0.83 | 4.36 | +0.0% | nein |
| BASE-GD1206 (Gott loben) | gottesdienst | +0.77 | 6.47 | +0.0% | nein |
| BASE-RG0149 (Dein Gebet für andere) | gebet | +0.73 | 5.65 | +0.0% | nein |
| BASE-RG0162 (Kraft durch Gebet) | gebet | +0.63 | 6.86 | +0.0% | nein |
| BASE-GD1202 (Waisen besuchen) | gottesdienst | +0.63 | 5.06 | +3.3% | nein |
| BASE-GD1204 (Unbeflekt bewahren) | gottesdienst | +0.47 | 5.24 | +3.3% | nein |
| BASE-RG0122 (Befreiung von Ängsten) | gebet | +0.43 | 5.25 | +0.0% | nein |
| BASE-RG0134 (Beten ohne Nachlass) | gebet | +0.40 | 3.47 | +0.0% | nein |
| BASE-RG1105 (Glaube wie ein Senfkorn) | glauben | +0.37 | 4.13 | +0.0% | nein |
| BASE-RG0126 (Gebet voll Freude) | gebet | +0.33 | 5.96 | +6.7% | nein |
| BASE-RG0105 (Gott allein) | gebet | +0.33 | 5.59 | -6.7% | nein |
| BASE-RG0156 (Gebet um Verstehen) | gebet | +0.20 | 6.38 | -3.3% | nein |
| BASE-RG1110 (Gebet: Glauben stärken) | glauben | +0.17 | 8.00 | +6.7% | nein |
| BASE-RG0111 (Herr über alles) | gebet | +0.17 | 2.34 | +0.0% | nein |
| BASE-RG0118 (Händ erhoben) | gebet | +0.17 | 7.01 | +6.7% | nein |
| BASE-RG0120 (Gebet in Not) | gebet | +0.17 | 5.23 | +3.3% | nein |
| BASE-RG0151 (Sprachengebet) | gebet | +0.10 | 3.40 | +6.7% | nein |
| BASE-RG0112 (Gebet nach Sünde) | gebet | +0.10 | 3.84 | -3.3% | nein |
| BASE-RG0116 (Gemeinsam fasten und beten) | gebet | +0.07 | 2.57 | +0.0% | nein |
| BASE-RG1107 (Kleinglaube) | glauben | +0.00 | 5.01 | -3.3% | nein |
| BASE-RG0138 (Jesus betet für Einheit) | gebet | +0.00 | 3.67 | +0.0% | nein |
| BASE-RG0145 (Aussendung mit Gebet) | gebet | -0.03 | 10.76 | +3.3% | nein |
| BASE-RG0163 (Gebet um Heilung) | gebet | -0.03 | 5.57 | +3.3% | nein |
| BASE-RG1101 (Gerecht durch Glauben) | glauben | -0.07 | 7.53 | +0.0% | nein |
| BASE-RG1111 (Glauben wie ein Senfkorn) | glauben | -0.23 | 7.25 | +6.7% | nein |
| BASE-RG0107 (Gebet nicht auslassen) | gebet | -0.23 | 4.69 | -3.3% | nein |
| BASE-RG0124 (Unaufhörliches Gebet) | gebet | -0.33 | 5.60 | +3.3% | nein |
| BASE-RG0158 (Gebet in der Gemeinde) | gebet | -0.37 | 5.55 | +0.0% | nein |
| BASE-RG0152 (Gebet in Sprachen und mit Verstand) | gebet | -0.37 | 11.91 | -3.3% | nein |
| BASE-RG1102 (Glauben durch sehen) | glauben | -0.40 | 5.54 | -3.3% | nein |
| BASE-RG0137 (Jesus betet für Dich) | gebet | -0.43 | 6.47 | -3.3% | nein |
| BASE-RG0113 (Not vor Gott bringen) | gebet | -0.43 | 3.76 | -3.3% | nein |
| BASE-RG1112 (Macht Gottes Kinder) | glauben | -0.47 | 8.35 | -3.3% | nein |
| BASE-RG0103 (Ungeheuchelts Gebet) | gebet | -0.57 | 10.53 | +0.0% | nein |
| BASE-RG0115 (Demütiges Gebet) | gebet | -0.63 | 7.60 | +0.0% | nein |
| BASE-RG0160 (Gebet der Witwen) | gebet | -0.63 | 5.82 | +3.3% | nein |
| BASE-RG0146 (Gebet als Zeugnis) | gebet | -0.67 | 7.80 | +0.0% | nein |
| BASE-RG0129 (Gott will erhören) | gebet | -0.70 | 6.22 | -10.0% | nein |
| BASE-RG0165 (Gebet in Kraft des Heiligen Geistes) | gebet | -0.73 | 8.05 | -6.7% | nein |
| BASE-RG0130 (Wache) | gebet | -0.93 | 5.69 | -3.3% | nein |
| BASE-RG0161 (Gebet bei Tag und Nacht) | gebet | -1.00 | 5.85 | -3.3% | nein |
| BASE-RG0148 (Der Geist betet für uns) | gebet | -1.13 | 5.59 | -6.7% | nein |
| BASE-RG0123 (Ausdauerndes Gebet) | gebet | -1.20 | 10.75 | -3.3% | nein |
| BASE-RG0102 (Gott erhört gebet) | gebet | -1.47 | 9.32 | -3.3% | nein |
| BASE-RG0142 (Gebet um Heiligen Geist) | gebet | -1.50 | 4.18 | +0.0% | nein |
| BASE-RG0125 (Ehre die Gott zusteht) | gebet | -1.53 | 6.04 | -10.0% | nein |
| BASE-RG0101 (Gebetsunterstützung) | gebet | -1.57 | 10.20 | +0.0% | nein |
| BASE-RG1106 (Glauben versetzt Berge) | glauben | -1.57 | 7.06 | -10.0% | nein |
| BASE-RG0157 (Gebet - Ausdauer, Dankbarkeit, Wachsamkeit) | gebet | -1.60 | 3.84 | -3.3% | ja |
| BASE-RG0128 (Wohlüberlegtes Gebet) | gebet | -1.63 | 10.34 | -6.7% | nein |
| BASE-GD1203 (Witwen besuchen) | gottesdienst | -1.63 | 7.84 | -3.3% | nein |
| BASE-GD1205 (Erneuertes Denken) | gottesdienst | -1.67 | 10.01 | -13.3% | nein |
| BASE-GD0102 (Erfüllung prophetischer Rede) | gottesdienst | -2.20 | 5.52 | -3.3% | ja |
| BASE-RG0132 (Gott mit Gebet und Fasten dienen) | gebet | -2.47 | 5.87 | -3.3% | ja |
| BASE-RG0110 (Gott antwortet) | gebet | -2.53 | 5.98 | -3.3% | ja |
| BASE-RG0136 (Gebet - Große Freude) | gebet | -2.97 | 9.17 | -3.3% | nein |
| BASE-RG0106 (Götzen nicht anbeten) | gebet | -3.27 | 12.44 | -6.7% | nein |
| BASE-RG1103 (Durch Glaube Vergebung) | glauben | -3.47 | 10.30 | -13.3% | nein |
| BASE-RG0121 (Gott in Heiligkeit) | gebet | -4.23 | 9.78 | -10.0% | ja |
