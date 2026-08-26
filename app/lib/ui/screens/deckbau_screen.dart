import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';

import '../../data/deck_repository.dart';
import '../widgets/karten_widget.dart';

/// Eigenes Deck zusammenstellen (Issue #17): Auswahl aus dem ganzen
/// Kartenpool (Kartenbesitz gibt es noch nicht, siehe #10/#11 — bis dahin
/// steht der volle Bestand zur Verfügung), Live-Prüfung gegen REGELWERK §2
/// über [pruefeDeck], Speichern über [DeckRepository].
///
/// Zwei CoverFlow-Karussells ([_KartenCoverflow], Hauptkarte in der Mitte,
/// Nachbarn kleiner und blasser daneben — wie beim klassischen
/// Apple-Coverflow) statt einer Textliste oder eines Scroll-Streifens: oben
/// das gebaute Deck, unten der Kartenpool, dazwischen frei in beide
/// Richtungen ziehbar. Zieht man eine Deck-Karte in den Pool, verschwindet
/// sie aus dem Deck — vorbereitet für ein künftiges Besitz-Modell, in dem
/// der Pool tatsächlich nur noch die Karten zeigt, die man (noch) hat.
class DeckbauScreen extends StatefulWidget {
  final Kartenset kartenset;

  const DeckbauScreen({super.key, required this.kartenset});

  @override
  State<DeckbauScreen> createState() => _DeckbauScreenState();
}

/// Eine gezogene Karte plus Herkunft — damit ein Drop-Ziel unterscheiden
/// kann, ob eine Pool-Karte ins Deck soll (hinzufügen) oder eine
/// Deck-Karte in den Pool zurück (entfernen), auch wenn beide Karussells
/// gleichzeitig Drag-Quelle und Drop-Ziel sind.
class _Zug {
  final Karte karte;
  final bool ausDeck;
  const _Zug(this.karte, {required this.ausDeck});
}

class _DeckbauScreenState extends State<DeckbauScreen> {
  late List<Karte> _deck;
  late final List<Karte> _auswaehlbar;
  Kategorie? _filter;
  _Sortierung _sortierung = _Sortierung.kategorie;
  int _deckSeite = 0;
  int _poolSeite = 0;

  @override
  void initState() {
    super.initState();
    _deck = List.of(DeckRepository.lade(widget.kartenset.alleKarten));
    _auswaehlbar = widget.kartenset.alleKarten.where((k) => k.kategorie != Kategorie.start).toList()
      ..sort((a, b) {
        final kat = a.kategorie.index.compareTo(b.kategorie.index);
        return kat != 0 ? kat : a.name.compareTo(b.name);
      });
  }

  List<Karte> get _gefiltert {
    final basis = _filter == null ? _auswaehlbar : _auswaehlbar.where((k) => k.kategorie == _filter).toList();
    if (_sortierung == _Sortierung.kategorie) return basis; // schon Kategorie+Name sortiert
    return List<Karte>.of(basis)..sort((a, b) {
      final wa = _sortierung.wertFuer(a)!;
      final wb = _sortierung.wertFuer(b)!;
      // Absteigend: der beste Wert beim gewählten Kriterium zuerst.
      return wa != wb ? wb.compareTo(wa) : a.name.compareTo(b.name);
    });
  }

  int _anzahlImDeck(Karte karte) => _deck.where((k) => k.id == karte.id).length;

  bool _kannHinzufuegen(Karte karte) => _anzahlImDeck(karte) < karte.anzahlImDeckMax;

  void _hinzufuegen(Karte karte) {
    if (!_kannHinzufuegen(karte)) return;
    setState(() => _deck.add(karte));
  }

  void _entfernenNachIndex(int index) => setState(() => _deck.removeAt(index));

  void _entfernenErsteVorkommen(Karte karte) => setState(() {
    final index = _deck.indexWhere((k) => k.id == karte.id);
    if (index != -1) _deck.removeAt(index);
  });

  void _filterSetzen(Kategorie? kategorie) => setState(() {
    _filter = kategorie;
    _poolSeite = 0;
  });

  void _sortierungSetzen(_Sortierung sortierung) => setState(() {
    _sortierung = sortierung;
    _poolSeite = 0;
  });

  void _zufaelligFuellen() {
    final aufbau = baueZufaelligesDeck(
      id: 'vorschlag',
      name: '',
      alleKarten: widget.kartenset.alleKarten,
      seed: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() => _deck = List.of(aufbau.deck));
  }

  void _leeren() => setState(() => _deck.clear());

