import 'dart:convert';

import '../models/club.dart';
import '../models/country.dart';
import '../models/league.dart';
import '../models/player.dart';

class ImportException implements Exception {
  final String message;
  const ImportException(this.message);

  @override
  String toString() => message;
}

class ImportResult {
  final List<Country> countries;
  final List<League> leagues;
  final List<Club> clubs;
  final List<String> warnings;

  const ImportResult({
    required this.countries,
    required this.leagues,
    required this.clubs,
    this.warnings = const [],
  });
}

class DataImporterService {
  static ImportResult parseJson(String raw) {
    final Map<String, dynamic> root;
    try {
      root = jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw ImportException('Not valid JSON: ${e.message}');
    }

    final countriesJson = root['countries'] as List<dynamic>?;
    final leaguesJson = root['leagues'] as List<dynamic>?;
    final clubsJson = root['clubs'] as List<dynamic>?;

    if (leaguesJson == null || clubsJson == null) {
      throw const ImportException(
        'JSON must have top-level "leagues" and "clubs" arrays.',
      );
    }

    final countries = <Country>[];
    for (var i = 0; i < (countriesJson?.length ?? 0); i++) {
      try {
        countries.add(Country.fromJson(countriesJson![i] as Map<String, dynamic>));
      } catch (e) {
        throw ImportException('countries[$i] is invalid: $e');
      }
    }

    final leagues = <League>[];
    for (var i = 0; i < leaguesJson.length; i++) {
      try {
        leagues.add(League.fromJson(leaguesJson[i] as Map<String, dynamic>));
      } catch (e) {
        throw ImportException('leagues[$i] is invalid: $e');
      }
    }

    final clubs = <Club>[];
    final warnings = <String>[];
    final leagueIds = leagues.map((l) => l.id).toSet();

    for (var i = 0; i < clubsJson.length; i++) {
      final Club club;
      try {
        club = Club.fromJson(clubsJson[i] as Map<String, dynamic>);
      } catch (e) {
        throw ImportException('clubs[$i] is invalid: $e');
      }
      if (!leagueIds.contains(club.leagueId)) {
        throw ImportException(
          'clubs[$i] ("${club.name}") references league_id '
          '"${club.leagueId}" which isn\'t in the "leagues" array.',
        );
      }
      if (club.squad.isEmpty) {
        warnings.add('${club.name} has no players.');
      }
      clubs.add(club);
    }

    _validateWorldShape(leagues, clubs, warnings);

    return ImportResult(
      countries: countries,
      leagues: leagues,
      clubs: clubs,
      warnings: warnings,
    );
  }

