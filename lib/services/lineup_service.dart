import '../models/club.dart';
import '../models/player.dart';
import '../models/tactics.dart';

/// Picks a starting XI for a given [Formation], choosing the
/// highest-rated available (non-retired, non-injured) player per slot
/// by fitness-adjusted overall rating. This is the auto-pick; a manual
/// lineup editor can override individual slots on top of this.
class LineupService {
  static List<String> autoPick(Club club, {Formation formation = Formation.f433}) {
    final squad = List<Player>.from(club.availableSquad);
    final picked = <String>[];

    final gkPool = squad.where((p) => p.position == Position.gk).toList()
      ..sort((a, b) => _score(b).compareTo(_score(a)));
    if (gkPool.isNotEmpty) picked.add(gkPool.first.id);

    const positionByKey = {
      'def': Position.def,
      'mid': Position.mid,
      'fwd': Position.fwd,
    };

    for (final entry in formation.slots.entries) {
      final position = positionByKey[entry.key]!;
      final pool = squad
          .where((p) => p.position == position && !picked.contains(p.id))
          .toList()
        ..sort((a, b) => _score(b).compareTo(_score(a)));
      picked.addAll(pool.take(entry.value).map((p) => p.id));
    }

    // If a position group is short (small squad), fill remaining slots
    // from whoever's left, best-rated first.
    final remaining = 11 - picked.length;
    if (remaining > 0) {
      final leftover = squad.where((p) => !picked.contains(p.id)).toList()
        ..sort((a, b) => _score(b).compareTo(_score(a)));
      picked.addAll(leftover.take(remaining).map((p) => p.id));
    }

    return picked;
  }

  static double _score(Player p) =>
      p.overallRating * (0.7 + 0.3 * p.fitness / 100) * (0.85 + 0.15 * p.morale / 100);
}
