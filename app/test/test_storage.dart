import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Einfaches In-Memory-[Storage] für Tests. `main()` läuft in Tests nicht,
/// also wird `HydratedBloc.storage` nie über die echte Hive-basierte
/// [HydratedStorage] gesetzt — ohne dieses Test-Double würde jeder Zugriff
/// auf [HydratedBloc.storage] mit `StorageNotFound` abstürzen.
class SpeicherImArbeitsspeicher implements Storage {
  final Map<String, dynamic> _daten = {};

  @override
  dynamic read(String key) => _daten[key];

  @override
  Future<void> write(String key, dynamic value) async => _daten[key] = value;

  @override
  Future<void> delete(String key) async => _daten.remove(key);

  @override
  Future<void> clear() async => _daten.clear();

  @override
  Future<void> close() async {}
}
