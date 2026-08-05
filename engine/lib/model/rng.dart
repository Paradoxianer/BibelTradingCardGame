/// Seedbarer, rein funktionaler RNG (xorshift32): Jeder Zug liefert eine neue
/// [SeedableRng]-Instanz statt intern zu mutieren, damit [GameState]
/// unveränderlich bleiben kann (ARCHITEKTUR §2 — "Gleicher Seed + gleiche
/// Commands = gleiches Spiel"). 32-bit-Arithmetik bewusst, damit VM und Web
/// (dart2js) identische Ergebnisse liefern.
class SeedableRng {
  final int state;

  const SeedableRng._(this.state);

  factory SeedableRng.seeded(int seed) {
    final s = seed & 0xFFFFFFFF;
    return SeedableRng._(s == 0 ? 1 : s);
  }

  /// Liefert eine Zahl in `[0, exklusivesMax)` und den Folgezustand.
  (int wert, SeedableRng rng) naechsteZahl(int exklusivesMax) {
    assert(exklusivesMax > 0);
    var x = state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    x &= 0xFFFFFFFF;
    if (x == 0) x = 1;
    return (x % exklusivesMax, SeedableRng._(x));
  }
}

/// Fisher-Yates-Mischen, rein funktional über [SeedableRng].
(List<T> liste, SeedableRng rng) mische<T>(List<T> liste, SeedableRng rng) {
  final kopie = List<T>.of(liste);
  var aktuellerRng = rng;
  for (var i = kopie.length - 1; i > 0; i--) {
    final (index, neuerRng) = aktuellerRng.naechsteZahl(i + 1);
    aktuellerRng = neuerRng;
    final tmp = kopie[i];
    kopie[i] = kopie[index];
    kopie[index] = tmp;
  }
  return (kopie, aktuellerRng);
}
