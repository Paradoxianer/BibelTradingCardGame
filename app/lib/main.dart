import 'package:flutter/material.dart';

import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/start_screen.dart';

void main() {
  runApp(const BtcgApp());
}

class BtcgApp extends StatelessWidget {
  const BtcgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BibelTradingCardGame',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
      home: Builder(
        builder: (context) => OnboardingScreen(
          onFertig: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StartScreen()),
          ),
        ),
      ),
    );
  }
}
