import 'package:btcg_app/data/deck_repository.dart';
import 'package:btcg_engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'test_storage.dart';

Karte _karte(String id) => Karte(
  id: id,
  cardId: id,
  name: id,
  vers: const Vers(stelle: 'X 1,1', text: ''),
  slots: ['0', '0', '0', '0', '0', '0'].map(SlotSymbol.parse).toList(),
  kategorie: Kategorie.gebet,
  seltenheit: 'haeufig',
  sofort: false,
  effekt: null,
  anzahlImDeckMax: 3,
  pictureLink: '',
);

void main() {
  setUp(() => HydratedBloc.storage = SpeicherImArbeitsspeicher());

  final alleKarten = [_karte('a'), _karte('b'), _karte('c')];

  test('alle() legt bei leerem Speicher automatisch ein leeres "Deck 1" an', () {
    final decks = DeckRepository.alle();
    expect(decks, hasLength(1));
    expect(decks.single.name, 'Deck 1');
    expect(decks.single.kartenIds, isEmpty);
    expect(DeckRepository.aktiveId(), decks.single.id);
  });

  test('altes Einzel-Deck-Schema wird beim ersten Zugriff als "Deck 1" übernommen', () async {
    await HydratedBloc.storage.write('EigenesDeck', ['a', 'b']);

    final decks = DeckRepository.alle();

    expect(decks, hasLength(1));
    expect(decks.single.name, 'Deck 1');
    expect(decks.single.kartenIds, ['a', 'b']);
    expect(HydratedBloc.storage.read('EigenesDeck'), isNull, reason: 'altes Schema wird aufgeräumt');
  });

  test('anlegen fügt ein neues Deck hinzu und setzt es aktiv', () async {
    final ersteId = DeckRepository.aktiv().id;

    final neueId = await DeckRepository.anlegen('Zweitdeck');

    expect(DeckRepository.alle(), hasLength(2));
    expect(DeckRepository.aktiveId(), neueId);
    expect(neueId, isNot(ersteId));
    expect(DeckRepository.aktiv().name, 'Zweitdeck');
  });

  test('speichereKarten und ladeKarten spielen zusammen', () async {
    final id = await DeckRepository.anlegen('Testdeck');
    await DeckRepository.speichereKarten(id, [alleKarten[0], alleKarten[1]]);

    final geladen = DeckRepository.ladeKarten(DeckRepository.aktiv(), alleKarten);

    expect(geladen.map((k) => k.id), ['a', 'b']);
  });

  test('umbenennen ändert nur den Namen, nicht die Karten', () async {
    final id = await DeckRepository.anlegen('Alter Name');
    await DeckRepository.speichereKarten(id, [alleKarten[0]]);

    await DeckRepository.umbenennen(id, 'Neuer Name');

    final eintrag = DeckRepository.alle().firstWhere((d) => d.id == id);
    expect(eintrag.name, 'Neuer Name');
    expect(eintrag.kartenIds, ['a']);
  });

  test('loeschen entfernt ein Deck und wählt bei Bedarf ein anderes als aktiv', () async {
    final zweiteId = await DeckRepository.anlegen('Zweitdeck');
    final ersteId = DeckRepository.alle().firstWhere((d) => d.id != zweiteId).id;

    await DeckRepository.loeschen(zweiteId);

    expect(DeckRepository.alle(), hasLength(1));
    expect(DeckRepository.aktiveId(), ersteId, reason: 'das gelöschte Deck war aktiv');
  });

  test('loeschen verweigert das letzte verbliebene Deck', () async {
    final einzigeId = DeckRepository.aktiv().id;

    await DeckRepository.loeschen(einzigeId);

    expect(DeckRepository.alle(), hasLength(1), reason: 'mindestens ein Deck bleibt immer erhalten');
    expect(DeckRepository.aktiveId(), einzigeId);
  });

  test('setzeAktiv wechselt das aktive Deck, ohne andere Decks zu verändern', () async {
    final zweiteId = await DeckRepository.anlegen('Zweitdeck');
    final ersteId = DeckRepository.alle().firstWhere((d) => d.id != zweiteId).id;

    await DeckRepository.setzeAktiv(ersteId);

    expect(DeckRepository.aktiveId(), ersteId);
    expect(DeckRepository.alle(), hasLength(2));
  });
}
