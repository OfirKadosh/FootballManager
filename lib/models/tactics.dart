enum Formation { f433, f4231, f352 }
enum TacticalStyle { highPress, counterAttack, possession }
enum Mentality { defensive, balanced, attacking }

extension FormationSlots on Formation {
  Map<String, int> get slots {
    switch (this) {
      case Formation.f433:
        return {'def': 4, 'mid': 3, 'fwd': 3};
      case Formation.f4231:
        return {'def': 4, 'mid': 5, 'fwd': 1};
      case Formation.f352:
        return {'def': 3, 'mid': 5, 'fwd': 2};
    }
  }

  String get label {
    switch (this) {
      case Formation.f433:
        return '4-3-3';
      case Formation.f4231:
        return '4-2-3-1';
      case Formation.f352:
        return '3-5-2';
    }
  }
}

class Tactics {
  final Formation formation;
  final TacticalStyle style;
  final Mentality mentality;

  const Tactics({
    this.formation = Formation.f433,
    this.style = TacticalStyle.possession,
    this.mentality = Mentality.balanced,
  });

  Map<String, dynamic> toJson() => {
        'formation': formation.name,
        'style': style.name,
        'mentality': mentality.name,
      };

  factory Tactics.fromJson(Map<String, dynamic> json) => Tactics(
        formation: Formation.values.byName(
          json['formation'] as String? ?? 'f433',
        ),
        style: TacticalStyle.values.byName(
          json['style'] as String? ?? 'possession',
        ),
        mentality: Mentality.values.byName(
          json['mentality'] as String? ?? 'balanced',
        ),
      );

  Tactics copyWith({
    Formation? formation,
    TacticalStyle? style,
    Mentality? mentality,
  }) =>
      Tactics(
        formation: formation ?? this.formation,
        style: style ?? this.style,
        mentality: mentality ?? this.mentality,
      );
}
