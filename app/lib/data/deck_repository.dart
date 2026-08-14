import 'package:btcg_engine/engine.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Persistiert das eigene, selbst zusammengestellte Deck als Liste von
/// Karten-IDs (Wiederholungen erlaubt) — direkt über [HydratedBloc.storage],
/// wie [GameBloc] es für den Spielstand tut (spiel_persistenz.dart). Vorerst
/// genau ein Deck pro Gerät (Issue #17 nennt mehrere Decks als Ausblick).
class DeckRepository {
  static const String _schluessel = 'EigenesDeck';

  static bool vorhanden() => HydratedBloc.storage.read(_schluessel) != null;

  static Future<void> speichere(List<Karte> deck) =>
      HydratedBloc.storage.write(_schluessel, [for (final k in deck) k.id]);

  static Future<void> loesche() => HydratedBloc.storage.delete(_schluessel);

  /// Löst die gespeicherten IDs gegen [alleKarten] auf. IDs, die es im
  /// aktuellen Kartenset nicht mehr gibt (Datensatz geändert), fallen
  /// stillschweigend weg — wie beim Laden eines gespeicherten Spiels
  /// (parseGespeichertePartie in spiel_persistenz.dart).
  static List<Karte> lade(List<Karte> alleKarten) {
    final ids = HydratedBloc.storage.read(_schluessel) as List<dynamic>?;
    if (ids == null) return const [];
    final karteNachId = {for (final k in alleKarten) k.id: k};
    return [
      for (final id in ids)
        if (karteNachId[id as String] != null) karteNachId[id]!,
    ];
  }
}
