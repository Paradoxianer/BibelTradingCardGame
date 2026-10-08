# Kartenkandidaten — Erweiterung tun/lehre/glauben/gottesdienst

> Rechercheergebnis (Websuche) für die redaktionelle Endauswahl, siehe
> ROADMAP.md Phase 1b und die Planungsrunde vom 2026-08-12. **Keine
> theologische Setzung** — dies ist eine Kandidatenliste, keine fertige
> Kartendefinition. Bibeltexte (`bible_text`) sind hier bewusst nicht
> ausformuliert (Übersetzungswahl ist Redaktionsarbeit, siehe CLAUDE.md).
>
> Cluster (`RV`/`RS`/`RH`) bestimmen nur ID-Präfix und Thema, **nicht** die
> mechanische `Kategorie` — die trägt jede Karte gemäß ihres tatsächlichen
> Inhalts (`tun`/`lehre`/`glauben`/`gottesdienst`), unabhängig vom Cluster.
> Vorschläge unten sind daher pro Zeile mit einer Kategorie-Empfehlung
> versehen, die der Nutzer ändern kann.

## Ziel

Aktuell (`data/sets/base.json`): `gebet` 66, `glauben` 13, `gottesdienst` 7,
`tun`/`lehre` 0. Grobe Zielrechnung: Pool von 86 auf ~150–160 Karten, um
`gebet`s Wertungsanteil von 63–78 % auf < 35 % zu drücken (Details im
Planungsrunden-Kontext). Personen-Bilanz zusätzlich beachten: Sohn ist mit
25,2 % der Wertsumme am stärksten unterrepräsentiert (Vater 42,9 %, Geist
31,9 %) — `RS`- und `RH`-Cluster sollten das durch überdurchschnittliche
Sohn-/Geist-Slotwerte ausgleichen, unabhängig vom Cluster-Thema.

## Cluster RV — Vater-Thema (Tun/Lehre: Gesetz, Auftrag, Handeln)

| Vorschlag-ID | Bibelstelle | Thema | Kategorie-Empfehlung |
|---|---|---|---|
| RV2001 | Matthäus 22,37–40 | Doppelgebot der Liebe | lehre |
| RV2002 | Matthäus 25,35–40 | "Was ihr dem Geringsten getan habt" | tun |
| RV2003 | Römer 13,9–10 | Nächstenliebe erfüllt das Gesetz | tun |
| RV2004 | Jakobus 2,14–17 | Glaube ohne Werke ist tot | tun |
| RV2005 | Jakobus 1,22 | Tut das Wort, nicht nur hören | tun |
| RV2006 | Micha 6,8 | Recht tun, Güte lieben, demütig wandeln | tun |
| RV2007 | Matthäus 7,24–27 | Haus auf Fels — Worte tun | tun |
| RV2008 | 5. Mose 6,4–9 | Schema Israel — Lehre weitergeben | lehre |
| RV2009 | Sprüche 22,6 | Erziehung/Lehre der Kinder | lehre |
| RV2010 | Matthäus 28,19–20 | Missionsbefehl: lehren zu halten | lehre |
| RV2011 | Titus 2,1 | Gesunde Lehre | lehre |
| RV2012 | 2. Timotheus 3,16–17 | Schrift als Lehrgrundlage | lehre |

## Cluster RS — Sohn-Thema (Gnade, Vergebung)

| Vorschlag-ID | Bibelstelle | Thema | Kategorie-Empfehlung |
|---|---|---|---|
| RS2001 | Lukas 23,34 | Jesus bittet um Vergebung für seine Feinde | glauben |
| RS2002 | Matthäus 6,12 | Vergib uns, wie wir vergeben (Vaterunser) | gebet |
| RS2003 | Matthäus 6,14–15 | Vergebung als Bedingung | lehre |
| RS2004 | Matthäus 18,21–22 | "Siebzig mal siebenmal" vergeben | tun |
| RS2005 | Psalm 86,5 | Gott ist gut und vergibt gern | glauben |
| RS2006 | Epheser 1,7 | Erlösung/Vergebung durch sein Blut | lehre |
| RS2007 | Epheser 2,8–9 | Gnade, nicht aus Werken | lehre |
| RS2008 | Kolosser 3,13 | Vergebt einander, wie Christus vergab | tun |
| RS2009 | Römer 5,8 | Gottes Liebe erwiesen, als wir Sünder waren | glauben |
| RS2010 | 1. Petrus 2,24 | Stellvertretung am Kreuz | lehre |
| RS2011 | Lukas 15,20 | Der verlorene Sohn — Vater läuft ihm entgegen | glauben |
| RS2012 | 1. Johannes 1,9 | Bekenntnis und Vergebung | glauben |

