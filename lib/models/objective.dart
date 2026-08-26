enum ObjectiveStatus { inProgress, achieved, failed }

class Objective {
  final String id;
  final String description;
  final int targetPosition; // finish at or above this table position
  ObjectiveStatus status;

  Objective({
    required this.id,
    required this.description,
    required this.targetPosition,
    this.status = ObjectiveStatus.inProgress,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'target_position': targetPosition,
        'status': status.name,
      };

  factory Objective.fromJson(Map<String, dynamic> json) => Objective(
        id: json['id'] as String,
        description: json['description'] as String,
        targetPosition: json['target_position'] as int,
        status: ObjectiveStatus.values.byName(
          json['status'] as String? ?? 'inProgress',
        ),
      );
}
