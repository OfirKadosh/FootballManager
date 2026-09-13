import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/new_game_screen.dart';
import 'state/game_controller.dart';

void main() {
  runApp(const PocketManagerApp());
}

/// Root widget. Owns the single [GameController] instance for the
/// whole app and loads the world/save state once, on startup, via
/// [GameController.init]. Every screen downstream reads from this
/// same controller instance — there's no separate per-screen state.
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
    // Loads the content pack (or an imported dataset later) and
    // checks disk for an existing career save. This is the "load the
    // new game state" step — everything the UI needs (countries,
    // leagues, clubs, tactics, inbox, etc.) is on `controller.save`
    // and `controller.pack` once this resolves.
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
      // ListenableBuilder re-runs this builder every time
      // controller.notifyListeners() fires — which covers loading
      // finishing, a new career starting, a matchday being played,
      // etc. No separate setState wiring needed per screen.
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
