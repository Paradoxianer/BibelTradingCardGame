import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/game_bloc.dart';
import '../../bloc/game_event.dart';
import '../../bloc/game_ui_state.dart';
import '../widgets/karten_widget.dart';
import '../widgets/spieler_bereich.dart';
import 'sieg_screen.dart';
import 'uebergabe_screen.dart';

String _phaseName(ZugPhase phase) => switch (phase) {
  ZugPhase.bauen => 'Bauen',
  ZugPhase.evilSpielen => 'Evil spielen (optional)',
  ZugPhase.reaktion => 'Reaktion auf Evil',
};

/// Hintergrund des Spielbretts. Dunkel und ruhig, damit die Löcher in den
/// Karten sichtbar durchscheinen (ARCHITEKTUR §3).
const BoxDecoration _bretthintergrund = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF35533F), Color(0xFF1F3327)],
  ),
);

/// Nur zwei Zustände, keine Zwischengrößen (keep it simple): auf schmalen
/// (Handy-)Bildschirmen die bisherige kompakte Darstellung, auf breiten
/// (Tablet/Desktop-)Bildschirmen direkt dieselbe Vollansicht wie in der
/// Großansicht per Doppeltipp — echte Kartengröße mit Bibeltext, statt nur
/// einer größer skalierten kompakten Karte (Issue #8).
({KartenAnsicht ansicht, double breite}) kartenDarstellungFuerBildschirm(
  double bildschirmBreite,
) => bildschirmBreite >= 1200
    ? (ansicht: KartenAnsicht.voll, breite: 320.0)
    : (ansicht: KartenAnsicht.kompakt, breite: 120.0);

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
    final spiel = state.spiel;
    final aktiver = spiel.aktiverSpieler;
    final darstellung = kartenDarstellungFuerBildschirm(MediaQuery.sizeOf(context).width);

    return Scaffold(
      appBar: AppBar(title: Text(_phaseName(spiel.phase))),
      body: DecoratedBox(
        decoration: _bretthintergrund,
        child: Column(
          children: [
            if (state.fehler != null)
              Container(
                width: double.infinity,
                color: Colors.red.shade100,
                padding: const EdgeInsets.all(8),
                child: Text(
                  state.fehler!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                // Alle Spieler in derselben Darstellung — der eigene Bereich
                // ist kein Sonderfall, nur die Rechte unterscheiden sich.
                child: Column(
                  children: [
                    // Man sitzt sich gegenüber: die Mitspieler oben, der
                    // eigene Bereich unten vor einem.
                    for (final s in spiel.spieler.where((s) => s.id != aktiver.id))
                      _Bereich(
                        spieler: s,
                        state: state,
                        eigen: false,
                        ansicht: darstellung.ansicht,
                        feldBreite: darstellung.breite,
                      ),
                    _Bereich(
                      spieler: aktiver,
                      state: state,
                      eigen: true,
                      ansicht: darstellung.ansicht,
                      feldBreite: darstellung.breite,
                    ),
                  ],
                ),
              ),
            ),
            if (spiel.phase == ZugPhase.reaktion)
              _ReaktionsLeiste(state: state)
            else
              _AktionsZeile(state: state),
          ],
        ),
      ),
    );
  }
}

/// Verdrahtet einen [SpielerBereich] mit dem Bloc: Drag-Ziele, Tap-Aktionen
/// und Punkte-Vorschau. Die Legalität entscheidet weiterhin der Bloc.
class _Bereich extends StatelessWidget {
  final Spieler spieler;
  final GameUiState state;
  final bool eigen;
  final KartenAnsicht ansicht;
  final double feldBreite;

