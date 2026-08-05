import 'karte.dart';
import 'rng.dart';
import 'spieler.dart';

/// Phase innerhalb des Zugs des aktiven Spielers (REGELWERK §5). `wertung`
/// und `nachziehen` sind keine eigenen Phasen, weil sie automatisch ablaufen
/// und keine Spielerentscheidung erfordern (ARCHITEKTUR §2).
enum ZugPhase {
  bauen,
  evilSpielen,
  reaktion, // nur aktiv, wenn eine Evil-Karte gerade unbeantwortet ist
}

/// Konfigurierbare Regelvarianten für die Simulation (Phase 1b). Alle
/// D-Punkte sind laut ÜBERGABE.md entschieden — einzige offene Zahlenwert-
/// Variante ist D5 (REGELWERK §7).
class RegelConfig {
  final bool startspielerZiehtNurVier;

  const RegelConfig({this.startspielerZiehtNurVier = false});
}

class GameState {
  final List<Spieler> spieler;
  final int aktiverIndex;
  final ZugPhase phase;
  final int rundeNummer; // 1-basiert; volle Zyklen aller Spieler
  final int zugNummer; // 1-basiert; Gesamtzahl gespielter Einzelzüge
  final Set<String> evilEmpfangenDieseRunde; // Spieler-IDs
  final String? pendingEvilOpferId; // Spieler, dessen Evil-Angriff auf Reaktion wartet
  final int? pendingEvilFeldIndex;
  final Karte? pendingEvilKarte;
  final SeedableRng rng;
  final RegelConfig config;
  final String? gewinnerId;

  const GameState({
    required this.spieler,
    required this.aktiverIndex,
    required this.rng,
    this.phase = ZugPhase.bauen,
    this.rundeNummer = 1,
    this.zugNummer = 1,
    this.evilEmpfangenDieseRunde = const {},
    this.pendingEvilOpferId,
    this.pendingEvilFeldIndex,
    this.pendingEvilKarte,
    this.config = const RegelConfig(),
    this.gewinnerId,
  });

  Spieler get aktiverSpieler => spieler[aktiverIndex];

  bool get spielLaeuft => gewinnerId == null;

  int spielerIndexVon(String id) => spieler.indexWhere((s) => s.id == id);

  GameState copyWith({
    List<Spieler>? spieler,
    int? aktiverIndex,
    ZugPhase? phase,
    int? rundeNummer,
    int? zugNummer,
    Set<String>? evilEmpfangenDieseRunde,
    Object? pendingEvilOpferId = _unset,
    Object? pendingEvilFeldIndex = _unset,
    Object? pendingEvilKarte = _unset,
    SeedableRng? rng,
    RegelConfig? config,
    Object? gewinnerId = _unset,
  }) => GameState(
    spieler: spieler ?? this.spieler,
    aktiverIndex: aktiverIndex ?? this.aktiverIndex,
    phase: phase ?? this.phase,
    rundeNummer: rundeNummer ?? this.rundeNummer,
    zugNummer: zugNummer ?? this.zugNummer,
    evilEmpfangenDieseRunde:
        evilEmpfangenDieseRunde ?? this.evilEmpfangenDieseRunde,
    pendingEvilOpferId: pendingEvilOpferId == _unset
        ? this.pendingEvilOpferId
        : pendingEvilOpferId as String?,
    pendingEvilFeldIndex: pendingEvilFeldIndex == _unset
        ? this.pendingEvilFeldIndex
        : pendingEvilFeldIndex as int?,
    pendingEvilKarte: pendingEvilKarte == _unset
        ? this.pendingEvilKarte
        : pendingEvilKarte as Karte?,
    rng: rng ?? this.rng,
    config: config ?? this.config,
    gewinnerId: gewinnerId == _unset ? this.gewinnerId : gewinnerId as String?,
  );

  Spieler spielerMitId(String id) => spieler[spielerIndexVon(id)];

  GameState mitSpieler(Spieler neuerSpieler) => copyWith(
    spieler: [
      for (final s in spieler) s.id == neuerSpieler.id ? neuerSpieler : s,
    ],
  );
}

const Object _unset = Object();
