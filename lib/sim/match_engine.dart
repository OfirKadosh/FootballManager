import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';
import '../models/tactics.dart';
import 'match_result.dart';
import 'sim_config.dart';

/// Pure, deterministic match simulation: (team_a, team_b, config, seed)
/// -> MatchResult. Mentality and tactical style are both modeled as a
/// home-side-only shift (a known v1 simplification).
class MatchEngine {
  final SimConfig config;

  const MatchEngine(this.config);

  MatchResult simulate({
    required Club home,
    required Club away,
    int? seed,
    List<String>? homeLineupIds,
    List<String>? awayLineupIds,
    double homeMentalityShift = 0.0,
    TacticalStyle? homeStyle,
  }) {
    final usedSeed = seed ?? config.randomSeedFallback;
    final rng = Random(usedSeed);

    final homeSquad = _resolveLineup(home, homeLineupIds);
    final awaySquad = _resolveLineup(away, awayLineupIds);

    final homeRatings = _teamRatings(homeSquad);
    final awayRatings = _teamRatings(awaySquad);

    final styleShift = _styleShift(homeStyle);

    final homeAttack = homeRatings.attack +
        config.homeAdvantage +
        homeMentalityShift +
        styleShift.attack;
    final homeMid = homeRatings.midfield + config.homeAdvantage + styleShift.midfield;
    final homeDefenseBase = homeRatings.defense + styleShift.defense;
    final awayAttack = awayRatings.attack;
    final awayMid = awayRatings.midfield;

    int homeGoals = 0;
    int awayGoals = 0;
    final events = <MatchEvent>[];

    for (var chunk = 0; chunk < config.possessionChunksPerMatch; chunk++) {
      final possessionRoll = rng.nextDouble() * (homeMid + awayMid);
      final homeHasBall = possessionRoll < homeMid;

      final attackingClub = homeHasBall ? home : away;
      final attackingSquad = homeHasBall ? homeSquad : awaySquad;
      final defendingRating =
          homeHasBall ? awayRatings.defense : homeDefenseBase - homeMentalityShift;
      final attackingRating = homeHasBall ? homeAttack : awayAttack;

      final chanceThreshold =
          attackingRating / (attackingRating + defendingRating);
      if (rng.nextDouble() > chanceThreshold) {
        continue;
      }

      final scorer = _pickScorer(attackingSquad, rng);
      if (scorer == null) continue;

      final finishingModifier = _playerEffectiveRating(
        scorer,
        config,
        pick: (a) => a.shooting,
      );
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

  _StyleShift _styleShift(TacticalStyle? style) {
    switch (style) {
      case TacticalStyle.highPress:
        return const _StyleShift(attack: 1, midfield: -1, defense: 4);
      case TacticalStyle.counterAttack:
        return const _StyleShift(attack: 4, midfield: -2, defense: 0);
      case TacticalStyle.possession:
      case null:
        return const _StyleShift(attack: 0, midfield: 4, defense: 0);
    }
  }

  List<Player> _resolveLineup(Club club, List<String>? lineupIds) {
    if (lineupIds == null || lineupIds.isEmpty) return club.availableSquad;
    final byId = {for (final p in club.availableSquad) p.id: p};
    final resolved = lineupIds
        .map((id) => byId[id])
        .whereType<Player>()
        .toList();
    return resolved.isEmpty ? club.availableSquad : resolved;
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

    double avgOf(List<Player> group, double Function(Player) pick) {
      final pool = group.isNotEmpty ? group : squad;
      final total = pool.map(pick).reduce((a, b) => a + b);
      return total / pool.length;
    }

    return _TeamRatings(
      attack: avgOf(
        attackers,
        (p) => _playerEffectiveRating(p, config, pick: (a) => a.shooting) * 0.7 +
            _playerEffectiveRating(p, config, pick: (a) => a.dribbling) * 0.3,
      ),
      midfield: avgOf(
        midfielders,
        (p) => _playerEffectiveRating(p, config, pick: (a) => a.passing) * 0.6 +
            _playerEffectiveRating(p, config, pick: (a) => a.workRate) * 0.4,
      ),
      defense: avgOf(
        defenders,
        (p) => _playerEffectiveRating(p, config, pick: (a) => a.tackling) * 0.6 +
            _playerEffectiveRating(p, config, pick: (a) => a.physical) * 0.4,
      ),
    );
  }

  Player? _pickScorer(List<Player> squad, Random rng) {
    final candidates =
        squad.where((p) => p.position != Position.gk).toList();
    if (candidates.isEmpty) return null;
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
    required int Function(PlayerAttributes) pick,
  }) {
    final base = pick(p.attributes).toDouble();
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

class _StyleShift {
  final double attack;
  final double midfield;
  final double defense;

  const _StyleShift({
    required this.attack,
    required this.midfield,
    required this.defense,
  });
}
