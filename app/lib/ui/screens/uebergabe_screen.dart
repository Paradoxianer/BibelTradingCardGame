import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';

/// Zwischen zwei Zügen: zeigt dem gerade aktiven Spieler seine Wertungs-
/// Aufschlüsselung (ARCHITEKTUR §2), dann verdeckt die Handkarten des
/// nächsten Spielers, bis das Gerät physisch übergeben wurde (REGELWERK D9).
class UebergabeScreen extends StatelessWidget {
  final String naechsterSpielerName;
  final Wertung? letzteWertung;
  final VoidCallback onWeiter;

  const UebergabeScreen({
    super.key,
    required this.naechsterSpielerName,
    required this.onWeiter,
    this.letzteWertung,
  });

  @override
  Widget build(BuildContext context) {
    final wertung = letzteWertung;
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (wertung != null) ...[
              Text(
                'Wertung: ${wertung.punkte >= 0 ? '+' : ''}${wertung.punkte} Heiligkeit',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              for (final f in wertung.felder)
                if (f.punkte != 0)
                  Text(
                    'Feld ${f.feldIndex + 1}: ${f.punkte >= 0 ? '+' : ''}${f.punkte}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
              if (wertung.globalerZuschlag != 0)
                Text(
                  'Globale Effekte: ${wertung.globalerZuschlag >= 0 ? '+' : ''}${wertung.globalerZuschlag}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              const SizedBox(height: 32),
            ],
            const Icon(Icons.swap_horiz, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              'Gerät an $naechsterSpielerName geben',
              style: const TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: onWeiter,
              child: Text('Weiter, ich bin $naechsterSpielerName'),
            ),
          ],
        ),
      ),
    );
  }
}
