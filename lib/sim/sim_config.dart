/// All tunable weights for the match engine. This is the piece that
/// ships inside a versioned content pack (not hardcoded in the app),
/// so balance changes don't require an app store release.
/// See spec §6.
class SimConfig {
  final int possessionChunksPerMatch;
  final double homeAdvantage; // additive bonus to home attack/midfield
  final double chanceConversionBaseline; // baseline chance a chance scores
  final double fitnessImpact; // how much low fitness hurts a rating
  final double moraleImpact; // how much low morale hurts a rating
  final int randomSeedFallback;

  const SimConfig({
    this.possessionChunksPerMatch = 20,
    this.homeAdvantage = 3.0,
    this.chanceConversionBaseline = 0.30,
    this.fitnessImpact = 0.15,
    this.moraleImpact = 0.10,
    this.randomSeedFallback = 1337,
  });

  factory SimConfig.fromJson(Map<String, dynamic> json) {
    return SimConfig(
      possessionChunksPerMatch: json['possession_chunks_per_match'] as int? ?? 20,
      homeAdvantage: (json['home_advantage'] as num?)?.toDouble() ?? 3.0,
      chanceConversionBaseline:
          (json['chance_conversion_baseline'] as num?)?.toDouble() ?? 0.30,
      fitnessImpact: (json['fitness_impact'] as num?)?.toDouble() ?? 0.15,
      moraleImpact: (json['morale_impact'] as num?)?.toDouble() ?? 0.10,
      randomSeedFallback: json['random_seed_fallback'] as int? ?? 1337,
    );
  }
}
