import 'package:btcg_engine/engine.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Lädt und parst `assets/kartensets/base.json` (Parsing selbst lebt in
/// btcg_engine, hier nur der Flutter-spezifische Asset-Zugriff).
///
/// Die Datei ist eine Kopie von `data/sets/base.json` (Source of Truth,
/// ARCHITEKTUR §1) — Flutters Web-Dev-Server (DWDS) liefert `..`-relative
/// Assets außerhalb von `assets/` nicht zuverlässig aus (funktioniert nur im
/// statischen `flutter build`), deshalb liegt hier eine synchronisierte
/// Kopie. Nach jedem `dart run tools/sheet_import` erneut nach
/// `app/assets/kartensets/base.json` kopieren.
Future<Kartenset> ladeKartenset({
  String assetPfad = 'assets/kartensets/base.json',
}) async {
  final text = await rootBundle.loadString(assetPfad);
  return parseKartenset(text);
}
