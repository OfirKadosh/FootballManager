import 'package:flutter/material.dart';

import '../state/game_controller.dart';
import 'dashboard_screen.dart';
import 'inbox_screen.dart';
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
    final unreadCount = controller.save!.inbox.where((n) => !n.read).length;

    final screens = [
      DashboardScreen(controller: controller),
      SquadScreen(controller: controller),
      TransferMarketScreen(controller: controller),
      TableScreen(controller: controller),
      InboxScreen(controller: controller),
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
        destinations: [
          const NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          const NavigationDestination(icon: Icon(Icons.groups), label: 'Squad'),
          const NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Transfers'),
          const NavigationDestination(icon: Icon(Icons.leaderboard), label: 'Standings'),
          NavigationDestination(
            icon: unreadCount > 0
                ? Badge(label: Text('$unreadCount'), child: const Icon(Icons.inbox))
                : const Icon(Icons.inbox),
            label: 'Inbox',
          ),
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
