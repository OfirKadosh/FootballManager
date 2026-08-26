import 'package:flutter/material.dart';

import '../models/objective.dart';
import '../state/game_controller.dart';

class ObjectivesScreen extends StatelessWidget {
  final GameController controller;

  const ObjectivesScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final save = controller.save!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (save.seasonComplete)
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Season complete — final results below.'),
            ),
          ),
        const SizedBox(height: 8),
        for (final obj in save.objectives) _ObjectiveTile(objective: obj),
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
        subtitle: Text(_statusLabel(objective.status)),
      ),
    );
  }

  String _statusLabel(ObjectiveStatus status) {
    switch (status) {
      case ObjectiveStatus.achieved:
        return 'Achieved';
      case ObjectiveStatus.failed:
        return 'Not achieved';
      case ObjectiveStatus.inProgress:
        return 'In progress';
    }
  }
}
