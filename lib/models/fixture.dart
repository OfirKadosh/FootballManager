class Fixture {
  final String id;
  final int round; // matchday number, 1-indexed
  final String homeClubId;
  final String awayClubId;
  final int? homeGoals; // null until played
  final int? awayGoals;

  const Fixture({
    required this.id,
    required this.round,
    required this.homeClubId,
    required this.awayClubId,
    this.homeGoals,
    this.awayGoals,
  });

  bool get isPlayed => homeGoals != null && awayGoals != null;

  Fixture withResult(int homeGoals, int awayGoals) => Fixture(
        id: id,
        round: round,
        homeClubId: homeClubId,
        awayClubId: awayClubId,
        homeGoals: homeGoals,
        awayGoals: awayGoals,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'round': round,
        'home_club_id': homeClubId,
        'away_club_id': awayClubId,
        'home_goals': homeGoals,
        'away_goals': awayGoals,
      };

  factory Fixture.fromJson(Map<String, dynamic> json) => Fixture(
        id: json['id'] as String,
        round: json['round'] as int,
        homeClubId: json['home_club_id'] as String,
        awayClubId: json['away_club_id'] as String,
        homeGoals: json['home_goals'] as int?,
        awayGoals: json['away_goals'] as int?,
      );
}
