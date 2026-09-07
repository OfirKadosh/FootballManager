enum TransferOfferStatus { pending, accepted, rejected, withdrawn, countered }
enum TransferOfferDirection { outgoing, incoming } // relative to the managed club

/// A single transfer negotiation. Phase 1 resolved an offer in one
/// function call; Phase 2 makes it a persisted object so a negotiation
/// can span multiple game weeks, be countered, and — once AI-initiated
/// incoming offers are added — appear in the Inbox for the user to
/// respond to.
class TransferOffer {
  final String id;
  final String playerId;
  final String sellingClubId;
  final String buyingClubId;
  final int amount;
  final TransferOfferDirection direction;
  TransferOfferStatus status;
  final int? counterAmount; // set when status == countered
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
