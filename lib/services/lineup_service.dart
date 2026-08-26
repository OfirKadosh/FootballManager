import '../models/club.dart';
import '../models/player.dart';

/// Picks a starting XI in a fixed 4-3-3 (1 GK, 4 DEF, 3 MID, 3 FWD),
/// choosing the highest-rated available (non-retired) player per slot
/// by fitness-adjusted overall rating. This is the v1 auto-pick; a
/// manual lineup editor can override individual slots later.
class LineupService {
  static const formation = {
    Position.gk: 1,
    Position.def: 4,
    Position.mid: 3,
    Position.fwd: 3,
  };

  static List<String> autoPick(Club club) {
    final squad = List<Player>.from(club.activeSquad);
    final picked = <String>[];

    for (final entry in formation.entries) {
      final pool = squad.where((p) => p.position == entry.key).toList()
        ..sort((a, b) => _score(b).compareTo(_score(a)));
      final take = pool.take(entry.value);
      picked.addAll(take.map((p) => p.id));
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
      p.overallRating * (0.7 + 0.3 * p.fitness / 100);
}
