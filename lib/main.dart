import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/new_game_screen.dart';
import 'state/game_controller.dart';

void main() {
  runApp(const PocketManagerApp());
}

class PocketManagerApp extends StatefulWidget {
  const PocketManagerApp({super.key});

  @override
  State<PocketManagerApp> createState() => _PocketManagerAppState();
}

class _PocketManagerAppState extends State<PocketManagerApp> {
  final GameController controller = GameController();

  @override
  void initState() {
    super.initState();
    controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          switch (controller.phase) {
            case AppPhase.loading:
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            case AppPhase.needsNewGame:
              return NewGameScreen(controller: controller);
            case AppPhase.ready:
              return HomeShell(controller: controller);
          }
        },
      ),
    );
  }
}