  Future<void> _speichern() async {
    await DeckRepository.speichere(_deck);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deck gespeichert.')));
  }

  Widget _deckKarteBauen(Karte karte) {
    // breite: null — die Karte füllt selbst die Fläche, die ihr das
    // CoverFlow-Karussell gibt, ohne dass hier nachgerechnet werden muss
    // (KartenWidget kennt als einzige Stelle das feste Seitenverhältnis).
    final inhalt = KartenWidget.handkarte(karte, breite: null, ansicht: KartenAnsicht.voll);
    // LongPressDraggable statt Draggable: dessen Erkennung lehnt sich aktiv
    // ab, sobald sich der Finger vor Ablauf der Wartezeit bewegt (Flutter-
    // intern DelayedMultiDragGestureRecognizer.checkForResolutionAfterMove),
    // und gibt die Geste damit sauber an die PageView-Wischgeste weiter. Ein
    // normaler Draggable (auch mit `axis`) löst sich dagegen nie aktiv, "gewinnt"
    // dadurch trotzdem gegen das Karussell und blockiert jedes Blättern.
    return LongPressDraggable<_Zug>(
      data: _Zug(karte, ausDeck: true),
      feedback: Material(color: Colors.transparent, child: inhalt),
      childWhenDragging: Opacity(opacity: 0.3, child: inhalt),
      child: inhalt,
    );
  }

