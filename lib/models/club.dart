import 'player.dart';

class Club {
  final String id;
  final String name;
  final String shortName;
  final String leagueId;
  final int reputation;
  final int balance;
  final int stadiumCapacity;
  final int weeklySponsorship;
  final List<Player> squad;

  const Club({
    required this.id,
    required this.name,
    required this.shortName,
    required this.leagueId,
    required this.reputation,
    required this.balance,
    required this.stadiumCapacity,
    required this.weeklySponsorship,
    required this.squad,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['short_name'] as String,
      leagueId: json['league_id'] as String,
      reputation: json['reputation'] as int,
      balance: json['balance'] as int? ?? 1000000,
      stadiumCapacity: json['stadium_capacity'] as int? ?? 15000,
      weeklySponsorship: json['weekly_sponsorship'] as int? ?? 20000,
      squad: (json['squad'] as List<dynamic>)
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'short_name': shortName,
        'league_id': leagueId,
        'reputation': reputation,
        'balance': balance,
        'stadium_capacity': stadiumCapacity,
        'weekly_sponsorship': weeklySponsorship,
        'squad': squad.map((p) => p.toJson()).toList(),
      };

  List<Player> get activeSquad => squad.where((p) => !p.retired).toList();

  List<Player> get availableSquad =>
      squad.where((p) => !p.retired && !p.injured).toList();

  int get weeklyWageBill => squad.fold(
        0,
        (total, p) => total + (p.wage ~/ 38).clamp(0, 1 << 30).toInt(),
      );

  /// Rough attendance-based gate receipts for a single home fixture:
  /// higher reputation clubs fill more of their stadium.
  int estimatedHomeGateReceipts() {
    final attendanceRate = (0.35 + reputation / 150).clamp(0.3, 0.98);
    const ticketPrice = 25;
    return (stadiumCapacity * attendanceRate * ticketPrice).round();
  }

  Club copyWith({
    List<Player>? squad,
    int? balance,
    String? leagueId,
  }) =>
      Club(
        id: id,
        name: name,
        shortName: shortName,
        leagueId: leagueId ?? this.leagueId,
        reputation: reputation,
        balance: balance ?? this.balance,
        stadiumCapacity: stadiumCapacity,
        weeklySponsorship: weeklySponsorship,
        squad: squad ?? this.squad,
      );
}
