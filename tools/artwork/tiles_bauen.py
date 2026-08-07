"""Erzeugt die Slot-Tiles der App aus dem Original-Artwork.

Quelle ist `legacy/ArtWork/` (Archiv, bleibt unverändert), Ziel
`app/assets/artwork/`. Alles hier ist ableitbar — die Datei ist die einzige
Stelle, an der die Tiles entstehen, damit sie sich jederzeit identisch
neu bauen lassen.

Drei Schritte:

1. **Größere Dreiecke.** Die Dreiecke ober- und unterhalb des Kreises
   bedeuten „dieser Wert zählt"; im Bestand tragen sie `-1` (zählt immer)
   und `x` (das Loch). Sie werden vergrößert, damit sie auch auf kleinen
   Karten erkennbar sind.
2. **Weiße Kontur.** Die Symbole sind schwarz; auf dunklem Spielbrett oder
   dunklem Artwork verschwinden sie sonst. Die Kontur wird aus dem
   Alphakanal erzeugt und folgt damit jeder Form, auch den Dreiecken.

Aufruf aus dem Repo-Wurzelverzeichnis:  python3 tools/artwork/tiles_bauen.py
"""

import pathlib

from PIL import Image, ImageDraw, ImageFilter

SRC = pathlib.Path("legacy/ArtWork")
DST = pathlib.Path("app/assets/artwork")

KACHEL = 378
SS = 4  # Supersampling für saubere Kanten
MITTE_X = 189.0
RING_OBEN, RING_UNTEN = 46.0, 332.0  # Kreiskante, aus den Wert-Tiles gemessen
DREIECK_BREITE = 110.0
KONTUR = 26  # Stärke der weißen Kontur
SCHWARZ = (0, 0, 0, 255)

# Im Bestand sind mehrere Dateien byte-identisch: ein Loch-Tile und ein
# Schwäche-Tile, jeweils personenunabhängig.
LOCH_ZIELE = ["Empty.png", "V_x.png", "S_x.png", "HG_x.png"]
SCHWAECHE_ZIELE = ["Evil.png", "V_-1.png", "S_-1.png", "HG_-1.png"]
WERT_ZIELE = [f"{p}_{w}.png" for p in ("V", "S", "HG") for w in (0, 1, 2)]


def dreiecke() -> Image.Image:
    """Transparente Ebene mit beiden Dreiecken, Spitze jeweils zur Ringkante."""
    s = KACHEL * SS
    ebene = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    stift = ImageDraw.Draw(ebene)
    cx, hb = MITTE_X * SS, DREIECK_BREITE * SS / 2
    stift.polygon([(cx - hb, 0), (cx + hb, 0), (cx, RING_OBEN * SS)], fill=SCHWARZ)
    stift.polygon([(cx - hb, s), (cx + hb, s), (cx, RING_UNTEN * SS)], fill=SCHWARZ)
    return ebene.resize((KACHEL, KACHEL), Image.LANCZOS)


def mit_neuen_dreiecken(quelle: str, marker: Image.Image) -> Image.Image:
    """Kreisgrafik übernehmen, die kleinen Original-Dreiecke ersetzen.

    Die Dreiecke liegen außerhalb des Kreises (y < 46 bzw. y > 332), lassen
    sich also wegschneiden, ohne die Kreisgrafik zu berühren.
    """
    bild = Image.open(SRC / quelle).convert("RGBA")
    px = bild.load()
    for y in list(range(0, int(RING_OBEN))) + list(range(int(RING_UNTEN) + 1, KACHEL)):
        for x in range(KACHEL):
            px[x, y] = (0, 0, 0, 0)
    bild.alpha_composite(marker)
    return bild


def mit_kontur(bild: Image.Image) -> Image.Image:
    """Weiße Kontur rund um alle undurchsichtigen Formen."""
    breiter = bild.getchannel("A").filter(ImageFilter.MaxFilter(KONTUR * 2 + 1))
    weiss = Image.new("RGBA", bild.size, (255, 255, 255, 255))
    weiss.putalpha(breiter)
    return Image.alpha_composite(weiss, bild)


def main() -> None:
    marker = dreiecke()
    loch = mit_kontur(mit_neuen_dreiecken("V_x.png", marker))
    for name in LOCH_ZIELE:
        loch.save(DST / name)

    schwaeche = mit_kontur(mit_neuen_dreiecken("V_-1.png", marker))
    for name in SCHWAECHE_ZIELE:
        schwaeche.save(DST / name)

    for name in WERT_ZIELE:
        mit_kontur(Image.open(SRC / name).convert("RGBA")).save(DST / name)

    print(f"{len(LOCH_ZIELE) + len(SCHWAECHE_ZIELE) + len(WERT_ZIELE)} Tiles geschrieben")


if __name__ == "__main__":
    main()
