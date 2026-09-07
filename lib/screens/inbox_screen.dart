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

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'News'),
              Tab(text: 'Objectives'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _NewsList(controller: controller),
                _ObjectivesList(objectives: save.objectives),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsList extends StatelessWidget {
  final GameController controller;

  const _NewsList({required this.controller});

  @override
  Widget build(BuildContext context) {
    final inbox = controller.save!.inbox;
    if (inbox.isEmpty) {
      return const Center(child: Text('No news yet — play a game week.'));
    }
    return ListView.separated(
      itemCount: inbox.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final item = inbox[i];
        return ListTile(
          leading: Icon(_iconFor(item.category), color: _colorFor(item.category)),
          title: Text(
            item.headline,
            style: TextStyle(fontWeight: item.read ? FontWeight.normal : FontWeight.bold),
          ),
          subtitle: Text(item.body, maxLines: 3, overflow: TextOverflow.ellipsis),
          trailing: Text('GW ${item.gameWeek}', style: Theme.of(context).textTheme.bodySmall),
          onTap: () => controller.markNewsRead(item.id),
        );
      },
    );
  }

  IconData _iconFor(NewsCategory c) {
    switch (c) {
      case NewsCategory.matchResult:
        return Icons.sports_soccer;
      case NewsCategory.transfer:
        return Icons.swap_horiz;
      case NewsCategory.objective:
        return Icons.flag;
      case NewsCategory.promotionRelegation:
        return Icons.trending_up;
      case NewsCategory.finance:
        return Icons.attach_money;
    }
  }

  Color? _colorFor(NewsCategory c) {
    switch (c) {
      case NewsCategory.promotionRelegation:
        return Colors.purple;
      case NewsCategory.objective:
        return Colors.orange;
      default:
        return null;
    }
  }
}

class _ObjectivesList extends StatelessWidget {
  final List<Objective> objectives;

  const _ObjectivesList({required this.objectives});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: objectives.map((obj) {
        final (icon, color) = switch (obj.status) {
          ObjectiveStatus.achieved => (Icons.check_circle, Colors.green),
          ObjectiveStatus.failed => (Icons.cancel, Colors.red),
          ObjectiveStatus.inProgress => (Icons.hourglass_top, Colors.orange),
        };
        return Card(
          child: ListTile(
            leading: Icon(icon, color: color),
            title: Text(obj.description),
            subtitle: Text(switch (obj.status) {
              ObjectiveStatus.achieved => 'Achieved',
              ObjectiveStatus.failed => 'Not achieved',
              ObjectiveStatus.inProgress => 'In progress',
            }),
          ),
        );
      }).toList(),
    );
  }
}
