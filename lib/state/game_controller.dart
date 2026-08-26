import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/club.dart';
import '../models/objective.dart';
import '../models/save_state.dart';
import '../services/content_pack_service.dart';
import '../services/lineup_service.dart';
import '../services/save_service.dart';
import '../services/season_service.dart';
import '../services/transfer_service.dart';
export '../services/transfer_service.dart' show OfferResult, OfferOutcome;
import '../sim/match_engine.dart';
import '../sim/match_result.dart';

enum AppPhase { loading, needsNewGame, ready }

class GameController extends ChangeNotifier {
  AppPhase phase = AppPhase.loading;
  ContentPack? pack;
  SaveState? save;

  /// Results from the matchday just played, for the "match result"
  /// screen. Transient — not persisted.
  List<MatchResult> lastMatchdayResults = [];
  String? lastTransferMessage;

  Future<void> init() async {
    pack = await ContentPackService.loadBundled(
      'assets/content/sample_pack.json',
    );
    final hasSave = await SaveService.hasSave();
    if (hasSave) {
      save = await SaveService.load();
      phase = AppPhase.ready;
    } else {
      phase = AppPhase.needsNewGame;
    }
    notifyListeners();
  }

  List<Club> get availableClubs => pack!.clubs;

  Future<void> startNewGame(String clubId) async {
    final clubs = pack!.clubs
        .map((c) => Club(
              id: c.id,
              name: c.name,
              shortName: c.shortName,
              reputation: c.reputation,
              balance: c.balance,
              squad: c.squad,
            ))
        .toList();

    final fixtures = SeasonService.generateRoundRobin(clubs);
    final managedClub = clubs.firstWhere((c) => c.id == clubId);
    final lineup = LineupService.autoPick(managedClub);
    final objectives = _generateObjectives(managedClub, clubs.length);

    save = SaveState(
      packVersion: pack!.version,
      season: pack!.season,
      managedClubId: clubId,
      currentRound: 1,
      clubs: clubs,
      fixtures: fixtures,
      objectives: objectives,
      lineup: lineup,
    );
    phase = AppPhase.ready;
    await SaveService.save(save!);
    notifyListeners();
  }

  List<Objective> _generateObjectives(Club club, int leagueSize) {
    final String title;
    final int target;
    if (club.reputation >= 70) {
      title = 'Win the league title';
      target = 1;
    } else if (club.reputation >= 55) {
      title = 'Finish in the top 3';
      target = 3;
    } else {
      title = 'Finish in the top 6';
      target = 6;
    }
    return [
      Objective(id: 'obj_primary', description: title, targetPosition: target),
      Objective(
        id: 'obj_safety',
        description: 'Avoid finishing bottom of the table',
        targetPosition: leagueSize - 1,
      ),
    ];
  }

  bool get canPlayMatchday =>
      save != null && !save!.seasonComplete && save!.hasFixturesRemaining;

  List<TableRow> get table =>
      SeasonService.computeTable(save!.clubs, save!.fixtures);

  int get managedClubPosition =>
      SeasonService.tablePositionOf(save!.managedClubId, table);

  Future<void> playNextMatchday() async {
    final s = save!;
    if (!canPlayMatchday) return;

    final roundFixtures = s.fixturesForRound(s.currentRound);
    final engine = MatchEngine(pack!.simConfig);
    final results = <MatchResult>[];

    for (final fixture in roundFixtures) {
      final home = s.clubById(fixture.homeClubId);
      final away = s.clubById(fixture.awayClubId);

      final homeIsManaged = home.id == s.managedClubId;
      final awayIsManaged = away.id == s.managedClubId;

      final homeLineup = homeIsManaged ? s.lineup : LineupService.autoPick(home);
      final awayLineup = awayIsManaged ? s.lineup : LineupService.autoPick(away);

      // The engine only models a home-side mentality shift (v1
      // simplification, see MatchEngine docs) — it applies whenever
      // the managed club is at home this fixture, and is a no-op
      // otherwise (awayIsManaged is unused here as a result).
      final result = engine.simulate(
        home: home,
        away: away,
        seed: s.matchSeedCounter++,
        homeLineupIds: homeLineup,
        awayLineupIds: awayLineup,
        homeMentalityShift: homeIsManaged ? _mentalityShift(s.mentality) : 0.0,
      );
      results.add(result);

      final updatedFixture = fixture.withResult(result.homeGoals, result.awayGoals);
      final idx = s.fixtures.indexWhere((f) => f.id == fixture.id);
      s.fixtures[idx] = updatedFixture;
    }

    lastMatchdayResults = results;
    s.currentRound++;

    if (!s.hasFixturesRemaining) {
      _finalizeSeason();
    } else {
      _updateObjectiveProgress();
    }

    await SaveService.save(s);
    notifyListeners();
  }

