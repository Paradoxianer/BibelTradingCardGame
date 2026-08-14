import 'package:btcg_engine/engine.dart';
import 'package:flutter/material.dart';

import '../../data/deck_repository.dart';

/// Eigenes Deck zusammenstellen (Issue #17): Auswahl aus dem ganzen
/// Kartenpool (Kartenbesitz gibt es noch nicht, siehe #10/#11 — bis dahin
/// steht der volle Bestand zur Verfügung), Live-Prüfung gegen REGELWERK §2
/// über [pruefeDeck], Speichern über [DeckRepository].
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

  void _entfernen(Karte karte) => setState(() {
    final index = _deck.indexWhere((k) => k.id == karte.id);
    if (index != -1) _deck.removeAt(index);
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

  @override
  Widget build(BuildContext context) {
    final fehler = pruefeDeck(_deck);
    final evilAnzahl = _deck.where((k) => k.kategorie == Kategorie.evil).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Eigenes Deck')),
      body: Column(
        children: [
          _StatusLeiste(
            gesamt: _deck.length,
            evil: evilAnzahl,
            fehler: fehler,
          ),
          Expanded(
            child: ListView(
              children: [
                for (var i = 0; i < _auswaehlbar.length; i++) ...[
                  if (i == 0 || _auswaehlbar[i].kategorie != _auswaehlbar[i - 1].kategorie)
                    _KategorieUeberschrift(kategorie: _auswaehlbar[i].kategorie),
                  _KartenZeile(
                    karte: _auswaehlbar[i],
                    anzahl: _anzahlImDeck(_auswaehlbar[i]),
                    onHinzufuegen: () => _hinzufuegen(_auswaehlbar[i]),
                    onEntfernen: () => _entfernen(_auswaehlbar[i]),
                  ),
                ],
              ],
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

class _KategorieUeberschrift extends StatelessWidget {
  final Kategorie kategorie;

  const _KategorieUeberschrift({required this.kategorie});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Text(
      kategorie.name[0].toUpperCase() + kategorie.name.substring(1),
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
  );
}

class _KartenZeile extends StatelessWidget {
  final Karte karte;
  final int anzahl;
  final VoidCallback onHinzufuegen;
  final VoidCallback onEntfernen;

  const _KartenZeile({
    required this.karte,
    required this.anzahl,
    required this.onHinzufuegen,
    required this.onEntfernen,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(karte.name),
    subtitle: Text(karte.vers.stelle),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: anzahl > 0 ? onEntfernen : null,
        ),
        SizedBox(
          width: 36,
          child: Text('$anzahl/${karte.anzahlImDeckMax}', textAlign: TextAlign.center),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: anzahl < karte.anzahlImDeckMax ? onHinzufuegen : null,
        ),
      ],
    ),
  );
}
