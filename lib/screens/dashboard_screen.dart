import 'package:flutter/material.dart';

import '../models/save_state.dart';
import '../sim/match_result.dart';
import '../state/game_controller.dart';

class DashboardScreen extends StatelessWidget {
  final GameController controller;

  const DashboardScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final save = controller.save!;
    final club = save.managedClub;
    final position = controller.managedClubPosition;
    final nextOwnFixture = save.fixtures
        .where((f) =>
            !f.isPlayed &&
            (f.homeClubId == save.managedClubId ||
                f.awayClubId == save.managedClubId))
        .toList()
      ..sort((a, b) => a.round.compareTo(b.round));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(club.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Position: $position of ${save.clubs.length}'),
                  Text('Balance: \$${club.balance}'),
                  Text('Season: ${save.season} · Matchday ${save.currentRound.clamp(1, save.totalRounds)} of ${save.totalRounds}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (nextOwnFixture.isNotEmpty && !save.seasonComplete)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Next match', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Builder(builder: (context) {
                      final f = nextOwnFixture.first;
                      final isHome = f.homeClubId == save.managedClubId;
                      final opponent = save.clubById(
                        isHome ? f.awayClubId : f.homeClubId,
                      );
                      return Text(
                        isHome ? 'Home vs ${opponent.name}' : 'Away at ${opponent.name}',
                      );
                    }),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tactics', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<Mentality>(
                    segments: const [
                      ButtonSegment(value: Mentality.defensive, label: Text('Defensive')),
                      ButtonSegment(value: Mentality.balanced, label: Text('Balanced')),
                      ButtonSegment(value: Mentality.attacking, label: Text('Attacking')),
                    ],
                    selected: {save.mentality},
                    onSelectionChanged: (s) => controller.setMentality(s.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (save.seasonComplete)
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Season complete! Check the Objectives tab for your final results.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            FilledButton.icon(
              onPressed: controller.canPlayMatchday
                  ? () => _playMatchday(context)
                  : null,
              icon: const Icon(Icons.sports_soccer),
              label: Text('Play Matchday ${save.currentRound}'),
            ),
        ],
      ),
    );
  }

  Future<void> _playMatchday(BuildContext context) async {
    await controller.playNextMatchday();
    if (!context.mounted) return;
    final save = controller.save!;
    final MatchResult? own = controller.lastMatchdayResults
        .cast<MatchResult?>()
        .firstWhere(
          (r) =>
              r!.homeClubId == save.managedClubId ||
              r.awayClubId == save.managedClubId,
          orElse: () => null,
        );
    if (own == null) return;

    final home = save.clubById(own.homeClubId);
    final away = save.clubById(own.awayClubId);
    final position = controller.managedClubPosition;

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Full time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${home.name}  ${own.scoreline}  ${away.name}',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text('League position: $position of ${save.clubs.length}'),
            if (own.events.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Goals:', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...own.events.map((e) => Text(e.toString())),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
