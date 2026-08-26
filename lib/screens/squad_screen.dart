import 'package:flutter/material.dart';

import '../models/player.dart';
import '../state/game_controller.dart';

class SquadScreen extends StatelessWidget {
  final GameController controller;

  const SquadScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final save = controller.save!;
    final club = save.managedClub;
    final squad = List<Player>.from(club.activeSquad)
      ..sort((a, b) {
        final posOrder = {
          Position.gk: 0,
          Position.def: 1,
          Position.mid: 2,
          Position.fwd: 3,
        };
        final byPos = posOrder[a.position]!.compareTo(posOrder[b.position]!);
        if (byPos != 0) return byPos;
        return b.overallRating.compareTo(a.overallRating);
      });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Starting XI: ${save.lineup.length} / 11 selected',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: squad.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final player = squad[i];
              final inLineup = save.lineup.contains(player.id);
              return ListTile(
                leading: CircleAvatar(
                  child: Text(player.position.name.toUpperCase()),
                ),
                title: Text(player.name),
                subtitle: Text(
                  'OVR ${player.overallRating} · Fit ${player.fitness} · Morale ${player.morale} · \$${player.value}',
                ),
                trailing: Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        inLineup ? Icons.check_circle : Icons.circle_outlined,
                        color: inLineup ? Colors.green : null,
                      ),
                      tooltip: inLineup ? 'In starting XI' : 'Add to starting XI',
                      onPressed: () => controller.toggleLineupPlayer(player.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sell_outlined),
                      tooltip: 'List for sale',
                      onPressed: () => _showSellDialog(context, player),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showSellDialog(BuildContext context, Player player) async {
    final controllerText = TextEditingController(text: player.value.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sell ${player.name}'),
        content: TextField(
          controller: controllerText,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Asking price'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              int.tryParse(controllerText.text) ?? player.value,
            ),
            child: const Text('List for sale'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final offerResult = await controller.sellPlayer(
      playerId: player.id,
      askingPrice: result,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(offerResult.message)),
    );
  }
}
