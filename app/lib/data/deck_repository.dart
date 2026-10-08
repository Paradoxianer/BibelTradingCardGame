import 'package:btcg_engine/engine.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Ein benanntes, gespeichertes Deck: nur die Kartenliste, keine
/// abgeleiteten Daten (Gültigkeit etc. berechnet [pruefeDeck] bei Bedarf).
class DeckEintrag {
  final String id;
  final String name;
  final List<String> kartenIds;

  const DeckEintrag({required this.id, required this.name, required this.kartenIds});

  DeckEintrag kopieMit({String? name, List<String>? kartenIds}) =>
      DeckEintrag(id: id, name: name ?? this.name, kartenIds: kartenIds ?? this.kartenIds);

  Map<String, dynamic> _zuJson() => {'id': id, 'name': name, 'kartenIds': kartenIds};

  static DeckEintrag _ausJson(Map<dynamic, dynamic> json) => DeckEintrag(
    id: json['id'] as String,
    name: json['name'] as String,
    kartenIds: (json['kartenIds'] as List<dynamic>).cast<String>(),
  );
}

/// Persistiert mehrere benannte Decks + welches davon aktiv ist (Issue #18,
/// Folge auf #17 — dort gab es nur ein Deck unter einem festen Schlüssel).
/// Direkt über [HydratedBloc.storage], wie [GameBloc] es für den Spielstand
/// tut (spiel_persistenz.dart).
///
/// [alle] garantiert mindestens ein Deck: existiert noch keines, wird beim
/// ersten Zugriff entweder das alte Einzel-Deck (Vorgänger-Schema) als
/// "Deck 1" übernommen oder ein neues, leeres "Deck 1" angelegt — die UI
/// muss den Fall "keine Decks vorhanden" dadurch nirgends behandeln.
class DeckRepository {
  static const String _schluesselDecks = 'EigeneDecks';
  static const String _schluesselAktiv = 'AktivesDeckId';
  static const String _schluesselAlt = 'EigenesDeck'; // Vorgänger-Schema (#17)

  static int _idZaehler = 0;
  static String _neueId() => '${DateTime.now().microsecondsSinceEpoch}-${_idZaehler++}';

  static List<DeckEintrag> alle() {
    _sicherstellen();
    final roh = HydratedBloc.storage.read(_schluesselDecks) as List<dynamic>;
    return [for (final e in roh) DeckEintrag._ausJson(e as Map<dynamic, dynamic>)];
  }

  static String? aktiveId() {
    _sicherstellen();
    return HydratedBloc.storage.read(_schluesselAktiv) as String?;
  }

  /// Das aktive Deck, oder das erste vorhandene, falls die aktive ID auf
  /// kein (mehr) existierendes Deck zeigt.
  static DeckEintrag aktiv() {
    final decks = alle();
    final id = aktiveId();
    for (final d in decks) {
      if (d.id == id) return d;
    }
    return decks.first;
  }

  static Future<void> setzeAktiv(String id) => HydratedBloc.storage.write(_schluesselAktiv, id);

  static Future<String> anlegen(String name) async {
    final id = _neueId();
    final neu = [...alle(), DeckEintrag(id: id, name: name, kartenIds: const [])];
    await _schreibeAlle(neu);
    await setzeAktiv(id);
    return id;
  }

  static Future<void> umbenennen(String id, String neuerName) async {
    final neu = [for (final d in alle()) d.id == id ? d.kopieMit(name: neuerName) : d];
    await _schreibeAlle(neu);
  }

  /// Löscht ein Deck — außer es ist das letzte verbliebene: mindestens ein
  /// Deck bleibt immer erhalten. War es das aktive, wird das nächstbeste
  /// aktiv.
  static Future<void> loeschen(String id) async {
    final decks = alle();
    if (decks.length <= 1) return;
    final neu = decks.where((d) => d.id != id).toList();
    await _schreibeAlle(neu);
    if (aktiveId() == id) await setzeAktiv(neu.first.id);
  }

  static Future<void> speichereKarten(String id, List<Karte> karten) async {
    final neu = [
      for (final d in alle()) d.id == id ? d.kopieMit(kartenIds: [for (final k in karten) k.id]) : d,
    ];
    await _schreibeAlle(neu);
  }

  /// Löst die gespeicherten IDs eines Decks gegen [alleKarten] auf. IDs, die
  /// es im aktuellen Kartenset nicht mehr gibt (Datensatz geändert), fallen
  /// stillschweigend weg — wie beim Laden eines gespeicherten Spiels
  /// (parseGespeichertePartie in spiel_persistenz.dart).
  static List<Karte> ladeKarten(DeckEintrag deck, List<Karte> alleKarten) {
    final karteNachId = {for (final k in alleKarten) k.id: k};
    return [
      for (final id in deck.kartenIds)
        if (karteNachId[id] != null) karteNachId[id]!,
    ];
  }

  static Future<void> _schreibeAlle(List<DeckEintrag> decks) =>
      HydratedBloc.storage.write(_schluesselDecks, [for (final d in decks) d._zuJson()]);

  static void _sicherstellen() {
    if (HydratedBloc.storage.read(_schluesselDecks) != null) return;
    final altesDeck = HydratedBloc.storage.read(_schluesselAlt) as List<dynamic>?;
    final id = _neueId();
    final eintrag = DeckEintrag(
      id: id,
      name: 'Deck 1',
      kartenIds: altesDeck?.cast<String>() ?? const [],
    );
    HydratedBloc.storage.write(_schluesselDecks, [eintrag._zuJson()]);
    HydratedBloc.storage.write(_schluesselAktiv, id);
    if (altesDeck != null) HydratedBloc.storage.delete(_schluesselAlt);
  }
}
