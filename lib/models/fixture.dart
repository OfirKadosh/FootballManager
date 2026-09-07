class Fixture {
  final String id;
  final String competitionId; // a League.id (continental cup added in a later phase)
  final int round; // matchday number, 1-indexed, within its competition
  final String homeClubId;
  final String awayClubId;
  final int? homeGoals; // null until played
  final int? awayGoals;

  const Fixture({
    required this.id,
    required this.competitionId,
    required this.round,
    required this.homeClubId,
    required this.awayClubId,
    this.homeGoals,
    this.awayGoals,
  });

  bool get isPlayed => homeGoals != null && awayGoals != null;

  Fixture withResult(int homeGoals, int awayGoals) => Fixture(
        id: id,
        competitionId: competitionId,
        round: round,
        homeClubId: homeClubId,
        awayClubId: awayClubId,
        homeGoals: homeGoals,
        awayGoals: awayGoals,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'competition_id': competitionId,
        'round': round,
        'home_club_id': homeClubId,
        'away_club_id': awayClubId,
        'home_goals': homeGoals,
        'away_goals': awayGoals,
      };

  factory Fixture.fromJson(Map<String, dynamic> json) => Fixture(
        id: json['id'] as String,
        // Older (Phase 1) saves have no competition_id — everything
        // was one implicit league. Give it a stable default so old
        // saves still load; SeasonService always sets this explicitly
        // for new fixtures.
        competitionId: json['competition_id'] as String? ?? 'legacy_league',
        round: json['round'] as int,
        homeClubId: json['home_club_id'] as String,
        awayClubId: json['away_club_id'] as String,
        homeGoals: json['home_goals'] as int?,
        awayGoals: json['away_goals'] as int?,
      );
}
