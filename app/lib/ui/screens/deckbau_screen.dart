import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';

import '../../data/deck_repository.dart';
import '../widgets/karten_widget.dart';

/// Eigenes Deck zusammenstellen (Issue #17): Auswahl aus dem ganzen
/// Kartenpool (Kartenbesitz gibt es noch nicht, siehe #10/#11 — bis dahin
/// steht der volle Bestand zur Verfügung), Live-Prüfung gegen REGELWERK §2
/// über [pruefeDeck], Speichern über [DeckRepository].
///
/// Bewusst kein Scroll-Streifen über alle ~106 Karten — das fühlt sich nicht
/// wie ein Kartenstapel an, den man durchblättert, sondern wie eine Tabelle.
/// Stattdessen: das Deck als **echter physischer Stapel** ([StapelWidget],
/// dieselbe Darstellung wie im Spiel, in [KartenAnsicht.voll]), und der Pool
/// als Ein-Karte-nach-der-anderen-Browser zum Durchblättern — beide per
/// Drag&Drop verbunden, genau wie Handkarte-auf-Feld im eigentlichen Spiel.
class DeckbauScreen extends StatefulWidget {
  final Kartenset kartenset;

  const DeckbauScreen({super.key, required this.kartenset});

  @override
  State<DeckbauScreen> createState() => _DeckbauScreenState();
}

class _DeckbauScreenState extends State<DeckbauScreen> {
  late List<Karte> _deck;
  late final List<Karte> _auswaehlbar;

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

  int _anzahlImDeck(Karte karte) => _deck.where((k) => k.id == karte.id).length;

  bool _kannHinzufuegen(Karte karte) => _anzahlImDeck(karte) < karte.anzahlImDeckMax;

  void _hinzufuegen(Karte karte) {
    if (!_kannHinzufuegen(karte)) return;
    setState(() => _deck.add(karte));
  }

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

