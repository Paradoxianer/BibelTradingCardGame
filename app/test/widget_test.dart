import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'package:btcg_app/main.dart';

import 'test_storage.dart';

/// rootBundle.loadString() ist echte Async-I/O und braucht echte Wall-Clock-
/// Zeit, die die Fake-Async-Zone von testWidgets nicht von selbst voran-
/// schreiten lässt. Außerdem hat der CircularProgressIndicator im
/// FutureBuilder eine endlose Animation, die pumpAndSettle() für immer
/// blockieren würde — deshalb hier gezielt außerhalb davon abwarten und mit
/// pump() statt pumpAndSettle() weitermachen.
Future<void> _kartendatenAbwarten(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump();
}

void main() {
  setUp(() {
    HydratedBloc.storage = SpeicherImArbeitsspeicher();
  });

  testWidgets('Onboarding zeigt die erste Seite, dann Startscreen nach Überspringen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BtcgApp());
    await tester.pump();

    expect(find.text('Willkommen bei BibelTradingCardGame'), findsOneWidget);
    expect(find.text('Überspringen'), findsOneWidget);

    await tester.tap(find.text('Überspringen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await _kartendatenAbwarten(tester);

    expect(find.text('BibelTradingCardGame'), findsOneWidget);
    expect(find.textContaining('Karten geladen'), findsOneWidget);
    expect(find.text('Neues Hotseat-Spiel (2 Spieler)'), findsOneWidget);
  });

  testWidgets('Onboarding: "Weiter" blättert bis zur letzten Seite', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BtcgApp());
    await tester.pump();

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Bereit?'), findsOneWidget);
    expect(find.text('Los geht\'s'), findsOneWidget);
  });

  testWidgets('Hilfe-Button auf dem Startscreen öffnet das Onboarding erneut', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BtcgApp());
    await tester.pump();
    await tester.tap(find.text('Überspringen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await _kartendatenAbwarten(tester);

    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();

    expect(find.text('Willkommen bei BibelTradingCardGame'), findsOneWidget);
  });
}
