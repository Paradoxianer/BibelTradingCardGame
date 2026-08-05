import 'package:flutter_test/flutter_test.dart';

import 'package:btcg_app/main.dart';

void main() {
  testWidgets('Startscreen lädt Kartendaten und zeigt den Start-Button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BtcgApp());

    // rootBundle.loadString() ist echte Async-I/O und braucht echte
    // Wall-Clock-Zeit, die die Fake-Async-Zone von testWidgets nicht von
    // selbst voranschreiten lässt — deshalb hier explizit außerhalb davon
    // abwarten (klassische Falle bei FutureBuilder + Asset-Laden in Tests).
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();

    expect(find.text('BibelTradingCardGame'), findsOneWidget);
    expect(find.textContaining('Karten geladen'), findsOneWidget);
    expect(find.text('Neues Hotseat-Spiel (2 Spieler)'), findsOneWidget);
  });
}
