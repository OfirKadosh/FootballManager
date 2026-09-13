import 'club.dart';
import 'country.dart';
import 'fixture.dart';
import 'league.dart';
import 'news_item.dart';
import 'objective.dart';
import 'tactics.dart';
import 'transfer_offer.dart';

class SaveState {
  final String packVersion;
  final String season;
  final String managedClubId;
  int currentRound;
  final List<Country> countries;
  final List<League> leagues;
  final List<Club> clubs;
  final List<Fixture> fixtures;
  final List<Objective> objectives;
  final List<TransferOffer> transferOffers;
  final List<NewsItem> inbox;
  List<String> lineup;
  Tactics tactics;
  int matchSeedCounter;
  bool seasonComplete;

  SaveState({
    required this.packVersion,
    required this.season,
    required this.managedClubId,
    required this.currentRound,
    required this.countries,
    required this.leagues,
    required this.clubs,
    required this.fixtures,
    required this.objectives,
    required this.lineup,
    List<TransferOffer>? transferOffers,
    List<NewsItem>? inbox,
    Tactics? tactics,
    this.matchSeedCounter = 1,
    this.seasonComplete = false,
  })  : transferOffers = transferOffers ?? [],
        inbox = inbox ?? [],
        tactics = tactics ?? const Tactics();

  Club get managedClub => clubs.firstWhere((c) => c.id == managedClubId);

  League get managedLeague =>
      leagues.firstWhere((l) => l.id == managedClub.leagueId);

  Club clubById(String id) => clubs.firstWhere((c) => c.id == id);

  void replaceClub(Club updated) {
    final idx = clubs.indexWhere((c) => c.id == updated.id);
    clubs[idx] = updated;
  }

  List<Fixture> fixturesForRound(int round) =>
      fixtures.where((f) => f.round == round).toList();

  List<Fixture> fixturesForCompetitionRound(String competitionId, int round) =>
      fixtures
          .where((f) => f.competitionId == competitionId && f.round == round)
          .toList();

  bool get hasFixturesRemaining => fixtures.any((f) => !f.isPlayed);

  int get totalRounds => fixtures.isEmpty
      ? 0
      : fixtures.map((f) => f.round).reduce((a, b) => a > b ? a : b);

  void addNews(NewsItem item) => inbox.insert(0, item);

  Map<String, dynamic> toJson() => {
        'pack_version': packVersion,
        'season': season,
        'managed_club_id': managedClubId,
        'current_round': currentRound,
        'countries': countries.map((c) => c.toJson()).toList(),
        'leagues': leagues.map((l) => l.toJson()).toList(),
        'clubs': clubs.map((c) => c.toJson()).toList(),
        'fixtures': fixtures.map((f) => f.toJson()).toList(),
        'objectives': objectives.map((o) => o.toJson()).toList(),
        'transfer_offers': transferOffers.map((t) => t.toJson()).toList(),
        'inbox': inbox.map((n) => n.toJson()).toList(),
        'lineup': lineup,
        'tactics': tactics.toJson(),
        'match_seed_counter': matchSeedCounter,
        'season_complete': seasonComplete,
      };

  factory SaveState.fromJson(Map<String, dynamic> json) => SaveState(
        packVersion: json['pack_version'] as String,
        season: json['season'] as String,
        managedClubId: json['managed_club_id'] as String,
        currentRound: json['current_round'] as int,
        countries: (json['countries'] as List<dynamic>? ?? [])
            .map((c) => Country.fromJson(c as Map<String, dynamic>))
            .toList(),
        leagues: (json['leagues'] as List<dynamic>? ?? [])
            .map((l) => League.fromJson(l as Map<String, dynamic>))
            .toList(),
        clubs: (json['clubs'] as List<dynamic>)
            .map((c) => Club.fromJson(c as Map<String, dynamic>))
            .toList(),
        fixtures: (json['fixtures'] as List<dynamic>)
            .map((f) => Fixture.fromJson(f as Map<String, dynamic>))
            .toList(),
        objectives: (json['objectives'] as List<dynamic>)
            .map((o) => Objective.fromJson(o as Map<String, dynamic>))
            .toList(),
        transferOffers: (json['transfer_offers'] as List<dynamic>? ?? [])
            .map((t) => TransferOffer.fromJson(t as Map<String, dynamic>))
            .toList(),
        inbox: (json['inbox'] as List<dynamic>? ?? [])
            .map((n) => NewsItem.fromJson(n as Map<String, dynamic>))
            .toList(),
        lineup: (json['lineup'] as List<dynamic>).cast<String>(),
        tactics: json['tactics'] != null
            ? Tactics.fromJson(json['tactics'] as Map<String, dynamic>)
            : const Tactics(),
        matchSeedCounter: json['match_seed_counter'] as int? ?? 1,
        seasonComplete: json['season_complete'] as bool? ?? false,
      );
}