  Widget _poolKarteBauen(Karte karte) {
    final anzahl = _anzahlImDeck(karte);
    final kann = _kannHinzufuegen(karte);
    final inhalt = KartenWidget.handkarte(karte, breite: null, ansicht: KartenAnsicht.voll);
    final mitZaehler = Opacity(
      opacity: kann ? 1.0 : 0.45,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          inhalt,
          Positioned(top: -8, right: -8, child: _Zaehler(anzahl: anzahl, max: karte.anzahlImDeckMax)),
        ],
      ),
    );
    if (!kann) return mitZaehler;
    return LongPressDraggable<_Zug>(
      data: _Zug(karte, ausDeck: false),
      feedback: Material(color: Colors.transparent, child: inhalt),
      childWhenDragging: Opacity(opacity: 0.3, child: mitZaehler),
      child: mitZaehler,
    );
  }

  /// Bewusst konstant: der PageController in [_KartenCoverflow] wird nicht
  /// neu aufgebaut, wenn sich die Fläche ändert (z. B. beim Skalieren des
  /// Browserfensters). Eine aus der Fläche abgeleitete Fraction lief dadurch
  /// mit dem Fenster auseinander. Wie groß die Karte selbst innerhalb ihres
  /// Ausschnitts wird, rechnet [KartenWidget] jetzt allein aus (`breite:
  /// null`) — hier geht es nur noch darum, wie viel Nachbarn hereinragen.
  static const double _kViewportFraction = 0.42;

  @override
  Widget build(BuildContext context) {
    final fehler = pruefeDeck(_deck);
    final evilAnzahl = _deck.where((k) => k.kategorie == Kategorie.evil).length;
    final gefiltert = _gefiltert;
    final deckSeite = _deck.isEmpty ? 0 : _deckSeite.clamp(0, _deck.length - 1);
    final poolSeite = gefiltert.isEmpty ? 0 : _poolSeite.clamp(0, gefiltert.length - 1);

    return Scaffold(
      appBar: AppBar(title: const Text('Eigenes Deck')),
      body: Column(
        children: [
          _StatusLeiste(gesamt: _deck.length, evil: evilAnzahl, fehler: fehler),
          const _Ueberschrift('Dein Deck — Karte aus dem Pool hierher ziehen'),
          Expanded(
            child: DragTarget<_Zug>(
              key: const ValueKey('deck-dragtarget'),
              onWillAcceptWithDetails: (d) => !d.data.ausDeck && _kannHinzufuegen(d.data.karte),
              onAcceptWithDetails: (d) => _hinzufuegen(d.data.karte),
              builder: (context, kandidaten, _) => _Rahmen(
                hervorgehoben: kandidaten.isNotEmpty,
                child: _deck.isEmpty
                    ? const Center(child: Text('Noch keine Karten im Deck.'))
                    : _KartenCoverflow(
                        karten: _deck,
                        viewportFraction: _kViewportFraction,
                        kartenBauen: _deckKarteBauen,
                        onSeiteGeaendert: (i) => setState(() => _deckSeite = i),
                      ),
              ),
            ),
          ),
          if (_deck.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: OutlinedButton.icon(
                onPressed: () => _entfernenNachIndex(deckSeite),
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('Aus dem Deck entfernen'),
              ),
            ),
          const Divider(height: 16),
          const _Ueberschrift('Kartenpool — antippen und ins Deck ziehen'),
          Row(
            children: [
              Expanded(child: _KategorieFilter(aktuell: _filter, onGewaehlt: _filterSetzen)),
              _SortierMenu(aktuell: _sortierung, onGewaehlt: _sortierungSetzen),
            ],
          ),
          Expanded(
            child: DragTarget<_Zug>(
              key: const ValueKey('pool-dragtarget'),
              onWillAcceptWithDetails: (d) => d.data.ausDeck,
              onAcceptWithDetails: (d) => _entfernenErsteVorkommen(d.data.karte),
              builder: (context, kandidaten, _) => _Rahmen(
                hervorgehoben: kandidaten.isNotEmpty,
                child: gefiltert.isEmpty
                    ? const Center(child: Text('Keine Karten in dieser Kategorie.'))
                    : _KartenCoverflow(
                        key: ValueKey(_filter),
                        karten: gefiltert,
                        viewportFraction: _kViewportFraction,
                        kartenBauen: _poolKarteBauen,
                        onSeiteGeaendert: (i) => setState(() => _poolSeite = i),
                      ),
              ),
            ),
          ),
          if (gefiltert.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: FilledButton.tonalIcon(
                onPressed: _kannHinzufuegen(gefiltert[poolSeite])
                    ? () => _hinzufuegen(gefiltert[poolSeite])
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Zum Deck hinzufügen'),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              TextButton(onPressed: _leeren, child: const Text('Leeren')),
              TextButton(onPressed: _zufaelligFuellen, child: const Text('Zufällig füllen')),
              const Spacer(),
              FilledButton(
                onPressed: fehler.isEmpty ? _speichern : null,
                child: const Text('Speichern'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rahmen extends StatelessWidget {
  final bool hervorgehoben;
  final Widget child;
  const _Rahmen({required this.hervorgehoben, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: Border.all(
        color: hervorgehoben ? Colors.amber : Colors.transparent,
        width: 3,
      ),
    ),
    child: child,
  );
}

class _Ueberschrift extends StatelessWidget {
  final String text;
  const _Ueberschrift(this.text);

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
  );
}

class _StatusLeiste extends StatelessWidget {
  final int gesamt;
  final int evil;
  final List<String> fehler;

  const _StatusLeiste({required this.gesamt, required this.evil, required this.fehler});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: fehler.isEmpty
        ? Colors.green.withValues(alpha: 0.12)
        : Colors.orange.withValues(alpha: 0.12),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$gesamt/$kDeckGroesse Karten · $evil/$kEvilAnzahlImDeck Evil',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        if (fehler.isEmpty)
          const Text('Deck ist gültig.', style: TextStyle(color: Colors.green))
        else
          for (final f in fehler) Text(f, style: const TextStyle(color: Colors.deepOrange)),
      ],
    ),
  );
}

class _KategorieFilter extends StatelessWidget {
  final Kategorie? aktuell;
  final void Function(Kategorie?) onGewaehlt;

  const _KategorieFilter({required this.aktuell, required this.onGewaehlt});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        _chip(context, null, 'Alle'),
        for (final k in Kategorie.values)
          if (k != Kategorie.start) _chip(context, k, k.name[0].toUpperCase() + k.name.substring(1)),
      ],
    ),
  );

  Widget _chip(BuildContext context, Kategorie? kategorie, String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: ChoiceChip(
      label: Text(label),
      selected: aktuell == kategorie,
      onSelected: (_) => onGewaehlt(kategorie),
    ),
  );
}

/// CoverFlow-Karussell: die mittlere Karte in voller Größe, Nachbarn kleiner
/// und blasser — wischbar wie bei Apples klassischem Coverflow, statt einer
/// starren Liste. [kartenBauen] liefert den (ggf. ziehbaren) Karteninhalt.
class _KartenCoverflow extends StatefulWidget {
  final List<Karte> karten;
  final Widget Function(Karte) kartenBauen;
  final double viewportFraction;
  final ValueChanged<int>? onSeiteGeaendert;

  const _KartenCoverflow({
    super.key,
    required this.karten,
    required this.kartenBauen,
    required this.viewportFraction,
    this.onSeiteGeaendert,
  });

  @override
  State<_KartenCoverflow> createState() => _KartenCoverflowState();
}

class _KartenCoverflowState extends State<_KartenCoverflow> {
  late final PageController _controller = PageController(viewportFraction: widget.viewportFraction);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView.builder(
    controller: _controller,
    itemCount: widget.karten.length,
    onPageChanged: widget.onSeiteGeaendert,
    itemBuilder: (context, index) => AnimatedBuilder(
      animation: _controller,
      builder: (context, kind) {
        final aktuelleSeite =
            _controller.hasClients && _controller.position.haveDimensions
            ? (_controller.page ?? index.toDouble())
            : index.toDouble();
        final abstand = (aktuelleSeite - index).abs().clamp(0.0, 1.0);
        return Center(
          child: Opacity(
            opacity: 1 - abstand * 0.55,
            child: Transform.scale(scale: 1 - abstand * 0.35, child: kind),
          ),
        );
      },
      child: widget.kartenBauen(widget.karten[index]),
    ),
  );
}

class _Zaehler extends StatelessWidget {
  final int anzahl;
  final int max;

  const _Zaehler({required this.anzahl, required this.max});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: anzahl > 0 ? Colors.blue.shade700 : Colors.black54,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white, width: 1),
    ),
    child: Text(
      '$anzahl/$max',
      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}

