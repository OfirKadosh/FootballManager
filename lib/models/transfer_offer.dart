enum TransferOfferStatus { pending, accepted, rejected, withdrawn, countered }
enum TransferOfferDirection { outgoing, incoming }

class TransferOffer {
  final String id;
  final String playerId;
  final String sellingClubId;
  final String buyingClubId;
  final int amount;
  final TransferOfferDirection direction;
  TransferOfferStatus status;
  final int? counterAmount;
  final int gameWeekCreated;

  TransferOffer({
    required this.id,
    required this.playerId,
    required this.sellingClubId,
    required this.buyingClubId,
    required this.amount,
    required this.direction,
    required this.gameWeekCreated,
    this.status = TransferOfferStatus.pending,
    this.counterAmount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'player_id': playerId,
        'selling_club_id': sellingClubId,
        'buying_club_id': buyingClubId,
        'amount': amount,
        'direction': direction.name,
        'status': status.name,
        'counter_amount': counterAmount,
        'game_week_created': gameWeekCreated,
      };

  factory TransferOffer.fromJson(Map<String, dynamic> json) => TransferOffer(
        id: json['id'] as String,
        playerId: json['player_id'] as String,
        sellingClubId: json['selling_club_id'] as String,
        buyingClubId: json['buying_club_id'] as String,
        amount: json['amount'] as int,
        direction: TransferOfferDirection.values.byName(
          json['direction'] as String,
        ),
        gameWeekCreated: json['game_week_created'] as int,
        status: TransferOfferStatus.values.byName(
          json['status'] as String? ?? 'pending',
        ),
        counterAmount: json['counter_amount'] as int?,
      );
}
