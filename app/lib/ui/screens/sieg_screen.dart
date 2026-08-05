import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';

class SiegScreen extends StatelessWidget {
  final GameState spiel;
  final VoidCallback onNeuesSpiel;

  const SiegScreen({super.key, required this.spiel, required this.onNeuesSpiel});

  @override
  Widget build(BuildContext context) {
    final gewinner = spiel.spieler.firstWhere((s) => s.id == spiel.gewinnerId);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 72),
            const SizedBox(height: 16),
            Text(
              '${gewinner.name} gewinnt!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('Heiligkeit: ${gewinner.heiligkeit}'),
            const SizedBox(height: 32),
            for (final s in spiel.spieler)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('${s.name}: ${s.heiligkeit} Heiligkeit'),
              ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: onNeuesSpiel,
              child: const Text('Neues Spiel'),
            ),
          ],
        ),
      ),
    );
  }
}
