# ÜBERGABE.md — Stand der Design-Diskussion (2026-07-26)

> Zweck: Kontext-Transfer aus der Planungs-Session (Claude App) an Claude Code.
> Nach Übernahme der Inhalte in die docs/ kann diese Datei gelöscht werden.
> Sie ergänzt CLAUDE.md und docs/ — bei Widerspruch gilt docs/REGELWERK.md.

## Aktueller Auftrag (Startpunkt für Claude Code)

**Phase 0 aus docs/ROADMAP.md ausführen:** Qt-Prototyp nach `legacy/`
archivieren (Tag `qt-prototype`), Flutter/Dart-Struktur anlegen, diese Doku
einchecken, README erneuern. Danach Phase 1 Schritt 1 (Datenmodell + Parser)
— aber erst nach Rücksprache beginnen.

## Bereits entschieden (Kurzfassung)

- Zielprodukt Phase 1: **Flutter-App** (PWA + Android), Hotseat zuerst.
- Engine als **reines Dart-Package**, deterministisch, Command/Event-basiert.
- Karten-Geometrie: **1 Symbolzeile oben, 6 Slots** (2×Vater, 2×Sohn, 2×Hl. Geist).
- Slot-Codes: `2|1|0` bunt (zählt nur durchs Loch), `-1` schwarz (zählt immer
  wenn sichtbar), `X` Loch. Bunte Werte der obersten Karte zählen nicht.
- ID-Schema auf Basis `R1301`, erweitert um Set + Exemplar-Serie (Druck).
- Besitz-System (Phase 2): QR + TAN gegen zentralen Server, **keine Blockchain**.
- Kartenpflege im Google Sheet, Import-Pipeline nach `data/sets/*.json`.
- Alter Qt-Code: nur Referenz. Sein Domänenmodell (positionierte Stärken,
  Löcher als Fenster, verkettete Stapel, closeToGod) ist konzeptionelle Vorlage
  für die Dart-Engine.

## Offen (nicht eigenmächtig entscheiden!)

- **D1–D10 sind alle entschieden** (docs/REGELWERK.md §7, v0.9). Nicht neu
  aufrollen. Offen sind nur noch Zahlenwerte, die die Simulation in Phase 1b
  klärt — insbesondere der gemessene Startspielervorteil von 56 %.
- **Effekt-System:** definiert in **docs/EFFEKTE.md** (v0.3, freigegeben):
  8 typisierte Effekte (`umkehrung` mit Slot-Beschränkung, `schutz`,
  `gebietserweiterung`, `zuwendung`, `globale_aura`, `suche`, `erneuerung`,
  `umordnung` als einzige D3-Ausnahme), Aktivierungsregel
  „solange oberste Karte des Stapels", keine Effekt-Ketten. Slot-Werte der
  Beispielkarten sind Platzhalter → Simulation (Phase 1b).
- **Kartendaten liegen vor:** `Bibelsammelkartenspiel_final.json`, 106 Karten
  in 4 Tabs (R_Gebet 66, R_Glauben 13, R_Gottesdienst 7, EvilDeck 19 + EStart).
  Format und Datenfehler sind in KARTEN_SPEZIFIKATION v0.2 dokumentiert.
  Fehlend: Kategorien `tun` und `lehre`, echtes Artwork (alles Placeholder).
- ID-Schema-Unschärfen (Präfix `RG` für zwei Kategorien u. a.):
  KARTEN_SPEZIFIKATION §4 — vor einer Änderung Rücksprache
- **Shop/Booster** ist Thema für Phase 3; Leitplanken stehen in ROADMAP

## Bekannte Design-Risiken (für spätere Simulation vormerken)

1. Schneeball-Effekt durch wiederkehrende Board-Wertung (REGELWERK §6).
2. Handverstopfung durch eigene Evil-Karten, besonders bei 2 Spielern (D6).
3. Startspieler-Vorteil (D5, Grundfix steht: kein Evil in Runde 1).
