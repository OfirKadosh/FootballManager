import 'package:flutter/material.dart';

import '../state/game_controller.dart';

class NewGameScreen extends StatelessWidget {
  final GameController controller;

  const NewGameScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final clubs = List.of(controller.availableClubs)
      ..sort((a, b) => b.reputation.compareTo(a.reputation));

    return Scaffold(
      appBar: AppBar(title: const Text('Pocket Manager')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Choose a club to manage for the 2026/27 season.',
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: clubs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final club = clubs[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(club.shortName)),
                  title: Text(club.name),
                  subtitle: Text(
                    'Reputation ${club.reputation} · Squad ${club.squad.length}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await controller.startNewGame(club.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