  double _mentalityShift(Mentality m) {
    switch (m) {
      case Mentality.attacking:
        return 5.0;
      case Mentality.defensive:
        return -5.0;
      case Mentality.balanced:
        return 0.0;
    }
  }

  void _updateObjectiveProgress() {
    // Objectives resolve fully at season end; mid-season this is a
    // no-op placeholder for future "on track / at risk" messaging.
  }

  void _finalizeSeason() {
    final s = save!;
    s.seasonComplete = true;
    final finalTable = table;
    final position = SeasonService.tablePositionOf(s.managedClubId, finalTable);
    for (final obj in s.objectives) {
      obj.status = position <= obj.targetPosition
          ? ObjectiveStatus.achieved
          : ObjectiveStatus.failed;
    }
  }

  Future<void> setMentality(Mentality m) async {
    save!.mentality = m;
    await SaveService.save(save!);
    notifyListeners();
  }

  Future<void> toggleLineupPlayer(String playerId) async {
    final s = save!;
    if (s.lineup.contains(playerId)) {
      s.lineup = List.from(s.lineup)..remove(playerId);
    } else if (s.lineup.length < 11) {
      s.lineup = List.from(s.lineup)..add(playerId);
    }
    await SaveService.save(s);
    notifyListeners();
  }

  Future<OfferResult> buyPlayer({
    required String sellingClubId,
    required String playerId,
    required int amount,
  }) async {
    final s = save!;
    final sellingClub = s.clubById(sellingClubId);
    final buyingClub = s.managedClub;
    final player = sellingClub.squad.firstWhere((p) => p.id == playerId);

    if (amount > buyingClub.balance) {
      return const OfferResult(OfferOutcome.rejected, "You can't afford that.");
    }

    final result = TransferService.evaluateOffer(
      player: player,
      offerAmount: amount,
      rng: Random(s.matchSeedCounter++),
    );

    if (result.outcome == OfferOutcome.accepted) {
      final (updatedSelling, updatedBuying) = TransferService.completeTransfer(
        sellingClub: sellingClub,
        buyingClub: buyingClub,
        player: player,
        amount: amount,
      );
      s.replaceClub(updatedSelling);
      s.replaceClub(updatedBuying);
      await SaveService.save(s);
      notifyListeners();
    }
    return result;
  }

  Future<OfferResult> sellPlayer({
    required String playerId,
    required int askingPrice,
  }) async {
    final s = save!;
    final sellingClub = s.managedClub;
    final player = sellingClub.squad.firstWhere((p) => p.id == playerId);

    final candidates = s.clubs
        .where((c) => c.id != s.managedClubId && c.balance >= askingPrice)
        .toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));

    if (candidates.isEmpty) {
      return const OfferResult(OfferOutcome.rejected, 'No interested buyers at that price.');
    }

    final buyingClub = candidates.first;
    final result = TransferService.evaluateOffer(
      player: player,
      offerAmount: askingPrice,
      rng: Random(s.matchSeedCounter++),
    );

    if (result.outcome == OfferOutcome.accepted) {
      final (updatedSelling, updatedBuying) = TransferService.completeTransfer(
        sellingClub: sellingClub,
        buyingClub: buyingClub,
        player: player,
        amount: askingPrice,
      );
      s.replaceClub(updatedSelling);
      s.replaceClub(updatedBuying);
      // Player leaving might have been in the lineup — remove if so.
      s.lineup = List.from(s.lineup)..remove(playerId);
      await SaveService.save(s);
      notifyListeners();
      return OfferResult(
        OfferOutcome.accepted,
        '${buyingClub.name} bought ${player.name} for \$$askingPrice.',
      );
    }
    return result;
  }

  Future<void> abandonCareer() async {
    await SaveService.deleteSave();
    save = null;
    phase = AppPhase.needsNewGame;
    notifyListeners();
  }
}
