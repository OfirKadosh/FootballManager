import 'package:flutter/material.dart';

import '../state/game_controller.dart';

class TableScreen extends StatelessWidget {
  final GameController controller;

  const TableScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final save = controller.save!;
    final table = controller.table;

    return ListView.builder(
      itemCount: table.length,
      itemBuilder: (context, i) {
        final row = table[i];
        final club = save.clubById(row.clubId);
        final isManaged = row.clubId == save.managedClubId;
        return Container(
          color: isManaged
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4)
              : null,
          child: ListTile(
            leading: SizedBox(
              width: 28,
              child: Text('${i + 1}', textAlign: TextAlign.center),
            ),
            title: Text(club.name),
            subtitle: Text(
              'P${row.played} W${row.won} D${row.drawn} L${row.lost} GD${row.goalDifference >= 0 ? '+' : ''}${row.goalDifference}',
            ),
            trailing: Text(
              '${row.points} pts',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
