import '../models/club.dart';
import '../models/country.dart';
import '../models/fixture.dart';
import '../models/league.dart';
import 'season_service.dart';

class WorldService {
  static List<Fixture> generateAllFixtures(
    List<League> leagues,
    List<Club> clubs,
  ) {
    final fixtures = <Fixture>[];
    for (final league in leagues) {
      final leagueClubs = clubs.where((c) => c.leagueId == league.id).toList();
      if (leagueClubs.isEmpty) continue;
      fixtures.addAll(
        SeasonService.generateRoundRobin(leagueClubs, competitionId: league.id),
      );
    }
    return fixtures;
  }

  static List<Club> clubsInLeague(String leagueId, List<Club> allClubs) =>
      allClubs.where((c) => c.leagueId == leagueId).toList();

  static List<Fixture> fixturesInCompetition(
    String competitionId,
    List<Fixture> allFixtures,
  ) =>
      allFixtures.where((f) => f.competitionId == competitionId).toList();

  static List<TableRow> tableFor(
    String leagueId,
    List<Club> allClubs,
    List<Fixture> allFixtures,
  ) {
    final clubs = clubsInLeague(leagueId, allClubs);
    final fixtures = fixturesInCompetition(leagueId, allFixtures);
    return SeasonService.computeTable(clubs, fixtures);
  }

  static League? leagueOf(String clubId, List<League> leagues, List<Club> clubs) {
    final club = clubs.where((c) => c.id == clubId).firstOrNull;
    if (club == null) return null;
    return leagues.where((l) => l.id == club.leagueId).firstOrNull;
  }

  static List<PromotionRelegationMove> resolveSeasonEnd({
    required List<Country> countries,
    required List<League> leagues,
    required List<Club> clubs,
    required List<Fixture> fixtures,
  }) {
    final moves = <PromotionRelegationMove>[];

    for (final country in countries) {
      final countryLeagues = leagues.where((l) => l.countryId == country.id).toList()
        ..sort((a, b) => a.tier.compareTo(b.tier));

      for (var i = 0; i < countryLeagues.length - 1; i++) {
        final upperLeague = countryLeagues[i];
        final lowerLeague = countryLeagues[i + 1];

        final upperTable = tableFor(upperLeague.id, clubs, fixtures);
        final lowerTable = tableFor(lowerLeague.id, clubs, fixtures);

        final relegated = upperTable
            .sublist(upperTable.length - upperLeague.relegationSpots)
            .map((r) => r.clubId)
            .toList();
        final promoted = lowerTable
            .take(lowerLeague.promotionSpots)
            .map((r) => r.clubId)
            .toList();

        for (final clubId in relegated) {
          moves.add(PromotionRelegationMove(
            clubId: clubId,
            fromLeagueId: upperLeague.id,
            toLeagueId: lowerLeague.id,
          ));
        }
        for (final clubId in promoted) {
          moves.add(PromotionRelegationMove(
            clubId: clubId,
            fromLeagueId: lowerLeague.id,
            toLeagueId: upperLeague.id,
          ));
        }
      }
    }

    return moves;
  }

  static List<String> continentalQualifiers({
    required List<League> leagues,
    required List<Club> clubs,
    required List<Fixture> fixtures,
  }) {
    final qualifiers = <String>[];
    for (final league in leagues.where((l) => l.continentalQualificationSpots > 0)) {
      final table = tableFor(league.id, clubs, fixtures);
      qualifiers.addAll(
        table.take(league.continentalQualificationSpots).map((r) => r.clubId),
      );
    }
    return qualifiers;
  }
}

class PromotionRelegationMove {
  final String clubId;
  final String fromLeagueId;
  final String toLeagueId;

  const PromotionRelegationMove({
    required this.clubId,
    required this.fromLeagueId,
    required this.toLeagueId,
  });
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
