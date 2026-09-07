/// A single division (e.g. "Premier League" tier 1, "Championship"
/// tier 2) within one [Country]. Promotion/relegation pairs are
/// resolved by [WorldService] matching countryId + adjacent tiers —
/// leagues don't reference each other directly, so a league can be
/// added or removed without dangling links.
class League {
  final String id;
  final String countryId;
  final String name;
  final int tier; // 1 = top flight
  final int promotionSpots; // clubs promoted to tier-1 above (0 if tier 1)
  final int relegationSpots; // clubs relegated to tier+1 below (0 if bottom tier)
  final int continentalQualificationSpots; // only meaningful for tier 1

  const League({
    required this.id,
    required this.countryId,
    required this.name,
    required this.tier,
    this.promotionSpots = 2,
    this.relegationSpots = 2,
    this.continentalQualificationSpots = 0,
  });

  factory League.fromJson(Map<String, dynamic> json) => League(
        id: json['id'] as String,
        countryId: json['country_id'] as String,
        name: json['name'] as String,
        tier: json['tier'] as int,
        promotionSpots: json['promotion_spots'] as int? ?? 2,
        relegationSpots: json['relegation_spots'] as int? ?? 2,
        continentalQualificationSpots:
            json['continental_qualification_spots'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'country_id': countryId,
        'name': name,
        'tier': tier,
        'promotion_spots': promotionSpots,
        'relegation_spots': relegationSpots,
        'continental_qualification_spots': continentalQualificationSpots,
      };
}