/// Sortierkriterium für den Pool. [wertFuer] liefert `null` für die
/// Standardsortierung (Kategorie, dann Name) — die Ausgangsliste ist schon
/// so sortiert, dann wird gar nicht erst neu verglichen —, sonst eine Zahl,
/// bei der der größte Wert zuerst steht.
///
/// "Stärke" (Marginal-Contribution-Analyse aus `tools/simulator/bin/
/// kartenstaerke.dart`) fehlt hier bewusst — dieser Wert wird bisher nur in
/// der Simulation berechnet, nicht als Kartenfeld in der App ausgeliefert,
/// bräuchte also eine eigene Daten-Pipeline statt nur eine Sortierfunktion.
/// Seltenheit dagegen steht schon auf jeder Karte (auch schon farblich am
/// Rahmen zu erkennen, [seltenheitsFarbe]) und kostet hier nur eine Zeile.
enum _Sortierung {
  kategorie('Kategorie'),
  seltenheit('Nach Seltenheit'),
  v1('Nach V1'),
  v2('Nach V2'),
  s1('Nach S1'),
  s2('Nach S2'),
  hg1('Nach HG1'),
  hg2('Nach HG2');

  final String label;
  const _Sortierung(this.label);

  int? wertFuer(Karte karte) => switch (this) {
    _Sortierung.kategorie => null,
    _Sortierung.seltenheit => _seltenheitSortWert(karte.seltenheit),
    _Sortierung.v1 => _slotSortWert(karte.slots[0]),
    _Sortierung.v2 => _slotSortWert(karte.slots[1]),
    _Sortierung.s1 => _slotSortWert(karte.slots[2]),
    _Sortierung.s2 => _slotSortWert(karte.slots[3]),
    _Sortierung.hg1 => _slotSortWert(karte.slots[4]),
    _Sortierung.hg2 => _slotSortWert(karte.slots[5]),
  };
}

/// Einheitliche Vergleichsgröße für ein Slot-Symbol: ein Loch gilt als das
/// wertvollste Symbol (deckt beliebige Werte darunter auf), danach absteigend
/// nach Farbwert, ein schwarzer Wert zuletzt (zählt immer negativ).
int _slotSortWert(SlotSymbol symbol) => switch (symbol) {
  Loch() => 3,
  Farbig(wert: final w) => w,
  Schwarz() => -1,
};

/// Dieselbe Rangfolge wie [seltenheitsFarbe]: Gold > Violett > Blau > Grau.
int _seltenheitSortWert(String seltenheit) => switch (seltenheit) {
  'einzigartig' => 3,
  'episch' => 2,
  'selten' => 1,
  _ => 0, // haeufig
};

/// Kompaktes Sortiermenü — ein einzelnes Icon statt einer Zeile voller
/// Optionen, damit auf kleinen Bildschirmen kein zusätzlicher Platz für
/// Sortierkriterien reserviert werden muss.
class _SortierMenu extends StatelessWidget {
  final _Sortierung aktuell;
  final ValueChanged<_Sortierung> onGewaehlt;

  const _SortierMenu({required this.aktuell, required this.onGewaehlt});

  @override
  Widget build(BuildContext context) => PopupMenuButton<_Sortierung>(
    initialValue: aktuell,
    onSelected: onGewaehlt,
    icon: const Icon(Icons.sort),
    tooltip: 'Sortieren',
    itemBuilder: (context) => [
      for (final s in _Sortierung.values)
        CheckedPopupMenuItem(value: s, checked: s == aktuell, child: Text(s.label)),
    ],
  );
}
