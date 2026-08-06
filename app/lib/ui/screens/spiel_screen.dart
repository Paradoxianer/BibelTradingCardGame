import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/game_bloc.dart';
import '../../bloc/game_event.dart';
import '../../bloc/game_ui_state.dart';
import '../widgets/handkarte_widget.dart';
import '../widgets/stapel_widget.dart';
import 'sieg_screen.dart';
import 'uebergabe_screen.dart';

String _phaseName(ZugPhase phase) => switch (phase) {
  ZugPhase.bauen => 'Bauen',
  ZugPhase.evilSpielen => 'Evil spielen (optional)',
  ZugPhase.reaktion => 'Reaktion auf Evil',
};

class SpielScreen extends StatelessWidget {
  final VoidCallback onNeuesSpiel;

  const SpielScreen({super.key, required this.onNeuesSpiel});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameUiState>(
      builder: (context, state) {
        if (!state.spiel.spielLaeuft) {
          return SiegScreen(spiel: state.spiel, onNeuesSpiel: onNeuesSpiel);
        }
        if (state.zeigtUebergabe) {
          return UebergabeScreen(
            naechsterSpielerName: state.spiel.aktiverSpieler.name,
            letzteWertung: state.letzteWertung,
            onWeiter: () =>
                context.read<GameBloc>().add(const UebergabeBestaetigt()),
          );
        }
        return _SpielBrett(state: state);
      },
    );
  }
}

class _SpielBrett extends StatelessWidget {
  final GameUiState state;
  const _SpielBrett({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    final spiel = state.spiel;
    final aktiver = spiel.aktiverSpieler;
    final andere = spiel.spieler.where((s) => s.id != aktiver.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${aktiver.name} — ${_phaseName(spiel.phase)}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Heiligkeit: ${aktiver.heiligkeit}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.fehler != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(8),
              child: Text(state.fehler!, style: const TextStyle(color: Colors.red)),
            ),
          for (final gegner in andere)
            _GegnerZeile(
              spieler: gegner,
              evilPhase: spiel.phase == ZugPhase.evilSpielen,
              evilKarteAusgewaehlt: spiel.phase == ZugPhase.evilSpielen &&
                  state.ausgewaehlteHandkarte != null,
              onFeldTap: (feldIndex) => bloc.add(
                EvilZielAngetippt(spielerId: gegner.id, feldIndex: feldIndex),
              ),
            ),
          const Divider(),
          Expanded(
            child: Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < aktiver.spielfelder.length; i++)
                    _EigenesFeld(
                      key: ValueKey('eigenes-feld-$i'),
                      feld: aktiver.spielfelder[i],
                      feldIndex: i,
                      bauenMoeglich: spiel.phase == ZugPhase.bauen,
                    ),
                ],
              ),
            ),
          ),
          if (spiel.phase == ZugPhase.reaktion)
            _ReaktionsLeiste(state: state)
          else
            _AktionsZeile(state: state),
          if (spiel.phase != ZugPhase.reaktion)
            _HandLeiste(hand: aktiver.hand, state: state),
        ],
      ),
    );
  }
}

/// Eigenes Spielfeld: antippbar wie bisher und zusätzlich Drag-Ziel.
/// Die Legalität entscheidet weiterhin allein der Bloc — die Prüfung hier
/// steuert nur, ob das Feld optisch als Ziel reagiert.
class _EigenesFeld extends StatelessWidget {
  final Spielfeld feld;
  final int feldIndex;
  final bool bauenMoeglich;

  const _EigenesFeld({
    super.key,
    required this.feld,
    required this.feldIndex,
    required this.bauenMoeglich,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    return DragTarget<Karte>(
      onWillAcceptWithDetails: (details) =>
          bauenMoeglich && details.data.kategorie != Kategorie.evil,
      onAcceptWithDetails: (details) {
        bloc.add(HandkarteAngetippt(details.data));
        bloc.add(FeldAngetippt(feldIndex));
      },
      builder: (context, kandidaten, _) => StapelWidget(
        feld: feld,
        ausgewaehlt: kandidaten.isNotEmpty,
        punkte: werteFeld(feld, feldIndex).punkte,
        vorschauKarte: kandidaten.isEmpty ? null : kandidaten.first,
        onTap: () => bloc.add(FeldAngetippt(feldIndex)),
      ),
    );
  }
}

class _GegnerZeile extends StatelessWidget {
  final Spieler spieler;
  final bool evilKarteAusgewaehlt;
  final bool evilPhase;
  final void Function(int feldIndex) onFeldTap;

