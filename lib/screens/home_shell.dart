import 'package:flutter/material.dart';

import '../state/game_controller.dart';
import 'dashboard_screen.dart';
import 'objectives_screen.dart';
import 'squad_screen.dart';
import 'table_screen.dart';
import 'transfer_market_screen.dart';

class HomeShell extends StatefulWidget {
  final GameController controller;

  const HomeShell({super.key, required this.controller});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final club = controller.save!.managedClub;

    final screens = [
      DashboardScreen(controller: controller),
      SquadScreen(controller: controller),
      TableScreen(controller: controller),
      TransferMarketScreen(controller: controller),
      ObjectivesScreen(controller: controller),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(club.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Abandon career',
            onPressed: () => _confirmAbandon(context),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.groups), label: 'Squad'),
          NavigationDestination(icon: Icon(Icons.leaderboard), label: 'Table'),
          NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Transfers'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'Objectives'),
        ],
      ),
    );
  }

  Future<void> _confirmAbandon(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandon career?'),
        content: const Text('This deletes your save and returns to club selection.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Abandon'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.controller.abandonCareer();
    }
  }
}
