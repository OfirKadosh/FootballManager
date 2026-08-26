import 'player.dart';

class Club {
  final String id;
  final String name;
  final String shortName;
  final int reputation;
  final int balance;
  final List<Player> squad;

  const Club({
    required this.id,
    required this.name,
    required this.shortName,
    required this.reputation,
    required this.balance,
    required this.squad,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['short_name'] as String,
      reputation: json['reputation'] as int,
      balance: json['balance'] as int? ?? 1000000,
      squad: (json['squad'] as List<dynamic>)
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'short_name': shortName,
        'reputation': reputation,
        'balance': balance,
        'squad': squad.map((p) => p.toJson()).toList(),
      };

  List<Player> get activeSquad => squad.where((p) => !p.retired).toList();

  Club copyWith({List<Player>? squad, int? balance}) => Club(
        id: id,
        name: name,
        shortName: shortName,
        reputation: reputation,
        balance: balance ?? this.balance,
        squad: squad ?? this.squad,
      );
}
