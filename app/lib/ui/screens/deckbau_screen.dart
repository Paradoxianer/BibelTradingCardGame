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

  List<Karte> get _gefiltert =>
      _filter == null ? _auswaehlbar : _auswaehlbar.where((k) => k.kategorie == _filter).toList();

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

  Widget _deckKarteBauen(Karte karte, double breite) {
    final inhalt = KartenWidget.handkarte(karte, breite: breite, ansicht: KartenAnsicht.voll);
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

  Widget _poolKarteBauen(Karte karte, double breite) {
    final anzahl = _anzahlImDeck(karte);
    final kann = _kannHinzufuegen(karte);
    final inhalt = KartenWidget.handkarte(karte, breite: breite, ansicht: KartenAnsicht.voll);
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

  /// Kartenbreite und PageView-[viewportFraction] so, dass links und rechts
  /// der mittleren Karte echte Nachbarn hereinragen (Coverflow-Gefühl) —
  /// beides aus der verfügbaren Fläche errechnet statt fest verdrahtet,
  /// sonst verschwinden die Nachbarn auf breiten Bildschirmen komplett
  /// hinter dem Bildschirmrand.
  ({double breite, double viewportFraction}) _coverflowMasse(BoxConstraints grenzen) {
    final breite = ((grenzen.maxHeight - 20) / 1.5).clamp(110.0, 200.0);
    final viewportFraction = ((breite * 1.35) / grenzen.maxWidth).clamp(0.22, 0.6);
    return (breite: breite, viewportFraction: viewportFraction);
  }

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
                    : LayoutBuilder(
                        builder: (context, grenzen) {
                          final masse = _coverflowMasse(grenzen);
                          return _KartenCoverflow(
                            karten: _deck,
                            viewportFraction: masse.viewportFraction,
                            kartenBauen: (karte) => _deckKarteBauen(karte, masse.breite),
                            onSeiteGeaendert: (i) => setState(() => _deckSeite = i),
                          );
                        },
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
          _KategorieFilter(aktuell: _filter, onGewaehlt: _filterSetzen),
          Expanded(
            child: DragTarget<_Zug>(
              key: const ValueKey('pool-dragtarget'),
              onWillAcceptWithDetails: (d) => d.data.ausDeck,
              onAcceptWithDetails: (d) => _entfernenErsteVorkommen(d.data.karte),
              builder: (context, kandidaten, _) => _Rahmen(
                hervorgehoben: kandidaten.isNotEmpty,
                child: gefiltert.isEmpty
                    ? const Center(child: Text('Keine Karten in dieser Kategorie.'))
                    : LayoutBuilder(
                        builder: (context, grenzen) {
                          final masse = _coverflowMasse(grenzen);
                          return _KartenCoverflow(
                            key: ValueKey(_filter),
                            karten: gefiltert,
                            viewportFraction: masse.viewportFraction,
                            kartenBauen: (karte) => _poolKarteBauen(karte, masse.breite),
                            onSeiteGeaendert: (i) => setState(() => _poolSeite = i),
                          );
                        },
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
