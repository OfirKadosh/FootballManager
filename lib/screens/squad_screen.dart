import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/tactics.dart';
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
        const posOrder = {
          Position.gk: 0,
          Position.def: 1,
          Position.mid: 2,
          Position.fwd: 3,
        };
        final byPos = posOrder[a.position]!.compareTo(posOrder[b.position]!);
        if (byPos != 0) return byPos;
        return b.overallRating.compareTo(a.overallRating);
      });

    return ListView(
      children: [
        _TacticsBoard(controller: controller),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Starting XI: ${save.lineup.length} / 11',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: controller.autoFillLineup,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Auto-fill'),
              ),
            ],
          ),
        ),
        ...squad.map((player) => _PlayerTile(controller: controller, player: player)),
      ],
    );
  }
}

class _TacticsBoard extends StatelessWidget {
  final GameController controller;

  const _TacticsBoard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final tactics = controller.save!.tactics;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tactics', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const Text('Formation', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SegmentedButton<Formation>(
              segments: Formation.values
                  .map((f) => ButtonSegment(value: f, label: Text(f.label)))
                  .toList(),
              selected: {tactics.formation},
              onSelectionChanged: (s) => controller.setTactics(
                tactics.copyWith(formation: s.first),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Style', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SegmentedButton<TacticalStyle>(
              segments: const [
                ButtonSegment(value: TacticalStyle.highPress, label: Text('High Press')),
                ButtonSegment(value: TacticalStyle.counterAttack, label: Text('Counter')),
                ButtonSegment(value: TacticalStyle.possession, label: Text('Possession')),
              ],
              selected: {tactics.style},
              onSelectionChanged: (s) => controller.setTactics(
                tactics.copyWith(style: s.first),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Mentality', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SegmentedButton<Mentality>(
              segments: const [
                ButtonSegment(value: Mentality.defensive, label: Text('Defensive')),
                ButtonSegment(value: Mentality.balanced, label: Text('Balanced')),
                ButtonSegment(value: Mentality.attacking, label: Text('Attacking')),
              ],
              selected: {tactics.mentality},
              onSelectionChanged: (s) => controller.setTactics(
                tactics.copyWith(mentality: s.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final GameController controller;
  final Player player;

  const _PlayerTile({required this.controller, required this.player});

  @override
  Widget build(BuildContext context) {
    final save = controller.save!;
    final inLineup = save.lineup.contains(player.id);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: player.injured ? Colors.red.shade100 : null,
        child: Text(player.position.name.toUpperCase()),
      ),
      title: Text(player.name),
      subtitle: Text(
        player.injured
            ? 'Injured — ${player.injuryDaysRemaining}d remaining'
            : 'OVR ${player.overallRating} · Fit ${player.fitness} · Morale ${player.morale} · \$${player.value}',
        style: player.injured ? const TextStyle(color: Colors.red) : null,
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
            onPressed: player.injured ? null : () => controller.toggleLineupPlayer(player.id),
          ),
          IconButton(
            icon: const Icon(Icons.sell_outlined),
            tooltip: 'List for sale',
            onPressed: () => _showSellDialog(context, player),
          ),
        ],
      ),
    );
  }

  Future<void> _showSellDialog(BuildContext context, Player player) async {
    final textController = TextEditingController(text: player.value.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sell ${player.name}'),
        content: TextField(
          controller: textController,
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
              int.tryParse(textController.text) ?? player.value,
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
