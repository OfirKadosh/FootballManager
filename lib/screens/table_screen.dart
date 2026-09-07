import 'package:flutter/material.dart';

import '../models/league.dart';
import '../services/world_service.dart';
import '../state/game_controller.dart';

class TableScreen extends StatefulWidget {
  final GameController controller;

  const TableScreen({super.key, required this.controller});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  String? _selectedLeagueId;

  @override
  Widget build(BuildContext context) {
    final save = widget.controller.save!;
    final leagues = List<League>.from(save.leagues)
      ..sort((a, b) {
        final byCountry = a.countryId.compareTo(b.countryId);
        return byCountry != 0 ? byCountry : a.tier.compareTo(b.tier);
      });

    final selectedId = _selectedLeagueId ?? save.managedClub.leagueId;
    final selectedLeague = leagues.firstWhere((l) => l.id == selectedId);
    final table = WorldService.tableFor(selectedId, save.clubs, save.fixtures);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            value: selectedId,
            decoration: const InputDecoration(
              labelText: 'League',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: leagues
                .map((l) => DropdownMenuItem(
                      value: l.id,
                      child: Text(
                        '${save.countries.firstWhere((c) => c.id == l.countryId).name} — ${l.name}',
                      ),
                    ))
                .toList(),
            onChanged: (id) => setState(() => _selectedLeagueId = id),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: table.length,
            itemBuilder: (context, i) {
              final row = table[i];
              final club = save.clubById(row.clubId);
              final isManaged = row.clubId == save.managedClubId;
              final rank = i + 1;
              final inPromotionZone = rank <= selectedLeague.promotionSpots;
              final inRelegationZone = rank > table.length - selectedLeague.relegationSpots;
              final inContinentalZone = rank <= selectedLeague.continentalQualificationSpots;

              return Container(
                color: isManaged
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4)
                    : null,
                child: ListTile(
                  leading: SizedBox(
                    width: 28,
                    child: Text(
                      '$rank',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: inPromotionZone || inContinentalZone
                            ? Colors.green
                            : inRelegationZone
                                ? Colors.red
                                : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(club.name),
                  subtitle: Text(
                    'P${row.played} W${row.won} D${row.drawn} L${row.lost} '
                    'GD${row.goalDifference >= 0 ? '+' : ''}${row.goalDifference}',
                  ),
                  trailing: Text(
                    '${row.points} pts',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 12,
            children: [
              if (selectedLeague.promotionSpots > 0) _legend(Colors.green, 'Promotion'),
              if (selectedLeague.continentalQualificationSpots > 0)
                _legend(Colors.green, 'Continental cup'),
              if (selectedLeague.relegationSpots > 0) _legend(Colors.red, 'Relegation'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legend(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}
