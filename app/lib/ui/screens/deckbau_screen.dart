import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';

import '../../data/deck_repository.dart';
import '../widgets/karten_widget.dart';

const double _kartenBreite = 110;

/// Eigenes Deck zusammenstellen (Issue #17): Auswahl aus dem ganzen
/// Kartenpool (Kartenbesitz gibt es noch nicht, siehe #10/#11 — bis dahin
/// steht der volle Bestand zur Verfügung), Live-Prüfung gegen REGELWERK §2
/// über [pruefeDeck], Speichern über [DeckRepository].
///
/// Zwei Karussells mit der echten Kartenansicht ([KartenWidget]) statt einer
/// Textliste: Slots, Werte und Löcher müssen beim Deckbau genauso sichtbar
/// sein wie im Spiel selbst — oben das gebaute Deck, unten der Kartenpool,
/// aus dem man antippend hinzufügt.
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

  void _hinzufuegen(Karte karte) => setState(() => _deck.add(karte));

  void _entfernen(int deckIndex) => setState(() => _deck.removeAt(deckIndex));

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

  @override
  Widget build(BuildContext context) {
    final fehler = pruefeDeck(_deck);
    final evilAnzahl = _deck.where((k) => k.kategorie == Kategorie.evil).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Eigenes Deck')),
      body: Column(
        children: [
          _StatusLeiste(gesamt: _deck.length, evil: evilAnzahl, fehler: fehler),
          const _Ueberschrift('Dein Deck — antippen entfernt eine Karte'),
          _DeckKarussell(key: const ValueKey('deck-karussell'), deck: _deck, onEntfernen: _entfernen),
          const Divider(height: 1),
          const _Ueberschrift('Kartenpool — antippen fügt eine Karte hinzu'),
          Expanded(
            child: _PoolKarussell(
              key: const ValueKey('pool-karussell'),
              karten: _auswaehlbar,
              anzahlImDeck: _anzahlImDeck,
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

/// Waagerechtes Karussell des aktuell gebauten Decks — jede Karte einzeln,
/// Duplikate also mehrfach, wie sie tatsächlich im Deck liegen.
class _DeckKarussell extends StatelessWidget {
  final List<Karte> deck;
  final void Function(int deckIndex) onEntfernen;

  const _DeckKarussell({super.key, required this.deck, required this.onEntfernen});

  @override
  Widget build(BuildContext context) {
    final hoehe = KartenWidget.hoeheFuer(_kartenBreite, KartenAnsicht.kompakt);
    return Container(
      height: hoehe + 12,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: deck.isEmpty
          ? const Center(child: Text('Noch keine Karten im Deck.'))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              itemCount: deck.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: () => onEntfernen(index),
                  child: KartenWidget.handkarte(deck[index], breite: _kartenBreite),
                ),
              ),
            ),
    );
  }
}

/// Waagerechtes Karussell des ganzen wählbaren Kartenpools, nach Kategorie
/// sortiert. Ein kleines Abzeichen zeigt, wie oft die Karte schon im Deck
/// steckt; ist das Limit erreicht, wird die Karte abgeblendet.
class _PoolKarussell extends StatelessWidget {
  final List<Karte> karten;
  final int Function(Karte) anzahlImDeck;
  final void Function(Karte) onHinzufuegen;

  const _PoolKarussell({
    super.key,
    required this.karten,
    required this.anzahlImDeck,
    required this.onHinzufuegen,
  });

  @override
  Widget build(BuildContext context) => ListView.builder(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.all(6),
    itemCount: karten.length,
    itemBuilder: (context, index) {
      final karte = karten[index];
      final anzahl = anzahlImDeck(karte);
      final voll = anzahl >= karte.anzahlImDeckMax;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: GestureDetector(
          onTap: voll ? null : () => onHinzufuegen(karte),
          child: Opacity(
            opacity: voll ? 0.4 : 1.0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                KartenWidget.handkarte(karte, breite: _kartenBreite),
                Positioned(
                  top: -4,
                  right: -4,
                  child: _Zaehler(anzahl: anzahl, max: karte.anzahlImDeckMax),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _Zaehler extends StatelessWidget {
  final int anzahl;
  final int max;

  const _Zaehler({required this.anzahl, required this.max});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: anzahl > 0 ? Colors.blue.shade700 : Colors.black54,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white, width: 1),
    ),
    child: Text(
      '$anzahl/$max',
      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}
