import 'package:flutter/material.dart';

import '../models/news_item.dart';
import '../models/objective.dart';
import '../state/game_controller.dart';

class InboxScreen extends StatelessWidget {
  final GameController controller;

  const InboxScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final save = controller.save!;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Season objectives', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...save.objectives.map((o) => _ObjectiveTile(objective: o)),
        const SizedBox(height: 20),
        Text('News', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (save.inbox.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Nothing yet — play a game week to see results here.'),
          ),
        ...save.inbox.map((n) => _NewsTile(controller: controller, item: n)),
      ],
    );
  }
}

class _ObjectiveTile extends StatelessWidget {
  final Objective objective;

  const _ObjectiveTile({required this.objective});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (objective.status) {
      ObjectiveStatus.achieved => (Icons.check_circle, Colors.green),
      ObjectiveStatus.failed => (Icons.cancel, Colors.red),
      ObjectiveStatus.inProgress => (Icons.hourglass_top, Colors.orange),
    };
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(objective.description),
        subtitle: Text(switch (objective.status) {
          ObjectiveStatus.achieved => 'Achieved',
          ObjectiveStatus.failed => 'Not achieved',
          ObjectiveStatus.inProgress => 'In progress',
        }),
      ),
    );
  }
}

class _NewsTile extends StatelessWidget {
  final GameController controller;
  final NewsItem item;

  const _NewsTile({required this.controller, required this.item});

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.category) {
      NewsCategory.matchResult => Icons.sports_soccer,
      NewsCategory.transfer => Icons.swap_horiz,
      NewsCategory.objective => Icons.flag,
      NewsCategory.promotionRelegation => Icons.trending_up,
      NewsCategory.finance => Icons.attach_money,
    };
    return Card(
      color: item.read ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: Icon(icon),
        title: Text(item.headline, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${item.body}\nGame week ${item.gameWeek}'),
        isThreeLine: true,
        onTap: item.read ? null : () => controller.markNewsRead(item.id),
      ),
    );
  }
}
