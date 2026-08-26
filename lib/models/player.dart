enum Position { gk, def, mid, fwd }

class PlayerAttributes {
  final int pace;
  final int shooting;
  final int passing;
  final int defending;
  final int physical;
  final int goalkeeping;

  const PlayerAttributes({
    required this.pace,
    required this.shooting,
    required this.passing,
    required this.defending,
    required this.physical,
    required this.goalkeeping,
  });

  factory PlayerAttributes.fromJson(Map<String, dynamic> json) {
    return PlayerAttributes(
      pace: json['pace'] as int,
      shooting: json['shooting'] as int,
      passing: json['passing'] as int,
      defending: json['defending'] as int,
      physical: json['physical'] as int,
      goalkeeping: json['goalkeeping'] as int,
    );
  }
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
  final int fitness; // 0-100
  final int morale; // 0-100
  final bool retired;
  final int wage; // per-season wage, in currency units
  final int value; // market value, in currency units

  const Player({
    required this.id,
    required this.name,
    required this.nationality,
    required this.position,
    required this.attributes,
    this.fitness = 100,
    this.morale = 70,
    this.retired = false,
    this.wage = 1000,
    this.value = 100000,
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
      retired: json['retired'] as bool? ?? false,
      wage: json['wage'] as int? ?? 1000,
      value: json['value'] as int? ?? 100000,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nationality': nationality,
        'position': position.name,
        'attributes': {
          'pace': attributes.pace,
          'shooting': attributes.shooting,
          'passing': attributes.passing,
          'defending': attributes.defending,
          'physical': attributes.physical,
          'goalkeeping': attributes.goalkeeping,
        },
        'fitness': fitness,
        'morale': morale,
        'retired': retired,
        'wage': wage,
        'value': value,
      };

  int get overallRating {
    switch (position) {
      case Position.gk:
        return attributes.goalkeeping;
      case Position.def:
        return attributes.defending;
      case Position.mid:
        return attributes.passing;
      case Position.fwd:
        return attributes.shooting;
    }
  }
}
