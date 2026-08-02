# Roadmap — BibelTradingCardGame

## Phase 0 — Repo-Umbau (Qt archivieren, Flutter aufsetzen)

Das bestehende Repository bleibt erhalten (Historie, Issues, Name). Der
Qt-Prototyp wird archiviert, nicht gelöscht:

```bash
git tag qt-prototype                      # Stand für immer auffindbar
mkdir legacy
git mv *.cpp *.h *.ui *.pro legacy/
git mv ArtWork legacy/ArtWork
git commit -m "Qt-Prototyp nach legacy/ archiviert (Tag: qt-prototype)"

# Struktur anlegen
mkdir -p docs data/sets assets engine tools
# docs/*.md + CLAUDE.md einchecken
flutter create app --platforms web,android
cd engine && dart create -t package .    # bzw. pubspec manuell, Name: btcg_engine
```

README.md neu schreiben (Projektziel, Verweis auf docs/, Hinweis auf legacy/).

**Definition of Done:** Repo gebaut (`flutter build web` in app/ läuft),
Doku eingecheckt, Qt unter legacy/ unangetastet.

## Phase 1 — Engine + Hotseat-Prototyp

1. **Datenmodell + Parser** für `data/sets/*.json` (KARTEN_SPEZIFIKATION §5).
2. **Engine-Kern:** GameState, Commands, Phasenablauf, Wertungsalgorithmus,
   Siegprüfung — testgetrieben gegen REGELWERK.md. Offene D-Entscheidungen
   werden als Konfigurationsflags implementiert, wo billig (mind. D1, D5-Option),
   damit die Simulation Varianten vergleichen kann.
3. **Kartendaten importieren:** `Bibelsammelkartenspiel_final.json`
   (106 Karten) bereinigen und ins Zielformat überführen
   (KARTEN_SPEZIFIKATION §5–6). Datenfehler vorher beheben: fehlender `name`
   in R_Glauben, zwei `#NUM!`-Werte in R_Gottesdienst. `strongness`/`rare`
   nicht übernehmen. Fehlende Kategorien `tun` und `lehre` redaktionell
   nachziehen.
4. **UI-Prototyp Loch-Mechanik** (wichtigster UI-Baustein, früh bauen):
   Stapel-Widget mit Durchschein-Darstellung und Lege-Animation.
5. **Hotseat-Spiel:** kompletter Spielfluss für 2 Spieler an einem Gerät,
   Wertungs-Aufschlüsselung sichtbar.

**Definition of Done:** Eine vollständige 2-Spieler-Partie auf dem Handy/Browser
spielbar; alle Regelwerk-Tests grün.

## Phase 1b — Simulation & Feinjustierung

1. `tools/simulator/` (ARCHITEKTUR §4) + einfacher Greedy-Bot.
2. Massensimulation; Metriken gegen Zielwerte (Baseline bereits gemessen,
   siehe REGELWERK §7):
   - Partiedauer 15–25 Züge — Baseline 16 ✅
   - Startspieler-Winrate 48–52 % — Baseline **56 % ⚠️**, D5-Zusatzoption
     („Startspieler zieht nur 4 Karten") als Erstes gegentesten
   - keine Kategorie/Person > ~35 % des Gesamtpunktebeitrags
   - prüfen, ob `erneuerung` die Evil-Handverstopfung wirklich löst (D6)
   - `umordnung` gesondert bewerten (schwer abschätzbarer Effekt)
3. Regelvarianten (D1, D5, D6) im A/B-Vergleich → **Entscheidungen fixieren,
   REGELWERK auf v1.0 heben.**
4. Kartenwerte im Spreadsheet nachjustieren, `sheet_import`-Pipeline bauen,
   volles Basis-Set importieren.
5. Playtests mit echten Menschen (Gemeinde/Jugendgruppe) — Simulation findet
   Ungleichgewichte, aber nicht Spielspaß.

## Phase 2 — Online & Besitz

- Server mit autoritativer Engine, Matchmaking „Gäste spielen sofort"
  (automatische Gast-ID, Namen vergeben), Konten via Google OAuth.
- Kartentausch nur für registrierte Konten.
- Physische Karten claimen: QR (Exemplar-ID) + TAN, Besitz-Datenbank
  (bewusst zentral, keine Blockchain — s. KARTEN_SPEZIFIKATION §4).
- Fortschritt/Level (Erfahrungspunkte-Idee aus dem Spreadsheet) — Design dann.

## Phase 3 — Shop, Booster und physischer Druck

### Shop-Leitplanken (verbindlich, vor der Umsetzung festgelegt)

1. **Kein Pay-to-win.** Seltenheit bedeutet Vielfalt und Sammelreiz, nicht
   Spielstärke. Turnier-/Standarddecks müssen aus häufigen Karten baubar sein.
2. **Keine digitalen Zufallskäufe für Geld.** Lootbox-Mechaniken sind in
   mehreren Ländern reguliert (u. a. Belgien, Niederlande) und für ein
   christliches Spiel mit jungem Publikum auch inhaltlich die falsche Wahl.
   Erlaubt sind stattdessen:
   - Pakete mit **sichtbarem Inhalt** (man weiß vor dem Kauf, was drin ist),
   - Booster, die durch **Spielen verdient** werden (kein Echtgeld),
   - **physische** Booster mit Claim-Code, die digitale Karten freischalten.
3. **Karten sind nutzbar, nicht spekulativ.** Kein selbst betriebener
   Handelsplatz mit Echtgeldpreisen; Tausch zwischen Konten dagegen ja.
4. Voraussetzung im Datenmodell: Feld `seltenheit`
   (KARTEN_SPEZIFIKATION §7) — muss vor dem ersten Set-Release gepflegt sein.

### Druck

- Druckvorlagen-Generator aus `data/sets/` + Artwork (Slots rastergenau,
  Stanz-Toleranzen), Kleinauflage als Proof of Concept.
- Echtes Artwork ersetzt `Placeholder.png` (aktuell bei allen 106 Karten).
- QR/TAN-Aufdruck je Exemplar, Abgleich mit Besitz-System aus Phase 2.

## Bewusst NICHT im Scope (bis mindestens Phase 2)

- Kein Blockchain/NFT
- Keine KI-Gegner über simple Bots hinaus
- Kein iOS-Build (erst wenn PWA/Android stehen)
- Keine Effekt-Engine „auf Vorrat" — Effekte erst, wenn konkrete Karten sie brauchen
