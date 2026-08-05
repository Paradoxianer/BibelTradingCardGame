import 'package:sheet_import/sheet_import.dart';
import 'package:test/test.dart';

Map<String, dynamic> _rohKarte({
  String cardId = 'RG0101',
  String? name = 'Testkarte',
  List<String> slots = const ['x', 'x', '1', '0', '1', '0'],
  num rare = 50,
}) => {
  'card_id': cardId,
  'name': name,
  'bible_vers': 'Philipper 1,19',
  'bible_text': 'Ein Testvers',
  'V1': slots[0],
  'V2': slots[1],
  'S1': slots[2],
  'S2': slots[3],
  'HG1': slots[4],
  'HG2': slots[5],
  'strongness': 12,
  'rare': rare,
  'effects': ' ',
  'notes': null,
  'picture_link': 'https://example.org/placeholder.png',
};

void main() {
  group('sheet_import', () {
    test('konvertiert eine gültige Karte ins Zielformat', () {
      final roh = {
        'R_Gebet': {'RG0101': _rohKarte()},
      };
      final ergebnis = importiere(roh, set: 'BASE');
      expect(ergebnis.istGueltig, isTrue);
      final karte = ergebnis.tabs['R_Gebet']!.single;
      expect(karte['card_id'], 'RG0101');
      expect(karte['kategorie'], 'gebet');
      expect(karte['effekt'], isNull);
      expect(karte['V1'], 'x');
      expect(karte.containsKey('strongness'), isFalse);
      expect(karte.containsKey('rare'), isFalse);
    });

    test('lehnt fehlenden Namen ab (bekannter Datenfehler R_Glauben)', () {
      final roh = {
        'R_Glauben': {'RG1107': _rohKarte(cardId: 'RG1107', name: null)},
      };
      final ergebnis = importiere(roh, set: 'BASE');
      expect(ergebnis.istGueltig, isFalse);
      expect(ergebnis.fehler.single.kartenId, 'RG1107');
    });

    test('lehnt Sheet-Fehlerwerte ab (bekannter Datenfehler R_Gottesdienst)', () {
      final karte = _rohKarte(cardId: 'GD0102');
      karte['V1'] = '#NUM!';
      final roh = {
        'R_Gottesdienst': {'GD0102': karte},
      };
      final ergebnis = importiere(roh, set: 'BASE');
      expect(ergebnis.istGueltig, isFalse);
    });

    test('lehnt doppelte card_id ab', () {
      final roh = {
        'R_Gebet': {
          'a': _rohKarte(cardId: 'RG0101'),
          'b': _rohKarte(cardId: 'RG0101'),
        },
      };
      final ergebnis = importiere(roh, set: 'BASE');
      expect(ergebnis.istGueltig, isFalse);
    });

    test('EStart wird als Kategorie start mit int-Slot-Codes erkannt', () {
      final karte = _rohKarte(cardId: 'EStart', name: 'Alle sind Sünder', rare: 100);
      karte['V1'] = -1;
      karte['V2'] = -1;
      karte['S1'] = -1;
      karte['S2'] = -1;
      karte['HG1'] = -1;
      karte['HG2'] = -1;
      final roh = {
        'EvilDeck': {'EStart': karte},
      };
      final ergebnis = importiere(roh, set: 'BASE');
      expect(ergebnis.istGueltig, isTrue);
      final out = ergebnis.tabs['EvilDeck']!.single;
      expect(out['kategorie'], 'start');
      expect(out['seltenheit'], 'einzigartig');
      expect(out['V1'], '-1');
      expect(out['anzahlImDeckMax'], 1);
    });

    test('Evil-Karten außerhalb der bekannten Tabs bekommen Kategorie evil', () {
      final roh = {
        'EvilDeck': {'E1201': _rohKarte(cardId: 'E1201', rare: -33.3)},
      };
      final ergebnis = importiere(roh, set: 'BASE');
      expect(ergebnis.istGueltig, isTrue);
      final out = ergebnis.tabs['EvilDeck']!.single;
      expect(out['kategorie'], 'evil');
      expect(out['anzahlImDeckMax'], 1);
    });
  });
}
