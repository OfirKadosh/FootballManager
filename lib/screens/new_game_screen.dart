import 'package:flutter/material.dart';

import '../models/club.dart';
import '../models/country.dart';
import '../models/league.dart';
import '../services/data_importer_service.dart';
import '../state/game_controller.dart';
import 'data_import_screen.dart';

class NewGameScreen extends StatefulWidget {
  final GameController controller;

  const NewGameScreen({super.key, required this.controller});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  ImportResult? _imported;

  @override
  Widget build(BuildContext context) {
    final countries = _imported?.countries ?? widget.controller.pack!.countries;
    final leagues = _imported?.leagues ?? widget.controller.pack!.leagues;
    final clubs = _imported?.clubs ?? widget.controller.availableClubs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pocket Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import your own data',
            onPressed: _openImporter,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _imported != null
                  ? 'Choose a club from your imported data.'
                  : 'Choose a club to manage for the 2026/27 season, '
                      'or import your own dataset.',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          if (_imported != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Using imported data: ${clubs.length} clubs across '
                      '${leagues.length} leagues.',
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _imported = null),
                    child: const Text('Use sample data'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              children: _groupByCountryAndLeague(countries, leagues, clubs),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _groupByCountryAndLeague(
    List<Country> countries,
    List<League> leagues,
    List<Club> clubs,
  ) {
    final widgets = <Widget>[];
    for (final country in countries) {
      final countryLeagues = leagues.where((l) => l.countryId == country.id).toList()
        ..sort((a, b) => a.tier.compareTo(b.tier));
      if (countryLeagues.isEmpty) continue;

      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          country.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ));

      for (final league in countryLeagues) {
        final leagueClubs = clubs.where((c) => c.leagueId == league.id).toList()
          ..sort((a, b) => b.reputation.compareTo(a.reputation));
        if (leagueClubs.isEmpty) continue;

        widgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            league.name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ));

        for (final club in leagueClubs) {
          widgets.add(ListTile(
            leading: CircleAvatar(child: Text(club.shortName)),
            title: Text(club.name),
            subtitle: Text('Reputation ${club.reputation} · Squad ${club.squad.length}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              if (_imported != null) {
                await widget.controller.startNewGameFromImport(_imported!, club.id);
              } else {
                await widget.controller.startNewGame(club.id);
              }
            },
          ));
        }
      }
    }
    return widgets;
  }

  Future<void> _openImporter() async {
    final result = await Navigator.of(context).push<ImportResult>(
      MaterialPageRoute(builder: (_) => const DataImportScreen()),
    );
    if (result != null) {
      setState(() => _imported = result);
    }
  }
}
