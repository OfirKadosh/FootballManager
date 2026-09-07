enum Position { gk, def, mid, fwd }

/// Technical, physical, and mental attributes, matching Phase 2's
/// attribute spec:
///   Technical: passing, shooting, tackling, dribbling, pace
///   Physical:  physical (strength/aerial), staminaRating, injuryProneness
///   Mental:    workRate, leadership
///   (goalkeeping is a technical attribute specific to the GK position)
///
/// Morale and current fitness are NOT here — they're day-to-day state
/// that changes constantly, not a fixed rating. They live on [Player]
/// itself (see below) alongside staminaRating/injuryProneness, which
/// ARE fixed traits that influence how fast fitness/morale move.
class PlayerAttributes {
  // Technical
  final int pace;
  final int shooting;
  final int passing;
  final int tackling;
  final int dribbling;
  final int goalkeeping;
  // Physical
  final int physical; // strength / aerial duels
  final int staminaRating; // how slowly fitness drains during a match
  final int injuryProneness; // 0-100, higher = more injury-prone
  // Mental
  final int workRate;
  final int leadership;

  const PlayerAttributes({
    required this.pace,
    required this.shooting,
    required this.passing,
    required this.tackling,
    required this.dribbling,
    required this.goalkeeping,
    required this.physical,
    required this.staminaRating,
    required this.injuryProneness,
    required this.workRate,
    required this.leadership,
  });

  factory PlayerAttributes.fromJson(Map<String, dynamic> json) {
    // Backward-compatible with Phase 1's 6-attribute sample_pack.json:
    // tackling/dribbling fall back to defending/pace-adjacent values,
    // and the new mental/physical traits default to a neutral value
    // if the source data (e.g. an older content pack) doesn't have them.
    final legacyDefending = json['defending'] as int?;
    return PlayerAttributes(
      pace: json['pace'] as int,
      shooting: json['shooting'] as int,
      passing: json['passing'] as int,
      tackling: json['tackling'] as int? ?? legacyDefending ?? 50,
      dribbling: json['dribbling'] as int? ?? (json['pace'] as int? ?? 50),
      goalkeeping: json['goalkeeping'] as int,
      physical: json['physical'] as int,
      staminaRating: json['stamina_rating'] as int? ?? 60,
      injuryProneness: json['injury_proneness'] as int? ?? 20,
      workRate: json['work_rate'] as int? ?? 55,
      leadership: json['leadership'] as int? ?? 45,
    );
  }

  Map<String, dynamic> toJson() => {
        'pace': pace,
        'shooting': shooting,
        'passing': passing,
        'tackling': tackling,
        'dribbling': dribbling,
        'goalkeeping': goalkeeping,
        'physical': physical,
        'stamina_rating': staminaRating,
        'injury_proneness': injuryProneness,
        'work_rate': workRate,
        'leadership': leadership,
      };
}

/// A player is identified by a stable internal [id] that is never reused.
/// Display data (name, nationality) is kept alongside stats here for
/// simplicity in this skeleton; in the full design this would be split
/// into a separate DisplayIdentity table (see spec §5).
class Player {
  final String id;
  final String name;
  final String nationality;
  final Position position;
  final PlayerAttributes attributes;
  final int fitness; // 0-100, current matchday condition (state, not a fixed rating)
  final int morale; // 0-100 (state)
  final bool injured;
  final int injuryDaysRemaining;
  final bool retired;
  final int wage; // per-season wage, in currency units
  final int value; // market value, in currency units
  final int contractYearsRemaining;

  const Player({
    required this.id,
    required this.name,
    required this.nationality,
    required this.position,
    required this.attributes,
    this.fitness = 100,
    this.morale = 70,
    this.injured = false,
    this.injuryDaysRemaining = 0,
    this.retired = false,
    this.wage = 1000,
    this.value = 100000,
    this.contractYearsRemaining = 2,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      nationality: json['nationality'] as String,
      position: Position.values.byName(json['position'] as String),
      attributes: PlayerAttributes.fromJson(
        json['attributes'] as Map<String, dynamic>,
      ),
      fitness: json['fitness'] as int? ?? 100,
      morale: json['morale'] as int? ?? 70,
      injured: json['injured'] as bool? ?? false,
      injuryDaysRemaining: json['injury_days_remaining'] as int? ?? 0,
      retired: json['retired'] as bool? ?? false,
      wage: json['wage'] as int? ?? 1000,
      value: json['value'] as int? ?? 100000,
      contractYearsRemaining: json['contract_years_remaining'] as int? ?? 2,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nationality': nationality,
        'position': position.name,
        'attributes': attributes.toJson(),
        'fitness': fitness,
        'morale': morale,
        'injured': injured,
        'injury_days_remaining': injuryDaysRemaining,
        'retired': retired,
        'wage': wage,
        'value': value,
        'contract_years_remaining': contractYearsRemaining,
      };

  /// Position-weighted overall, used for lineup auto-pick and AI
  /// transfer valuation. Each position blends more than one attribute
  /// now that the attribute set is richer.
  int get overallRating {
    switch (position) {
      case Position.gk:
        return attributes.goalkeeping;
      case Position.def:
        return ((attributes.tackling * 0.5) +
                (attributes.physical * 0.3) +
                (attributes.passing * 0.2))
            .round();
      case Position.mid:
        return ((attributes.passing * 0.4) +
                (attributes.dribbling * 0.3) +
                (attributes.workRate * 0.3))
            .round();
      case Position.fwd:
        return ((attributes.shooting * 0.5) +
                (attributes.pace * 0.3) +
                (attributes.dribbling * 0.2))
            .round();
    }
  }

  Player copyWith({
    int? fitness,
    int? morale,
    bool? injured,
    int? injuryDaysRemaining,
    int? contractYearsRemaining,
  }) =>
      Player(
        id: id,
        name: name,
        nationality: nationality,
        position: position,
        attributes: attributes,
        fitness: fitness ?? this.fitness,
        morale: morale ?? this.morale,
        injured: injured ?? this.injured,
        injuryDaysRemaining: injuryDaysRemaining ?? this.injuryDaysRemaining,
        retired: retired,
        wage: wage,
        value: value,
        contractYearsRemaining:
            contractYearsRemaining ?? this.contractYearsRemaining,
      );
}