*Hinweis:* Johannes 3,14 (RG1113) und Markus 16,17 (RG1109) sind bereits im
Bestand — Johannes 3,16 als naheliegende Ergänzung ggf. bewusst wählen, um
Doppelung im selben Kapitel zu vermeiden oder gerade als Paar zu nutzen.

## Cluster RH — Geist-Thema (Emotion, Wunder, Gefühle)

| Vorschlag-ID | Bibelstelle | Thema | Kategorie-Empfehlung |
|---|---|---|---|
| RH2001 | Galater 5,22–23 | Frucht des Geistes | lehre |
| RH2002 | Apostelgeschichte 2,1–4 | Pfingsten — Geist wird ausgegossen | glauben |
| RH2003 | 1. Korinther 12,4–11 | Gaben des Geistes (Wunder, Weisheit, Prophetie) | lehre |
| RH2004 | Joel 3,1–2 | Prophetie: Geist über alle Menschen | lehre |
| RH2005 | Hesekiel 36,26–27 | Neues Herz, neuer Geist | glauben |
| RH2006 | Johannes 14,26 | Der Tröster/Beistand | glauben |
| RH2007 | Römer 8,26 | Der Geist hilft in unserer Schwachheit | gebet |
| RH2008 | Römer 8,15–16 | Geist der Kindschaft — Gewissheit/Gefühl der Nähe | glauben |
| RH2009 | Psalm 42,2–3 | Sehnsucht der Seele nach Gott | gebet |
| RH2010 | Johannes 11,35 | "Jesus weinte" — Emotion und Wunder (Auferweckung) | tun |

*Hinweis:* Psalm 150 (GD1206) und Markus 16,17 (RG1109) sind bereits im
Bestand — hier nicht doppelt vorgeschlagen.

## Sources (Recherche-Grundlage)

- [Doppelgebot der Liebe – EKD](https://www.ekd.de/doppelgebot-der-liebe-10800.htm)
- [29 Bibelverse über Nächstenliebe](https://bible.knowing-jesus.com/Deutsch/topics/N%C3%A4chstenliebe)
- [Faith and Works – The Gospel Coalition](https://www.thegospelcoalition.org/essay/faith-and-works/)
- [Key Doctrines and Verses Every Elder Needs to Know (PDF)](https://www.biblicaleldership.com/files/pdfs/key_doctrinal_verses.pdf)
- [8 Foundational Doctrines of the Christian Faith](https://churchgrowth.org/8-foundational-doctrines-of-the-christian-faith/)
- [12 Bibelverse zur Vergebung – evangelisch.de](https://www.evangelisch.de/galerien/175610/22-03-2022/12-bibelverse-zur-vergebung)
- [Bibelverse über Vergebung – bibeltv.de](https://www.bibeltv.de/gott-erklaert/bibelverse/ueber-vergebung/)
- [Bibelstellen über den Heiligen Geist – bibeltv.de](https://www.bibeltv.de/gott-erklaert/heiliger-geist-bibelstellen/)
- [Bibelverse zu Pfingsten – Bibel Liga](https://www.bibelliga.org/10-bibelverse-zu-pfingsten/)

## Weiteres Vorgehen

1. Nutzer wählt aus diesen (oder eigenen) Kandidaten aus, legt Namen,
   `bible_text` (Übersetzung eigener Wahl) und finale Kategorie fest.
2. Claude trägt ausgewählte Karten nach der Slot-Design-Richtlinie
   (Personen-Bilanz, siehe Planung) in `data/sets/base.json` ein, in Batches.
3. Nach jedem Batch: Simulator-Check (`kategorieAnteile`, `personAnteile`)
   gegen Zielwert < 35 %.
