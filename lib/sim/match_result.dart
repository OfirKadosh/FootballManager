enum MatchEventType { goal, yellowCard, redCard, injury }

class MatchEvent {
  final int chunk; // which possession chunk this happened in (proxy for time)
  final String clubId;
  final String playerId;
  final MatchEventType type;

  const MatchEvent({
    required this.chunk,
    required this.clubId,
    required this.playerId,
    required this.type,
  });

  @override
  String toString() {
    final minute = (chunk * (90 / 20)).round();
    return "$minute' ${type.name} — $playerId ($clubId)";
  }
}

class MatchResult {
  final String homeClubId;
  final String awayClubId;
  final int homeGoals;
  final int awayGoals;
  final List<MatchEvent> events;
  final int seedUsed;

  const MatchResult({
    required this.homeClubId,
    required this.awayClubId,
    required this.homeGoals,
    required this.awayGoals,
    required this.events,
    required this.seedUsed,
  });

  String get scoreline => '$homeGoals - $awayGoals';
}
