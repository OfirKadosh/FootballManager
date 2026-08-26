import '../models/club.dart';
import '../models/fixture.dart';

class TableRow {
  final String clubId;
  int played = 0;
  int won = 0;
  int drawn = 0;
  int lost = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;

  TableRow(this.clubId);

  int get points => won * 3 + drawn;
  int get goalDifference => goalsFor - goalsAgainst;
}

class SeasonService {
  /// Generates a double round-robin fixture list (home & away) for an
  /// even number of clubs using the standard circle method.
  static List<Fixture> generateRoundRobin(List<Club> clubs) {
    final ids = clubs.map((c) => c.id).toList();
    assert(ids.length.isEven, 'Round robin requires an even number of clubs');

    final n = ids.length;
    final rounds = n - 1;
    final half = n ~/ 2;
    final fixtures = <Fixture>[];
    var rotating = ids.sublist(1); // keep ids[0] fixed, rotate the rest

    var fixtureCounter = 0;

    for (var round = 0; round < rounds; round++) {
      final roundIds = [ids[0], ...rotating];
      for (var i = 0; i < half; i++) {
        final a = roundIds[i];
        final b = roundIds[n - 1 - i];
        // Alternate home/away by round parity so it's not always the
        // same side at home in the first leg.
        final home = (round.isEven) ? a : b;
        final away = (round.isEven) ? b : a;
        fixtures.add(Fixture(
          id: 'f${fixtureCounter++}',
          round: round + 1,
          homeClubId: home,
          awayClubId: away,
        ));
      }
      // Rotate: move last element to just after the fixed first id.
      final last = rotating.removeLast();
      rotating.insert(0, last);
    }

    // Second leg: same pairings, home/away swapped, appended as
    // further rounds.
    final firstLeg = List<Fixture>.from(fixtures);
    for (final f in firstLeg) {
      fixtures.add(Fixture(
        id: 'f${fixtureCounter++}',
        round: f.round + rounds,
        homeClubId: f.awayClubId,
        awayClubId: f.homeClubId,
      ));
    }

    return fixtures;
  }

  /// Computes a sorted league table (points, then goal difference,
  /// then goals for) from played fixtures.
  static List<TableRow> computeTable(List<Club> clubs, List<Fixture> fixtures) {
    final rows = {for (final c in clubs) c.id: TableRow(c.id)};

    for (final f in fixtures.where((f) => f.isPlayed)) {
      final home = rows[f.homeClubId]!;
      final away = rows[f.awayClubId]!;
      home.played++;
      away.played++;
      home.goalsFor += f.homeGoals!;
      home.goalsAgainst += f.awayGoals!;
      away.goalsFor += f.awayGoals!;
      away.goalsAgainst += f.homeGoals!;

      if (f.homeGoals! > f.awayGoals!) {
        home.won++;
        away.lost++;
      } else if (f.homeGoals! < f.awayGoals!) {
        away.won++;
        home.lost++;
      } else {
        home.drawn++;
        away.drawn++;
      }
    }

    final sorted = rows.values.toList()
      ..sort((a, b) {
        if (b.points != a.points) return b.points - a.points;
        if (b.goalDifference != a.goalDifference) {
          return b.goalDifference - a.goalDifference;
        }
        return b.goalsFor - a.goalsFor;
      });
    return sorted;
  }

  static int tablePositionOf(String clubId, List<TableRow> table) {
    return table.indexWhere((r) => r.clubId == clubId) + 1; // 1-indexed
  }
}
