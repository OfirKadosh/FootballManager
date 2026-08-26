import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';
import 'match_result.dart';
import 'sim_config.dart';

/// Pure, deterministic match simulation: (team_a, team_b, config, seed)
/// -> MatchResult. Same inputs always produce the same output, which
/// makes results testable and reproducible. See spec §6.
///
/// The algorithm itself is intentionally simple and coarse (possession
/// "chunks" rather than minute-by-minute simulation) — it's a v1
/// skeleton meant to be tuned via [SimConfig], not a final balance.
class MatchEngine {
  final SimConfig config;

  const MatchEngine(this.config);

  /// [homeLineupIds]/[awayLineupIds] restrict which players are used to
  /// compute ratings and pick scorers (a chosen starting XI). If null
  /// or empty, falls back to the full active squad. [homeMentality]
  /// nudges the home side's attack/defense balance — attacking trades
  /// defense for attack, defensive trades the other way.
  MatchResult simulate({
    required Club home,
    required Club away,
    int? seed,
    List<String>? homeLineupIds,
    List<String>? awayLineupIds,
    double homeMentalityShift = 0.0,
  }) {
    final usedSeed = seed ?? config.randomSeedFallback;
    final rng = Random(usedSeed);

    final homeSquad = _resolveLineup(home, homeLineupIds);
    final awaySquad = _resolveLineup(away, awayLineupIds);

    final homeRatings = _teamRatings(homeSquad);
    final awayRatings = _teamRatings(awaySquad);

    // Home advantage applies to attack and midfield only. Mentality
    // shifts attack up and defense down (or vice versa) for the home
    // side only — a simple v1 tactical lever.
    final homeAttack =
        homeRatings.attack + config.homeAdvantage + homeMentalityShift;
    final homeMid = homeRatings.midfield + config.homeAdvantage;
    final awayAttack = awayRatings.attack;
    final awayMid = awayRatings.midfield;

    int homeGoals = 0;
    int awayGoals = 0;
    final events = <MatchEvent>[];

    for (var chunk = 0; chunk < config.possessionChunksPerMatch; chunk++) {
      // Who has possession this chunk, weighted by midfield strength.
      final possessionRoll = rng.nextDouble() * (homeMid + awayMid);
      final homeHasBall = possessionRoll < homeMid;

      final attackingClub = homeHasBall ? home : away;
      final attackingSquad = homeHasBall ? homeSquad : awaySquad;
      final defendingRating = homeHasBall
          ? awayRatings.defense
          : homeRatings.defense - homeMentalityShift;
      final attackingRating = homeHasBall ? homeAttack : awayAttack;

      // Does possession produce a scoring chance?
      final chanceThreshold =
          attackingRating / (attackingRating + defendingRating);
      if (rng.nextDouble() > chanceThreshold) {
        continue; // no chance created this chunk
      }

      // Does the chance convert to a goal?
      final scorer = _pickScorer(attackingSquad, rng);
      if (scorer == null) continue;

      final finishingModifier = _playerEffectiveRating(scorer, config);
      final conversionChance = (config.chanceConversionBaseline +
              (finishingModifier - 50) / 200)
          .clamp(0.05, 0.75);

      if (rng.nextDouble() < conversionChance) {
        if (homeHasBall) {
          homeGoals++;
        } else {
          awayGoals++;
        }
        events.add(MatchEvent(
          chunk: chunk,
          clubId: attackingClub.id,
          playerId: scorer.id,
          type: MatchEventType.goal,
        ));
      }
    }

    return MatchResult(
      homeClubId: home.id,
      awayClubId: away.id,
      homeGoals: homeGoals,
      awayGoals: awayGoals,
      events: events,
      seedUsed: usedSeed,
    );
  }

  List<Player> _resolveLineup(Club club, List<String>? lineupIds) {
    if (lineupIds == null || lineupIds.isEmpty) return club.activeSquad;
    final byId = {for (final p in club.activeSquad) p.id: p};
    final resolved = lineupIds
        .map((id) => byId[id])
        .whereType<Player>()
        .toList();
    return resolved.isEmpty ? club.activeSquad : resolved;
  }

  _TeamRatings _teamRatings(List<Player> squad) {
    if (squad.isEmpty) {
      return const _TeamRatings(attack: 1, midfield: 1, defense: 1);
    }
    final attackers =
        squad.where((p) => p.position == Position.fwd).toList();
    final midfielders =
        squad.where((p) => p.position == Position.mid).toList();
    final defenders = squad
        .where((p) =>
            p.position == Position.def || p.position == Position.gk)
        .toList();

    double avgOf(List<Player> group, int Function(PlayerAttributes) pick) {
      final pool = group.isNotEmpty ? group : squad;
      final total = pool
          .map((p) => _playerEffectiveRating(p, config, pick: pick))
          .reduce((a, b) => a + b);
      return total / pool.length;
    }

    return _TeamRatings(
      attack: avgOf(attackers, (a) => a.shooting),
      midfield: avgOf(midfielders, (a) => a.passing),
      defense: avgOf(defenders, (a) => a.defending),
    );
  }

  Player? _pickScorer(List<Player> squad, Random rng) {
    final candidates =
        squad.where((p) => p.position != Position.gk).toList();
    if (candidates.isEmpty) return null;
    // Weight by shooting attribute so strikers are more likely scorers.
    final weights = candidates.map((p) => p.attributes.shooting).toList();
    final total = weights.reduce((a, b) => a + b);
    var roll = rng.nextDouble() * total;
    for (var i = 0; i < candidates.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return candidates[i];
    }
    return candidates.last;
  }

  static double _playerEffectiveRating(
    Player p,
    SimConfig config, {
    int Function(PlayerAttributes)? pick,
  }) {
    final base = (pick ?? (a) => a.shooting)(p.attributes).toDouble();
    final fitnessPenalty = (100 - p.fitness) / 100 * config.fitnessImpact * base;
    final moralePenalty = (100 - p.morale) / 100 * config.moraleImpact * base;
    return base - fitnessPenalty - moralePenalty;
  }
}

class _TeamRatings {
  final double attack;
  final double midfield;
  final double defense;

  const _TeamRatings({
    required this.attack,
    required this.midfield,
    required this.defense,
  });
}
