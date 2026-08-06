import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/start_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory((await getApplicationDocumentsDirectory()).path),
  );
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
