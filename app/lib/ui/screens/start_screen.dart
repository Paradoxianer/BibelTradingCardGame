import 'dart:math';

import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/game_bloc.dart';
import '../../data/deckbau.dart';
import '../../data/kartenset_loader.dart';
import 'spiel_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late final Future<Kartenset> _kartenset = ladeKartenset();

  void _neuesSpielStarten(BuildContext context, Kartenset kartenset) {
    final random = Random();
    final seed = random.nextInt(1 << 31);
    final aufbau = [
      baueZufaelligesDeck(
        id: 'p1',
        name: 'Spieler 1',
        alleKarten: kartenset.alleKarten,
        random: Random(seed),
      ),
      baueZufaelligesDeck(
        id: 'p2',
        name: 'Spieler 2',
        alleKarten: kartenset.alleKarten,
        random: Random(seed + 1),
      ),
    ];
    final anfangszustand = neuesSpiel(spieler: aufbau, seed: seed);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => GameBloc(
            anfangszustand: anfangszustand,
            kartenset: kartenset,
          ),
          child: SpielScreen(
            onNeuesSpiel: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<Kartenset>(
          future: _kartenset,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Fehler beim Laden der Kartendaten: ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            final kartenset = snapshot.data!;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'BibelTradingCardGame',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text('${kartenset.alleKarten.length} Karten geladen (Set ${kartenset.set})'),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => _neuesSpielStarten(context, kartenset),
                  child: const Text('Neues Hotseat-Spiel (2 Spieler)'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