  const _Bereich({
    required this.spieler,
    required this.state,
    required this.eigen,
    required this.ansicht,
    required this.feldBreite,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    final phase = state.spiel.phase;
    final bauenMoeglich = eigen && phase == ZugPhase.bauen;
    final evilMoeglich = !eigen && phase == ZugPhase.evilSpielen;

    return SpielerBereich(
      spieler: spieler,
      eigen: eigen,
      amZug: eigen,
      ansicht: ansicht,
      feldBreite: feldBreite,
      feldPunkte: eigen
          ? [
              for (var i = 0; i < spieler.spielfelder.length; i++)
                werteFeld(spieler.spielfelder[i], i).punkte,
            ]
          : const [],
      feldBauen: (context, i) => DragTarget<Karte>(
        onWillAcceptWithDetails: (d) => bauenMoeglich
            ? d.data.kategorie != Kategorie.evil
            : evilMoeglich && d.data.kategorie == Kategorie.evil,
        onAcceptWithDetails: (d) {
          bloc.add(HandkarteAngetippt(d.data));
          if (eigen) {
            bloc.add(FeldAngetippt(i));
          } else {
            bloc.add(EvilZielAngetippt(spielerId: spieler.id, feldIndex: i));
          }
        },
        builder: (context, kandidaten, _) => _AntippbaresFeld(
          key: eigen ? ValueKey('eigenes-feld-$i') : null,
          feld: spieler.spielfelder[i],
          breite: feldBreite,
          ansicht: ansicht,
          hervorgehoben: kandidaten.isNotEmpty,
          vorschauKarte: kandidaten.isEmpty ? null : kandidaten.first,
          onTap: eigen
              ? () => bloc.add(FeldAngetippt(i))
              : () => bloc.add(
                  EvilZielAngetippt(spielerId: spieler.id, feldIndex: i),
                ),
        ),
      ),
      handkarteBauen: (context, karte) {
        final spielbar =
            (phase == ZugPhase.bauen && karte.kategorie != Kategorie.evil) ||
            (phase == ZugPhase.evilSpielen &&
                karte.kategorie == Kategorie.evil);
        final ausgewaehlt = karte.id == state.ausgewaehlteHandkarte?.id;
        final karteWidget = _AntippbareHandkarte(
          karte: karte,
          breite: feldBreite,
          ansicht: ansicht,
          spielbar: spielbar,
          ausgewaehlt: ausgewaehlt,
          onTap: () => bloc.add(HandkarteAngetippt(karte)),
        );
        if (!spielbar) return karteWidget;
        // Ziehen ist die zweite Bedienart neben Antippen; beide lösen
        // dieselben Bloc-Events aus.
        return Draggable<Karte>(
          data: karte,
          feedback: Material(
            color: Colors.transparent,
            child: KartenWidget.handkarte(karte, breite: feldBreite, ansicht: ansicht),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: karteWidget),
          child: karteWidget,
        );
      },
    );
  }
}

/// Spielfeld mit Auswahlrahmen und optionaler Ablege-Vorschau.
class _AntippbaresFeld extends StatelessWidget {
  final Spielfeld feld;
  final double breite;
  final KartenAnsicht ansicht;
  final bool hervorgehoben;
  final Karte? vorschauKarte;
  final VoidCallback onTap;

  const _AntippbaresFeld({
    super.key,
    required this.feld,
    required this.breite,
    required this.ansicht,
    required this.hervorgehoben,
    required this.vorschauKarte,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final jetzt = werteFeld(feld, 0).punkte;
    // Bei ansicht == voll zeigt das Feld Bibeltext & Co. schon direkt an —
    // die Großansicht-Dialog wäre dann nur eine identische Kopie.
    final grossansichtNoetig = !feld.istLeer && ansicht != KartenAnsicht.voll;
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: grossansichtNoetig ? () => zeigeFeldGross(context, feld) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hervorgehoben ? Colors.amber : Colors.transparent,
                width: 3,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: StapelWidget(feld: feld, breite: breite, ansicht: ansicht),
            ),
          ),
          if (vorschauKarte != null)
            _Vorschau(
              vorher: jetzt,
              nachher: werteFeld(feld.legeObenauf(vorschauKarte!), 0).punkte,
            ),
        ],
      ),
    );
  }
}

/// Zeigt beim Drag über einem Feld, wie sich die Punkte ändern würden.
class _Vorschau extends StatelessWidget {
  final int vorher;
  final int nachher;

  const _Vorschau({required this.vorher, required this.nachher});

  static String _v(int w) => w > 0 ? '+$w' : '$w';