  const _GegnerZeile({
    required this.spieler,
    required this.evilKarteAusgewaehlt,
    required this.evilPhase,
    required this.onFeldTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '${spieler.name}\nHeiligkeit ${spieler.heiligkeit}\nHand: ${spieler.hand.length}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < spieler.spielfelder.length; i++)
                  Transform.scale(
                    scale: 0.7,
                    child: DragTarget<Karte>(
                      onWillAcceptWithDetails: (details) =>
                          evilPhase && details.data.kategorie == Kategorie.evil,
                      onAcceptWithDetails: (details) {
                        context.read<GameBloc>().add(
                          HandkarteAngetippt(details.data),
                        );
                        onFeldTap(i);
                      },
                      builder: (context, kandidaten, _) => StapelWidget(
                        feld: spieler.spielfelder[i],
                        hervorgehoben:
                            evilKarteAusgewaehlt || kandidaten.isNotEmpty,
                        onTap: evilKarteAusgewaehlt
                            ? () => onFeldTap(i)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AktionsZeile extends StatelessWidget {
  final GameUiState state;
  const _AktionsZeile({required this.state});

  @override
  Widget build(BuildContext context) {
    final phase = state.spiel.phase;
    final hinweis = switch (phase) {
      ZugPhase.bauen =>
        'Handkarte antippen, dann eigenes Feld antippen (optional).',
      ZugPhase.evilSpielen =>
        'Evil-Karte antippen, dann Feld eines Mitspielers antippen (optional).',
      ZugPhase.reaktion => '',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(hinweis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          OutlinedButton(
            onPressed: () =>
                context.read<GameBloc>().add(const PassenAngetippt()),
            child: Text(phase == ZugPhase.bauen ? 'Bauen überspringen' : 'Evil überspringen'),
          ),
        ],
      ),
    );
  }
}

class _ReaktionsLeiste extends StatelessWidget {
  final GameUiState state;
  const _ReaktionsLeiste({required this.state});

  @override
  Widget build(BuildContext context) {
    final spiel = state.spiel;
    final verteidiger = spiel.spielerMitId(spiel.pendingEvilOpferId!);
    final sofortKarten = verteidiger.hand.where((k) => k.sofort).toList();
    return Container(
      color: Colors.red.shade50,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evil-Angriff auf ${verteidiger.name}! Reaktion mit Sofort-Karte möglich.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              for (final karte in sofortKarten)
                ActionChip(
                  label: Text(karte.name),
                  onPressed: () => context
                      .read<GameBloc>()
                      .add(ReaktionskarteAngetippt(karte)),
                ),
              ActionChip(
                label: const Text('Passen'),
                onPressed: () =>
                    context.read<GameBloc>().add(const PassenAngetippt()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HandLeiste extends StatelessWidget {
  final List<Karte> hand;
  final GameUiState state;
  const _HandLeiste({required this.hand, required this.state});

  @override
  Widget build(BuildContext context) {
    final phase = state.spiel.phase;
    return SizedBox(
      height: 144,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        children: [
          for (final karte in hand)
            Builder(
              builder: (context) {
                final spielbar =
                    (phase == ZugPhase.bauen &&
                        karte.kategorie != Kategorie.evil) ||
                    (phase == ZugPhase.evilSpielen &&
                        karte.kategorie == Kategorie.evil);
                final widget = HandkarteWidget(
                  karte: karte,
                  ausgewaehlt: karte.id == state.ausgewaehlteHandkarte?.id,
                  spielbar: spielbar,
                  onTap: () =>
                      context.read<GameBloc>().add(HandkarteAngetippt(karte)),
                );
                if (!spielbar) return widget;
                // Ziehen ist die zweite Bedienart neben Antippen — beide
                // lösen dieselben Bloc-Events aus.
                return Draggable<Karte>(
                  data: karte,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Transform.scale(scale: 1.1, child: widget),
                  ),
                  childWhenDragging: Opacity(opacity: 0.3, child: widget),
                  child: widget,
                );
              },
            ),
        ],
      ),
    );
  }
}
