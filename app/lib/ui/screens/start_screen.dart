import 'dart:math';

import 'package:btcg_engine/bots/bots.dart';
import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../bloc/game_bloc.dart';
import '../../bloc/spiel_persistenz.dart';
import '../../data/kartenset_loader.dart';
import 'onboarding_screen.dart';
import 'spiel_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late final Future<Kartenset> _kartenset = ladeKartenset();

  void _oeffneSpiel(
    BuildContext context, {
    required Kartenset kartenset,
    required List<SpielerAufbau> aufbauListe,
    required int seed,
    required RegelConfig config,
    required Map<String, Bot> botSpieler,
    required int botSeed,
  }) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => GameBloc(
                kartenset: kartenset,
                aufbauListe: aufbauListe,
                seed: seed,
                config: config,
                botSpieler: botSpieler,
                botSeed: botSeed,
              ),
              child: SpielScreen(onNeuesSpiel: () => Navigator.of(context).pop()),
            ),
          ),
        )
        .then((_) => setState(() {})); // Rückkehr: "Fortsetzen"-Sichtbarkeit neu prüfen
  }

  Future<void> _neuesSpielStarten(
    BuildContext context,
    Kartenset kartenset, {
    required Map<String, Bot> botSpieler,
  }) async {
    await GameBloc.loescheGespeichertesSpiel();
    final random = Random();
    final seed = random.nextInt(1 << 31);
    final aufbauListe = [
      baueZufaelligesDeck(
        id: 'p1',
        name: 'Spieler 1',
        alleKarten: kartenset.alleKarten,
        seed: seed,
      ),
      baueZufaelligesDeck(
        id: 'p2',
        name: botSpieler.containsKey('p2') ? 'Computer' : 'Spieler 2',
        alleKarten: kartenset.alleKarten,
        seed: seed + 1,
      ),
    ];
    if (!context.mounted) return;
    _oeffneSpiel(
      context,
      kartenset: kartenset,
      aufbauListe: aufbauListe,
      seed: seed,
      config: const RegelConfig(),
      botSpieler: botSpieler,
      botSeed: seed + 2,
    );
  }

  void _spielFortsetzen(BuildContext context, Kartenset kartenset) {
    final json =
        HydratedBloc.storage.read(GameBloc.speicherSchluessel) as Map<dynamic, dynamic>?;
    if (json == null) return;
    final partie = parseGespeichertePartie(
      json.map((k, v) => MapEntry(k as String, v)),
      kartenset,
    );
    if (partie == null) return;
    _oeffneSpiel(
      context,
      kartenset: kartenset,
      aufbauListe: partie.aufbauListe,
      seed: partie.seed,
      config: partie.config,
      botSpieler: partie.botSpieler,
      botSeed: partie.botSeed,
    );
  }

  void _regelnZeigen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnboardingScreen(
          onFertig: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Bewusst als leading statt trailing action: der rechte Rand
        // überlappt sich im Debug-Build mit Flutters Debug-Banner.
        leading: IconButton(
          onPressed: () => _regelnZeigen(context),
          icon: const Icon(Icons.help_outline),
          tooltip: 'Wie spielt man?',
        ),
      ),
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
            final fortsetzenMoeglich = GameBloc.gespeichertesSpielVorhanden();
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
                if (fortsetzenMoeglich) ...[
                  FilledButton.icon(
                    onPressed: () => _spielFortsetzen(context, kartenset),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Spiel fortsetzen'),
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton(
                  onPressed: () => _neuesSpielStarten(
                    context,
                    kartenset,
                    botSpieler: const {},
                  ),
                  child: const Text('Neues Hotseat-Spiel (2 Spieler)'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _neuesSpielStarten(
                    context,
                    kartenset,
                    botSpieler: const {'p2': GreedyBot()},
                  ),
                  child: const Text('Gegen den Computer spielen'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
