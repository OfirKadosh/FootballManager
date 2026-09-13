import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';

enum OfferOutcome { accepted, rejected }

class OfferResult {
  final OfferOutcome outcome;
  final String message;

  const OfferResult(this.outcome, this.message);
}

class TransferService {
  static const double acceptThreshold = 0.90;

  static OfferResult evaluateOffer({
    required Player player,
    required int offerAmount,
    required Random rng,
  }) {
    final roll = 0.85 + rng.nextDouble() * 0.3;
    final requiredAmount = player.value * acceptThreshold * roll;

    if (offerAmount >= requiredAmount) {
      return const OfferResult(
        OfferOutcome.accepted,
        'Offer accepted.',
      );
    }
    return OfferResult(
      OfferOutcome.rejected,
      'Offer rejected — they want closer to \$${player.value}.',
    );
  }

  static (Club, Club) completeTransfer({
    required Club sellingClub,
    required Club buyingClub,
    required Player player,
    required int amount,
  }) {
    final updatedSellingSquad =
        sellingClub.squad.where((p) => p.id != player.id).toList();
    final updatedBuyingSquad = [...buyingClub.squad, player];

    final updatedSelling = sellingClub.copyWith(
      squad: updatedSellingSquad,
      balance: sellingClub.balance + amount,
    );
    final updatedBuying = buyingClub.copyWith(
      squad: updatedBuyingSquad,
      balance: buyingClub.balance - amount,
    );

    return (updatedSelling, updatedBuying);
  }
}
