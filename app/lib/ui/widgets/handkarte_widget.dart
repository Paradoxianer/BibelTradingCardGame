import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';

/// Einzelne Handkarte: Name, Kategorie, Slot-Zeile (unverdeckt, da eigene
/// Hand). Farblich markiert, wenn ausgewählt oder gerade nicht spielbar.
class HandkarteWidget extends StatelessWidget {
  final Karte karte;
  final bool ausgewaehlt;
  final bool spielbar;
  final VoidCallback? onTap;

  const HandkarteWidget({
    super.key,
    required this.karte,
    this.ausgewaehlt = false,
    this.spielbar = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: spielbar ? 1.0 : 0.45,
      child: GestureDetector(
        onTap: spielbar ? onTap : null,
        child: Container(
          width: 92,
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: karte.kategorie == Kategorie.evil
                ? Colors.red.shade50
                : Colors.white,
            border: Border.all(
              color: ausgewaehlt ? Colors.amber : Colors.black38,
              width: ausgewaehlt ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                karte.name,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                karte.kategorie.name,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
              if (karte.sofort)
                const Text(
                  'sofort',
                  style: TextStyle(fontSize: 9, color: Colors.blue),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
