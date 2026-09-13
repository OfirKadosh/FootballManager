import 'package:flutter/material.dart';

import '../state/game_controller.dart';
import 'dashboard_screen.dart';
import 'inbox_screen.dart';
import 'squad_screen.dart';
import 'table_screen.dart';
import 'transfer_market_screen.dart';

/// The main mobile layout container: a bottom nav bar connecting
/// Dashboard / Squad & Tactics / Transfers & Scouting / League
/// Standings, plus Inbox & News (from the original Phase 2 tab list —
/// kept since it already holds real functionality: season objectives
/// and the match/transfer/promotion news feed. Drop it from
/// `_screens`/`_navItems` below if you want exactly the 4 named tabs).
class HomeShell extends StatefulWidget {
  final GameController controller;

  const HomeShell({super.key, required this.controller});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final club = controller.save!.managedClub;
    final unreadCount = controller.save!.inbox.where((n) => !n.read).length;

    // IndexedStack keeps each tab's scroll position / state alive when
    // switching, instead of rebuilding the screen from scratch.
    final screens = <Widget>[
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
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // keeps all labels visible with 5 tabs
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Squad',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Transfers',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Standings',
          ),
          BottomNavigationBarItem(
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