  static ImportResult parseCsv({
    required String clubsCsv,
    required String playersCsv,
  }) {
    final clubRows = _parseCsvTable(clubsCsv);
    final playerRows = _parseCsvTable(playersCsv);
    final warnings = <String>[];

    final countriesById = <String, Country>{};
    final leaguesById = <String, League>{};

    for (final row in clubRows) {
      final countryName = _require(row, 'country_name', context: 'clubs.csv');
      final countryId = _slug(countryName);
      countriesById.putIfAbsent(
        countryId,
        () => Country(id: countryId, name: countryName),
      );

      final leagueName = _require(row, 'league_name', context: 'clubs.csv');
      final tier = int.tryParse(row['tier'] ?? '1') ?? 1;
      final leagueId = '${countryId}_${_slug(leagueName)}';
      leaguesById.putIfAbsent(
        leagueId,
        () => League(
          id: leagueId,
          countryId: countryId,
          name: leagueName,
          tier: tier,
          promotionSpots: int.tryParse(row['promotion_spots'] ?? '') ?? 2,
          relegationSpots: int.tryParse(row['relegation_spots'] ?? '') ?? 2,
          continentalQualificationSpots:
              int.tryParse(row['continental_spots'] ?? '') ?? 0,
        ),
      );
    }

    final playersByClubId = <String, List<Player>>{};
    for (var i = 0; i < playerRows.length; i++) {
      final row = playerRows[i];
      final clubId = _require(row, 'club_id', context: 'players.csv row $i');
      final Position position;
      try {
        position = Position.values.byName(
          _require(row, 'position', context: 'players.csv row $i').toLowerCase(),
        );
      } catch (_) {
        throw ImportException(
          'players.csv row $i: position "${row['position']}" must be one '
          'of gk, def, mid, fwd.',
        );
      }
      final player = Player(
        id: _require(row, 'id', context: 'players.csv row $i'),
        name: _require(row, 'name', context: 'players.csv row $i'),
        nationality: row['nationality'] ?? 'UNK',
        position: position,
        attributes: PlayerAttributes(
          pace: _int(row, 'pace', 50),
          shooting: _int(row, 'shooting', 50),
          passing: _int(row, 'passing', 50),
          tackling: _int(row, 'tackling', 50),
          dribbling: _int(row, 'dribbling', 50),
          goalkeeping: _int(row, 'goalkeeping', position == Position.gk ? 60 : 10),
          physical: _int(row, 'physical', 50),
          staminaRating: _int(row, 'stamina_rating', 60),
          injuryProneness: _int(row, 'injury_proneness', 20),
          workRate: _int(row, 'work_rate', 55),
          leadership: _int(row, 'leadership', 45),
        ),
        wage: _int(row, 'wage', 1000),
        value: _int(row, 'value', 100000),
        contractYearsRemaining: _int(row, 'contract_years_remaining', 2),
      );
      playersByClubId.putIfAbsent(clubId, () => []).add(player);
    }

    final clubs = <Club>[];
    for (final row in clubRows) {
      final countryId = _slug(_require(row, 'country_name', context: 'clubs.csv'));
      final leagueId =
          '${countryId}_${_slug(_require(row, 'league_name', context: 'clubs.csv'))}';
      final clubId = _require(row, 'id', context: 'clubs.csv');
      final squad = playersByClubId[clubId] ?? [];
      if (squad.isEmpty) {
        warnings.add('${row['name'] ?? clubId} has no players in players.csv.');
      }
      clubs.add(Club(
        id: clubId,
        name: _require(row, 'name', context: 'clubs.csv'),
        shortName: row['short_name'] ?? clubId.toUpperCase(),
        leagueId: leagueId,
        reputation: _int(row, 'reputation', 50),
        balance: _int(row, 'balance', 1000000),
        stadiumCapacity: _int(row, 'stadium_capacity', 15000),
        weeklySponsorship: _int(row, 'weekly_sponsorship', 20000),
        squad: squad,
      ));
    }

    final leagues = leaguesById.values.toList();
    _validateWorldShape(leagues, clubs, warnings);

    return ImportResult(
      countries: countriesById.values.toList(),
      leagues: leagues,
      clubs: clubs,
      warnings: warnings,
    );
  }

  static void _validateWorldShape(
    List<League> leagues,
    List<Club> clubs,
    List<String> warnings,
  ) {
    for (final league in leagues) {
      final count = clubs.where((c) => c.leagueId == league.id).length;
      if (count == 0) {
        warnings.add('League "${league.name}" has no clubs.');
      } else if (count < 2) {
        throw ImportException(
          'League "${league.name}" has only $count club(s) — need at least 2.',
        );
      } else if (count.isOdd) {
        throw ImportException(
          'League "${league.name}" has $count clubs — the season scheduler '
          'needs an even number per league.',
        );
      }
    }
  }

  static String _require(Map<String, String> row, String key, {required String context}) {
    final value = row[key];
    if (value == null || value.trim().isEmpty) {
      throw ImportException('$context: missing required field "$key".');
    }
    return value.trim();
  }

  static int _int(Map<String, String> row, String key, int fallback) {
    final raw = row[key];
    if (raw == null || raw.trim().isEmpty) return fallback;
    return int.tryParse(raw.trim()) ?? fallback;
  }

  static String _slug(String s) =>
      s.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  static List<Map<String, String>> _parseCsvTable(String csv) {
    final lines = csv.split(RegExp(r'\r\n|\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return [];

    final header = _parseCsvLine(lines.first);
    final rows = <Map<String, String>>[];
    for (var i = 1; i < lines.length; i++) {
      final fields = _parseCsvLine(lines[i]);
      final row = <String, String>{};
      for (var c = 0; c < header.length; c++) {
        row[header[c]] = c < fields.length ? fields[c] : '';
      }
      rows.add(row);
    }
    return rows;
  }

  static List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            buffer.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          buffer.write(ch);
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
        } else if (ch == ',') {
          fields.add(buffer.toString().trim());
          buffer.clear();
        } else {
          buffer.write(ch);
        }
      }
    }
    fields.add(buffer.toString().trim());
    return fields;
  }
}
