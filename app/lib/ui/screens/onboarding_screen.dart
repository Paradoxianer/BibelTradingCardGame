import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';

import '../widgets/karten_widget.dart';

Karte _demoKarte(String id, List<String> slots) => Karte(
  id: id,
  cardId: id,
  name: id,
  vers: const Vers(stelle: '', text: ''),
  slots: slots.map(SlotSymbol.parse).toList(),
  kategorie: Kategorie.gebet,
  seltenheit: 'haeufig',
  sofort: false,
  effekt: null,
  anzahlImDeckMax: 3,
  pictureLink: '',
);

/// Kurzes, seitenweises Tutorial vor dem ersten Spiel. Die Loch-Mechanik ist
/// laut ARCHITEKTUR.md das "visuelle Alleinstellungsmerkmal" — hier wird sie
/// nicht nur erklärt, sondern mit echten [KartenWidget]s vorgeführt.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFertig;

  const OnboardingScreen({super.key, required this.onFertig});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _seite = 0;

  static const int _anzahlSeiten = 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _weiter() {
    if (_seite == _anzahlSeiten - 1) {
      widget.onFertig();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.ease);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _seite = i),
                children: const [
                  _WillkommenSeite(),
                  _KartenaufbauSeite(),
                  _LochMechanikSeite(),
                  _RundenablaufSeite(),
                  _LosGehtsSeite(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: widget.onFertig,
                    child: const Text('Überspringen'),
                  ),
                  const Spacer(),
                  Row(
                    children: List.generate(
                      _anzahlSeiten,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _seite
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _weiter,
                    child: Text(_seite == _anzahlSeiten - 1 ? 'Los geht\'s' : 'Weiter'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeitenGeruest extends StatelessWidget {
  final String titel;
  final Widget inhalt;

  const _SeitenGeruest({required this.titel, required this.inhalt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titel, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          Expanded(child: Center(child: inhalt)),
        ],
      ),
    );
  }
}

class _WillkommenSeite extends StatelessWidget {
  const _WillkommenSeite();

  @override
  Widget build(BuildContext context) {
    return _SeitenGeruest(
      titel: 'Willkommen bei BibelTradingCardGame',
      inhalt: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 64, color: Colors.amber),
          const SizedBox(height: 24),
          const Text(
            'Ziel: Bringe deine Heiligkeit von 30 auf 100.\n'
            'Sie kann nie unter 0 fallen.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            '„Überwinde das Böse mit Gutem." (Röm 12,21)',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _KartenaufbauSeite extends StatelessWidget {
  const _KartenaufbauSeite();

  @override
  Widget build(BuildContext context) {
    return _SeitenGeruest(
      titel: 'Jede Karte zeigt 6 Symbole',
      inhalt: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Zwei Symbole je Person: Vater, Sohn, Heiliger Geist.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SymbolErklaerung(
                bild: 'assets/artwork/V_2.png',
                titel: 'Bunt (0-2)',
                beschreibung: 'Stärke —\nzählt nur\ndurch ein Loch',
              ),
              const SizedBox(width: 24),
              _SymbolErklaerung(
                bild: 'assets/artwork/V_-1.png',
                titel: 'Schwarz',
                beschreibung: 'Schwäche —\nzählt immer,\nsobald sichtbar',
              ),
              const SizedBox(width: 24),
              _SymbolErklaerung(
                bild: 'assets/artwork/Empty.png',
                titel: 'Loch',
                beschreibung: 'zeigt die\nKarte darunter',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Unterlegt eine Demo-Karte mit dem Spielbrett-Grün. Auf hellem Grund wäre
/// nicht zu sehen, dass ein Loch durchsichtig ist — und genau darum geht es
/// auf dieser Seite.
class _AufBrett extends StatelessWidget {
  final Widget child;

  const _AufBrett({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFF2A4433),
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );
}

class _SymbolErklaerung extends StatelessWidget {
  final String bild;
  final String titel;
  final String beschreibung;

  const _SymbolErklaerung({
    required this.bild,
    required this.titel,
    required this.beschreibung,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(bild, width: 48, height: 48),
        const SizedBox(height: 8),
        Text(titel, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          beschreibung,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _LochMechanikSeite extends StatelessWidget {
  const _LochMechanikSeite();

  @override
  Widget build(BuildContext context) {
    // Karte A: V1 bunt (2, zählt erst durch ein Loch), V2 schwarz (-1,
    // zählt immer). Karte B: Löcher genau dort, wo A etwas zu zeigen hat.
    final karteA = _demoKarte('a', ['2', '-1', '0', '0', '0', '0']);
    final karteB = _demoKarte('b', ['x', 'x', '0', '0', '0', '0']);
    final vorher = Spielfeld([Kartenlage(karteA)]);
    final nachher = Spielfeld([Kartenlage(karteB), Kartenlage(karteA)]);

    return _SeitenGeruest(
      titel: 'Das Kernprinzip',
      inhalt: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Schwarz zählt SOFORT. Bunte Werte zählen NICHT auf der\n'
            'obersten Karte — erst wenn später eine Karte mit Loch\n'
            'sie freilegt.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Text('Vorher', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _AufBrett(child: StapelWidget(feld: vorher, breite: 110)),
                  const SizedBox(height: 8),
                  const Text('−1 Punkt sichtbar', style: TextStyle(color: Colors.grey)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.arrow_forward, size: 32),
              ),
              Column(
                children: [
                  const Text('Nachher', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _AufBrett(child: StapelWidget(feld: nachher, breite: 110)),
                  const SizedBox(height: 8),
                  const Text(
                    '+2 −1 = +1 Punkt sichtbar',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Die zweite Karte hat Löcher genau an den Stellen der ersten —\n'
            'jetzt zählt der bunte Wert (+2), und der schwarze (−1) zählt\n'
            'immer noch. Böses wird nicht zerstört, sondern überbaut.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _RundenablaufSeite extends StatelessWidget {
  const _RundenablaufSeite();

  @override
  Widget build(BuildContext context) {
    return _SeitenGeruest(
      titel: 'Ein Zug in 4 Schritten',
      inhalt: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SchrittZeile(
            nummer: 1,
            titel: 'Bauen',
            beschreibung: 'Eine Handkarte offen auf eines deiner Felder legen (optional).',
          ),
          _SchrittZeile(
            nummer: 2,
            titel: 'Evil spielen',
            beschreibung:
                'Optional eine Evil-Karte gegen einen Mitspieler — nicht in Runde 1, '
                'nicht gegen jemanden, der diese Runde schon Evil bekam.',
          ),
          _SchrittZeile(
            nummer: 3,
            titel: 'Wertung',
            beschreibung: 'Läuft automatisch: alle deine Felder werden gewertet.',
          ),
          _SchrittZeile(
            nummer: 4,
            titel: 'Nachziehen',
            beschreibung: 'Du füllst deine Hand automatisch auf 5 Karten auf.',
          ),
        ],
      ),
    );
  }
}

class _SchrittZeile extends StatelessWidget {
  final int nummer;
  final String titel;
  final String beschreibung;

  const _SchrittZeile({
    required this.nummer,
    required this.titel,
    required this.beschreibung,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 14, child: Text('$nummer')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titel, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(beschreibung, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LosGehtsSeite extends StatelessWidget {
  const _LosGehtsSeite();

  @override
  Widget build(BuildContext context) {
    return _SeitenGeruest(
      titel: 'Bereit?',
      inhalt: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green),
          SizedBox(height: 24),
          Text(
            'Am Anfang liegt bei jedem die Karte "Alle sind Sünder" '
            'unbedeckt auf Feld 1 — sie kostet 6 Heiligkeit pro Zug, '
            'bis sie überbaut wird.',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'Diese Erklärung findest du jederzeit wieder über den\n'
            'Hilfe-Button auf dem Startbildschirm.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