  void _deckDurchblaettern() {
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Dein Deck (${_deck.length})', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SizedBox(
                  height: KartenWidget.hoeheFuer(180, KartenAnsicht.voll) + 24,
                  child: _deck.isEmpty
                      ? const Center(child: Text('Noch keine Karten im Deck.'))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _deck.length,
                          itemBuilder: (context, index) {
                            final karte = _deck[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  KartenWidget.handkarte(karte, breite: 180, ansicht: KartenAnsicht.voll),
                                  Positioned(
                                    top: -8,
                                    right: -8,
                                    child: _EntfernenKnopf(
                                      onTap: () {
                                        setState(() => _deck.removeAt(index));
                                        setDialogState(() {});
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Schließen')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fehler = pruefeDeck(_deck);
    final evilAnzahl = _deck.where((k) => k.kategorie == Kategorie.evil).length;
    // Zuletzt hinzugefügte Karte obenauf, wie beim Bauen im echten Spiel
    // (REGELWERK D3: neue Karte kommt immer obenauf).
    final deckFeld = Spielfeld([for (final k in _deck.reversed) Kartenlage(k)]);

    return Scaffold(
      appBar: AppBar(title: const Text('Eigenes Deck')),
      body: Column(
        children: [
          _StatusLeiste(gesamt: _deck.length, evil: evilAnzahl, fehler: fehler),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: GestureDetector(
              onTap: _deck.isEmpty ? null : _deckDurchblaettern,
              child: DragTarget<Karte>(
                onWillAcceptWithDetails: (d) => _kannHinzufuegen(d.data),
                onAcceptWithDetails: (d) => _hinzufuegen(d.data),
                builder: (context, kandidaten, _) => Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: kandidaten.isNotEmpty ? Colors.amber : Colors.transparent,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: StapelWidget(feld: deckFeld, breite: 150, ansicht: KartenAnsicht.voll),
                ),
              ),
            ),
          ),
          Text(
            _deck.isEmpty
                ? 'Dein Deck — Karte hierher ziehen'
                : 'Dein Deck — antippen zum Durchblättern, Karte hierher ziehen',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Divider(height: 16),
          Expanded(
            child: _PoolBrowser(
              karten: _auswaehlbar,
              anzahlImDeck: _anzahlImDeck,
              kannHinzufuegen: _kannHinzufuegen,
              onHinzufuegen: _hinzufuegen,
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

class _EntfernenKnopf extends StatelessWidget {
  final VoidCallback onTap;
  const _EntfernenKnopf({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: const CircleAvatar(
      radius: 14,
      backgroundColor: Colors.black87,
      child: Icon(Icons.close, size: 16, color: Colors.white),
    ),
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

/// Ein Kartenpool zum Durchblättern statt Durchscrollen: eine Kategorie
/// filtern, dann eine Karte nach der anderen ansehen ([PageView], mit
/// wischbarer Stapel-Optik) und per Drag auf den Deck-Stapel ziehen.
class _PoolBrowser extends StatefulWidget {
  final List<Karte> karten;
  final int Function(Karte) anzahlImDeck;
  final bool Function(Karte) kannHinzufuegen;
  final void Function(Karte) onHinzufuegen;

  const _PoolBrowser({
    required this.karten,
    required this.anzahlImDeck,
    required this.kannHinzufuegen,
    required this.onHinzufuegen,
  });

  @override
  State<_PoolBrowser> createState() => _PoolBrowserState();
}

class _PoolBrowserState extends State<_PoolBrowser> {
  Kategorie? _filter;
  late PageController _controller;
  int _seite = 0;

  List<Karte> get _gefiltert =>
      _filter == null ? widget.karten : widget.karten.where((k) => k.kategorie == _filter).toList();

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _filterSetzen(Kategorie? kategorie) {
    setState(() {
      _filter = kategorie;
      _seite = 0;
    });
    _controller = PageController();
  }

  @override
  Widget build(BuildContext context) {
    final karten = _gefiltert;
    return Column(
      children: [
        _KategorieFilter(aktuell: _filter, onGewaehlt: _filterSetzen),
        Expanded(
          child: karten.isEmpty
              ? const Center(child: Text('Keine Karten in dieser Kategorie.'))
              : LayoutBuilder(
                  builder: (context, grenzen) {
                    // Feste Zuschläge abziehen, bevor aus der Höhe eine
                    // Kartenbreite (Verhältnis 1:1.5, KartenAnsicht.voll)
                    // errechnet wird: Stapel-Optik-Rand (16) + Abstand zum
                    // Knopf (4) + Knopfhöhe (~48).
                    final breite = ((grenzen.maxHeight - 68) / 1.5).clamp(120.0, 240.0);
                    return PageView.builder(
                      key: ValueKey(_filter),
                      controller: _controller,
                      itemCount: karten.length,
                      onPageChanged: (i) => setState(() => _seite = i),
                      itemBuilder: (context, index) {
                        final karte = karten[index];
                        return Center(
                          child: SingleChildScrollView(
                            child: _GrosseKarteMitStapelOptik(
                              karte: karte,
                              breite: breite,
                              anzahl: widget.anzahlImDeck(karte),
                              kannHinzufuegen: widget.kannHinzufuegen(karte),
                              onHinzufuegen: () => widget.onHinzufuegen(karte),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _seite > 0
                    ? () => _controller.previousPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      )
                    : null,
              ),
              Text(karten.isEmpty ? '0 / 0' : '${_seite + 1} / ${karten.length}'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _seite < karten.length - 1
                    ? () => _controller.nextPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
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

/// Die aktuell durchblätterte Karte in [KartenAnsicht.voll], mit zwei
/// versetzten, angedeuteten Karten dahinter — die Stapel-Optik, die eine
/// simple Scroll-Liste nicht vermitteln kann. Ziehbar auf den Deck-Stapel;
/// der Knopf darunter ist die alternative Bedienung ohne Drag.
class _GrosseKarteMitStapelOptik extends StatelessWidget {
  final Karte karte;
  final double breite;
  final int anzahl;
  final bool kannHinzufuegen;
  final VoidCallback onHinzufuegen;

  const _GrosseKarteMitStapelOptik({
    required this.karte,
    required this.breite,
    required this.anzahl,
    required this.kannHinzufuegen,
    required this.onHinzufuegen,
  });

  @override
  Widget build(BuildContext context) {
    final hoehe = KartenWidget.hoeheFuer(breite, KartenAnsicht.voll);
    final karteWidget = KartenWidget.handkarte(karte, breite: breite, ansicht: KartenAnsicht.voll);

    final vorschau = Opacity(
      opacity: kannHinzufuegen ? 1.0 : 0.45,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          karteWidget,
          Positioned(top: -8, right: -8, child: _Zaehler(anzahl: anzahl, max: karte.anzahlImDeckMax)),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: breite + 24,
          height: hoehe + 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: const Offset(9, 9),
                child: Transform.rotate(
                  angle: 0.07,
                  child: _StapelSchatten(breite: breite, hoehe: hoehe, farbe: Colors.indigo.shade200),
                ),
              ),
              Transform.translate(
                offset: const Offset(-7, 6),
                child: Transform.rotate(
                  angle: -0.05,
                  child: _StapelSchatten(breite: breite, hoehe: hoehe, farbe: Colors.indigo.shade100),
                ),
              ),
              kannHinzufuegen
                  ? Draggable<Karte>(
                      data: karte,
                      feedback: Material(color: Colors.transparent, child: karteWidget),
                      childWhenDragging: Opacity(opacity: 0.3, child: vorschau),
                      child: vorschau,
                    )
                  : vorschau,
            ],
          ),
        ),
        const SizedBox(height: 4),
        FilledButton.tonal(
          onPressed: kannHinzufuegen ? onHinzufuegen : null,
          child: const Text('Zum Deck hinzufügen'),
        ),
      ],
    );
  }
}

class _StapelSchatten extends StatelessWidget {
  final double breite;
  final double hoehe;
  final Color farbe;

  const _StapelSchatten({required this.breite, required this.hoehe, required this.farbe});

  @override
  Widget build(BuildContext context) => Container(
    width: breite,
    height: hoehe,
    decoration: BoxDecoration(color: farbe, borderRadius: BorderRadius.circular(breite / 14)),
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
