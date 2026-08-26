import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';

enum OfferOutcome { accepted, rejected }

class OfferResult {
  final OfferOutcome outcome;
  final String message;

  const OfferResult(this.outcome, this.message);
}

/// Deliberately simple v1 transfer logic: a selling club accepts an
/// offer if it clears a threshold relative to the player's value, with
/// a little randomness so it's not a pure spreadsheet check. No
/// negotiation rounds/counter-offers yet — see spec's "next layer" notes.
class TransferService {
  static const double acceptThreshold = 0.90;

  static OfferResult evaluateOffer({
    required Player player,
    required int offerAmount,
    required Random rng,
  }) {
    final roll = 0.85 + rng.nextDouble() * 0.3; // 0.85x - 1.15x noise
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

  /// Moves [player] from [sellingClub] to [buyingClub], adjusting
  /// balances. Returns updated (sellingClub, buyingClub).
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