  @override
  Widget build(BuildContext context) {
    // Bewusst ohne Differenz: „−6 → −2" ist eindeutig, ein zusätzliches
    // „(+4)" liest sich leicht als das Ergebnis.
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: _v(vorher),
              style: const TextStyle(color: Colors.white54),
            ),
            const TextSpan(
              text: '  →  ',
              style: TextStyle(color: Colors.white38),
            ),
            TextSpan(
              text: _v(nachher),
              style: TextStyle(
                color: nachher > vorher
                    ? Colors.greenAccent
                    : nachher < vorher
                    ? Colors.redAccent
                    : Colors.white70,
              ),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Offene Handkarte: antippen wählt aus, Doppeltippen zeigt sie groß.
class _AntippbareHandkarte extends StatelessWidget {
  final Karte karte;
  final double breite;
  final KartenAnsicht ansicht;
  final bool spielbar;
  final bool ausgewaehlt;
  final VoidCallback onTap;

  const _AntippbareHandkarte({
    required this.karte,
    required this.breite,
    required this.ansicht,
    required this.spielbar,
    required this.ausgewaehlt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: spielbar ? 1.0 : 0.45,
    child: GestureDetector(
      onTap: spielbar ? onTap : null,
      // Bei ansicht == voll zeigt die Handkarte Bibeltext & Co. schon direkt
      // an — die Großansicht-Dialog wäre dann nur eine identische Kopie.
      onDoubleTap: ansicht == KartenAnsicht.voll ? null : () => zeigeKarteGross(context, karte),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ausgewaehlt ? Colors.amber : Colors.transparent,
            width: 3,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: KartenWidget.handkarte(karte, breite: breite, ansicht: ansicht),
        ),
      ),
    ),
  );
}

/// Karte in voller Größe mit Bibeltext — die Verse sind der Inhalt des
/// Spiels und sollen jederzeit lesbar sein.
void zeigeKarteGross(BuildContext context, Karte karte) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: KartenWidget.handkarte(
        karte,
        ansicht: KartenAnsicht.voll,
        breite: 320,
      ),
    ),
  );
}

/// Der ganze Stapel groß — nicht nur die oberste Karte, sondern der
/// tatsächliche physische Stapel, damit man sieht, was durch die Löcher der
/// obersten Karte hindurchscheint (dieselbe [StapelWidget]-Stapelung wie auf
/// dem Brett, nur größer und in [KartenAnsicht.voll] mit Bibeltext — dieselbe
/// Ansicht wie bei einer einzelnen Karte, nicht die verdichtete Brettform).
void zeigeFeldGross(BuildContext context, Spielfeld feld) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: StapelWidget(
        feld: feld,
        breite: 320,
        ansicht: KartenAnsicht.voll,
      ),
    ),
  );
}

class _AktionsZeile extends StatelessWidget {
  final GameUiState state;
  const _AktionsZeile({required this.state});

  @override
  Widget build(BuildContext context) {
    final phase = state.spiel.phase;
    final hinweis = switch (phase) {
      ZugPhase.bauen => 'Karte auf ein eigenes Feld ziehen oder antippen.',
      ZugPhase.evilSpielen =>
        'Evil-Karte auf ein Feld eines Mitspielers ziehen (optional).',
      ZugPhase.reaktion => '',
    };
    return Container(
      color: Colors.black38,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hinweis,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () => _passenBestaetigen(context, phase),
            child: Text(
              phase == ZugPhase.bauen ? 'Bauen überspringen' : 'Evil überspringen',
            ),
          ),
        ],
      ),
    );
  }

  /// Vor dem Verschenken des Bauzugs nachfragen — versehentliches Antippen
  /// kostet sonst eine ganze Runde.
  Future<void> _passenBestaetigen(BuildContext context, ZugPhase phase) async {
    final bloc = context.read<GameBloc>();
    if (phase != ZugPhase.bauen) {
      bloc.add(const PassenAngetippt());
      return;
    }
    final ja = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bauen überspringen?'),
        content: const Text(
          'Du legst diese Runde keine Karte an. Die Auslage bleibt, wie sie '
          'ist — und bringt entsprechend weniger Heiligkeit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zurück'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Überspringen'),
          ),
        ],
      ),
    );
    if (ja ?? false) bloc.add(const PassenAngetippt());
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
                  onPressed: () =>
                      context.read<GameBloc>().add(ReaktionskarteAngetippt(karte)),
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
