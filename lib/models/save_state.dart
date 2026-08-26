import 'club.dart';
import 'fixture.dart';
import 'objective.dart';

enum Mentality { defensive, balanced, attacking }

/// The full persisted state for one career save. Holds a working copy
/// of every club (squads mutate via transfers, so this isn't just a
/// reference back to the read-only ContentPack — see spec §3/§5 on
/// why SaveState references world data by ID in the full design; this
/// skeleton keeps a full mutable copy per save for simplicity, since
/// there's only one save slot and no shared content across saves yet).
class SaveState {
  final String packVersion;
  final String season;
  final String managedClubId;
  int currentRound; // 1-indexed matchday about to be played
  final List<Club> clubs;
  final List<Fixture> fixtures;
  final List<Objective> objectives;
  List<String> lineup; // starting XI player IDs for the managed club
  Mentality mentality;
  int matchSeedCounter;
  bool seasonComplete;

  SaveState({
    required this.packVersion,
    required this.season,
    required this.managedClubId,
    required this.currentRound,
    required this.clubs,
    required this.fixtures,
    required this.objectives,
    required this.lineup,
    this.mentality = Mentality.balanced,
    this.matchSeedCounter = 1,
    this.seasonComplete = false,
  });

  Club get managedClub => clubs.firstWhere((c) => c.id == managedClubId);

  Club clubById(String id) => clubs.firstWhere((c) => c.id == id);

  void replaceClub(Club updated) {
    final idx = clubs.indexWhere((c) => c.id == updated.id);
    clubs[idx] = updated;
  }

  List<Fixture> fixturesForRound(int round) =>
      fixtures.where((f) => f.round == round).toList();

  bool get hasFixturesRemaining =>
      fixtures.any((f) => !f.isPlayed);

  int get totalRounds =>
      fixtures.isEmpty ? 0 : fixtures.map((f) => f.round).reduce((a, b) => a > b ? a : b);

  Map<String, dynamic> toJson() => {
        'pack_version': packVersion,
        'season': season,
        'managed_club_id': managedClubId,
        'current_round': currentRound,
        'clubs': clubs.map((c) => c.toJson()).toList(),
        'fixtures': fixtures.map((f) => f.toJson()).toList(),
        'objectives': objectives.map((o) => o.toJson()).toList(),
        'lineup': lineup,
        'mentality': mentality.name,
        'match_seed_counter': matchSeedCounter,
        'season_complete': seasonComplete,
      };

  factory SaveState.fromJson(Map<String, dynamic> json) => SaveState(
        packVersion: json['pack_version'] as String,
        season: json['season'] as String,
        managedClubId: json['managed_club_id'] as String,
        currentRound: json['current_round'] as int,
        clubs: (json['clubs'] as List<dynamic>)
            .map((c) => Club.fromJson(c as Map<String, dynamic>))
            .toList(),
        fixtures: (json['fixtures'] as List<dynamic>)
            .map((f) => Fixture.fromJson(f as Map<String, dynamic>))
            .toList(),
        objectives: (json['objectives'] as List<dynamic>)
            .map((o) => Objective.fromJson(o as Map<String, dynamic>))
            .toList(),
        lineup: (json['lineup'] as List<dynamic>).cast<String>(),
        mentality: Mentality.values.byName(
          json['mentality'] as String? ?? 'balanced',
        ),
        matchSeedCounter: json['match_seed_counter'] as int? ?? 1,
        seasonComplete: json['season_complete'] as bool? ?? false,
      );
}
