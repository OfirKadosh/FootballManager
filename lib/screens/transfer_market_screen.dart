import 'package:flutter/material.dart';

import '../models/club.dart';
import '../models/player.dart';
import '../state/game_controller.dart';

class TransferMarketScreen extends StatefulWidget {
  final GameController controller;

  const TransferMarketScreen({super.key, required this.controller});

  @override
  State<TransferMarketScreen> createState() => _TransferMarketScreenState();
}

class _TransferMarketScreenState extends State<TransferMarketScreen> {
  Position? _positionFilter;

  @override
  Widget build(BuildContext context) {
    final save = widget.controller.save!;
    final scoutingTip = _weakestPosition(save.managedClub.activeSquad);

    final listings = <(Club, Player)>[];
    for (final club in save.clubs) {
      if (club.id == save.managedClubId) continue;
      for (final p in club.activeSquad) {
        if (_positionFilter != null && p.position != _positionFilter) continue;
        listings.add((club, p));
      }
    }
    listings.sort((a, b) => b.$2.overallRating.compareTo(a.$2.overallRating));
    final shown = listings.take(50).toList();

    return Column(
      children: [
        if (scoutingTip != null)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.tertiaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.travel_explore, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scouting: ${scoutingTip.name.toUpperCase()} is your weakest '
                    'position (avg OVR ${scoutingTip.avgRating}) — consider '
                    'strengthening there.',
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _positionFilter = scoutingTip.position),
                  child: const Text('Filter'),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _positionFilter == null,
                onSelected: (_) => setState(() => _positionFilter = null),
              ),
              for (final pos in Position.values)
                ChoiceChip(
                  label: Text(pos.name.toUpperCase()),
                  selected: _positionFilter == pos,
                  onSelected: (_) => setState(() => _positionFilter = pos),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: shown.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final (club, player) = shown[i];
              return ListTile(
                leading: CircleAvatar(child: Text(player.position.name.toUpperCase())),
                title: Text(player.name),
                subtitle: Text('${club.name} · OVR ${player.overallRating} · \$${player.value}'),
                trailing: FilledButton(
                  onPressed: () => _showOfferDialog(club, player),
                  child: const Text('Bid'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showOfferDialog(Club club, Player player) async {
    final save = widget.controller.save!;
    final textController = TextEditingController(text: player.value.toString());
    final amount = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bid for ${player.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your balance: \$${save.managedClub.balance}'),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Offer amount'),
            ),
          ],
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
            child: const Text('Submit bid'),
          ),
        ],
      ),
    );
    if (amount == null) return;

    final result = await widget.controller.buyPlayer(
      sellingClubId: club.id,
      playerId: player.id,
      amount: amount,
    );
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  /// Simple scouting heuristic: which outfield position has the lowest
  /// average rating in the managed squad. Good enough to point the
  /// user somewhere useful; a fuller scouting system (scout reports,
  /// hidden attributes revealed over time) is a natural next layer.
  _WeakPosition? _weakestPosition(List<Player> squad) {
    final byPosition = <Position, List<int>>{};
    for (final p in squad) {
      if (p.position == Position.gk) continue;
      byPosition.putIfAbsent(p.position, () => []).add(p.overallRating);
    }
    if (byPosition.isEmpty) return null;

    Position? weakest;
    double weakestAvg = double.infinity;
    for (final entry in byPosition.entries) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (avg < weakestAvg) {
        weakestAvg = avg;
        weakest = entry.key;
      }
    }
    if (weakest == null) return null;
    return _WeakPosition(position: weakest, avgRating: weakestAvg.round());
  }
}

class _WeakPosition {
  final Position position;
  final int avgRating;

  const _WeakPosition({required this.position, required this.avgRating});

  String get name => position.name;
}
