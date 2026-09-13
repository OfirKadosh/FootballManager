import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/club.dart';
import '../models/country.dart';
import '../models/league.dart';
import '../models/news_item.dart';
import '../models/objective.dart';
import '../models/save_state.dart';
import '../models/tactics.dart';
import '../models/transfer_offer.dart';
import '../services/content_pack_service.dart';
import '../services/data_importer_service.dart';
import '../services/lineup_service.dart';
import '../services/save_service.dart';
import '../services/season_service.dart';
import '../services/transfer_service.dart';
import '../services/world_service.dart';
import '../sim/match_engine.dart';
import '../sim/match_result.dart';

export '../services/transfer_service.dart' show OfferResult, OfferOutcome;

enum AppPhase { loading, needsNewGame, ready }

class GameController extends ChangeNotifier {
  AppPhase phase = AppPhase.loading;
  ContentPack? pack;
  SaveState? save;

  List<MatchResult> lastMatchdayResults = [];

  Future<void> init() async {
    pack = await ContentPackService.loadBundled(
      'assets/content/sample_world_pack.json',
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
    await _startCareer(
      packVersion: pack!.version,
      season: pack!.season,
      countries: pack!.countries,
      leagues: pack!.leagues,
      clubs: pack!.clubs,
      managedClubId: clubId,
    );
  }

  Future<void> startNewGameFromImport(ImportResult imported, String clubId) async {
    await _startCareer(
      packVersion: 'imported-${DateTime.now().millisecondsSinceEpoch}',
      season: pack!.season,
      countries: imported.countries,
      leagues: imported.leagues,
      clubs: imported.clubs,
      managedClubId: clubId,
    );
  }

  Future<void> _startCareer({
    required String packVersion,
    required String season,
    required List<Country> countries,
    required List<League> leagues,
    required List<Club> clubs,
    required String managedClubId,
  }) async {
    final clonedClubs = clubs
        .map((c) => Club(
              id: c.id,
              name: c.name,
              shortName: c.shortName,
              leagueId: c.leagueId,
              reputation: c.reputation,
              balance: c.balance,
              stadiumCapacity: c.stadiumCapacity,
              weeklySponsorship: c.weeklySponsorship,
              squad: c.squad,
            ))
        .toList();

    final fixtures = WorldService.generateAllFixtures(leagues, clonedClubs);
    final managedClub = clonedClubs.firstWhere((c) => c.id == managedClubId);
    final lineup = LineupService.autoPick(managedClub);
    final leagueSize = WorldService.clubsInLeague(managedClub.leagueId, clonedClubs).length;
    final objectives = _generateObjectives(managedClub, leagueSize);

    save = SaveState(
      packVersion: packVersion,
      season: season,
      managedClubId: managedClubId,
      currentRound: 1,
      countries: countries,
      leagues: leagues,
      clubs: clonedClubs,
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
      title = 'Finish in the top ${(leagueSize / 2).ceil()}';
      target = (leagueSize / 2).ceil();
    }
    return [
      Objective(id: 'obj_primary', description: title, targetPosition: target),
      Objective(
        id: 'obj_safety',
        description: 'Avoid relegation',
        targetPosition: leagueSize - 1,
      ),
    ];
  }

  bool get canPlayMatchday =>
      save != null && !save!.seasonComplete && save!.hasFixturesRemaining;

  List<TableRow> get table => WorldService.tableFor(
        save!.managedClub.leagueId,
        save!.clubs,
        save!.fixtures,
      );

  int get managedClubPosition =>
      SeasonService.tablePositionOf(save!.managedClubId, table);

  Future<void> playNextMatchday() async {
    final s = save!;
    if (!canPlayMatchday) return;

    final roundFixtures = s.fixtures.where((f) => f.round == s.currentRound).toList();
    final engine = MatchEngine(pack!.simConfig);
    final results = <MatchResult>[];
    final playedPlayerIds = <String>{};

    for (final fixture in roundFixtures) {
      final home = s.clubById(fixture.homeClubId);
      final away = s.clubById(fixture.awayClubId);

      final homeIsManaged = home.id == s.managedClubId;
      final awayIsManaged = away.id == s.managedClubId;

      final homeLineup = homeIsManaged ? s.lineup : LineupService.autoPick(home);
      final awayLineup = awayIsManaged ? s.lineup : LineupService.autoPick(away);

      final result = engine.simulate(
        home: home,
        away: away,
        seed: s.matchSeedCounter++,
        homeLineupIds: homeLineup,
        awayLineupIds: awayLineup,
        homeMentalityShift:
            homeIsManaged ? _mentalityShift(s.tactics.mentality) : 0.0,
        homeStyle: homeIsManaged ? s.tactics.style : null,
      );
      results.add(result);
      playedPlayerIds.addAll(homeLineup);
      playedPlayerIds.addAll(awayLineup);

      final updatedFixture = fixture.withResult(result.homeGoals, result.awayGoals);
      final idx = s.fixtures.indexWhere((f) => f.id == fixture.id);
      s.fixtures[idx] = updatedFixture;

      if (homeIsManaged || awayIsManaged) {
        _applyMatchFinances(home: home, away: away);
      }
    }

    _applyFitnessAndInjuries(playedPlayerIds);
    lastMatchdayResults = results;
    s.currentRound++;

    _postManagedClubNews(results);

    if (!s.hasFixturesRemaining) {
      _finalizeSeason();
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

  void _applyFitnessAndInjuries(Set<String> playedPlayerIds) {
    final s = save!;
    final rng = Random(s.matchSeedCounter++);

    for (var ci = 0; ci < s.clubs.length; ci++) {
      final club = s.clubs[ci];
      final updatedSquad = club.squad.map((p) {
        if (p.retired) return p;
        if (playedPlayerIds.contains(p.id)) {
          final drain = (12 - (p.attributes.staminaRating / 12)).clamp(4, 12).round();
          final newFitness = (p.fitness - drain).clamp(30, 100).toInt();

          final injuryRoll = rng.nextDouble() * 100;
          final injuryThreshold = p.attributes.injuryProneness / 25;
          if (injuryRoll < injuryThreshold) {
            return p.copyWith(
              fitness: newFitness,
              injured: true,
              injuryDaysRemaining: 7 + rng.nextInt(21),
            );
          }
          return p.copyWith(fitness: newFitness);
        }
        final recovered = (p.fitness + 8).clamp(0, 100).toInt();
        if (p.injured) {
          final remaining = p.injuryDaysRemaining - 7;
          return p.copyWith(
            fitness: recovered,
            injured: remaining > 0,
            injuryDaysRemaining: remaining > 0 ? remaining : 0,
          );
        }
        return p.copyWith(fitness: recovered);
      }).toList();
      s.clubs[ci] = club.copyWith(squad: updatedSquad);
    }
  }

  void _applyMatchFinances({required Club home, required Club away}) {
    final s = save!;
    final gate = home.estimatedHomeGateReceipts();
    final updatedHome = s.clubById(home.id).copyWith(
          balance: s.clubById(home.id).balance +
              gate +
              home.weeklySponsorship -
              home.weeklyWageBill,
        );
    final updatedAway = s.clubById(away.id).copyWith(
          balance: s.clubById(away.id).balance +
              away.weeklySponsorship -
              away.weeklyWageBill,
        );
    s.replaceClub(updatedHome);
    s.replaceClub(updatedAway);
  }

  void _postManagedClubNews(List<MatchResult> results) {
    final s = save!;
    final own = results.cast<MatchResult?>().firstWhere(
          (r) => r!.homeClubId == s.managedClubId || r.awayClubId == s.managedClubId,
          orElse: () => null,
        );
    if (own == null) return;
    final home = s.clubById(own.homeClubId);
    final away = s.clubById(own.awayClubId);
    s.addNews(NewsItem(
      id: 'news_${s.matchSeedCounter}',
      category: NewsCategory.matchResult,
      headline: '${home.name} ${own.scoreline} ${away.name}',
      body: own.events.isEmpty
          ? 'A quiet one — no goals from either side.'
          : own.events.map((e) => e.toString()).join('\n'),
      gameWeek: s.currentRound - 1,
    ));
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
      s.addNews(NewsItem(
        id: 'news_obj_${obj.id}',
        category: NewsCategory.objective,
        headline: obj.status == ObjectiveStatus.achieved
            ? 'Objective achieved: ${obj.description}'
            : 'Objective missed: ${obj.description}',
        body: 'Final league position: $position.',
        gameWeek: s.currentRound,
      ));
    }

    final moves = WorldService.resolveSeasonEnd(
      countries: s.countries,
      leagues: s.leagues,
      clubs: s.clubs,
      fixtures: s.fixtures,
    );
    for (final move in moves) {
      final club = s.clubById(move.clubId);
      s.replaceClub(club.copyWith(leagueId: move.toLeagueId));
      final movingUp = s.leagues.firstWhere((l) => l.id == move.toLeagueId).tier <
          s.leagues.firstWhere((l) => l.id == move.fromLeagueId).tier;
      if (club.id == s.managedClubId) {
        s.addNews(NewsItem(
          id: 'news_promrel_${move.clubId}',
          category: NewsCategory.promotionRelegation,
          headline: movingUp ? 'Promoted!' : 'Relegated',
          body: movingUp
              ? '${club.name} have been promoted to a higher division.'
              : '${club.name} have been relegated to a lower division.',
          gameWeek: s.currentRound,
        ));
      }
    }
  }

  Future<void> setTactics(Tactics tactics) async {
    save!.tactics = tactics;
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

  Future<void> autoFillLineup() async {
    final s = save!;
    s.lineup = LineupService.autoPick(s.managedClub, formation: s.tactics.formation);
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

    final offer = TransferOffer(
      id: 'offer_${s.matchSeedCounter}',
      playerId: playerId,
      sellingClubId: sellingClubId,
      buyingClubId: buyingClub.id,
      amount: amount,
      direction: TransferOfferDirection.outgoing,
      gameWeekCreated: s.currentRound,
      status: result.outcome == OfferOutcome.accepted
          ? TransferOfferStatus.accepted
          : TransferOfferStatus.rejected,
    );
    s.transferOffers.add(offer);

    if (result.outcome == OfferOutcome.accepted) {
      final (updatedSelling, updatedBuying) = TransferService.completeTransfer(
        sellingClub: sellingClub,
        buyingClub: buyingClub,
        player: player,
        amount: amount,
      );
      s.replaceClub(updatedSelling);
      s.replaceClub(updatedBuying);
      s.addNews(NewsItem(
        id: 'news_${offer.id}',
        category: NewsCategory.transfer,
        headline: '${player.name} signed',
        body: '${buyingClub.name} completed the signing of ${player.name} '
            'from ${sellingClub.name} for \$$amount.',
        gameWeek: s.currentRound,
      ));
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
      s.lineup = List.from(s.lineup)..remove(playerId);
      s.addNews(NewsItem(
        id: 'news_sell_${player.id}_${s.currentRound}',
        category: NewsCategory.transfer,
        headline: '${player.name} sold',
        body: '${buyingClub.name} bought ${player.name} for \$$askingPrice.',
        gameWeek: s.currentRound,
      ));
      await SaveService.save(s);
      notifyListeners();
      return OfferResult(
        OfferOutcome.accepted,
        '${buyingClub.name} bought ${player.name} for \$$askingPrice.',
      );
    }
    return result;
  }

  Future<void> markNewsRead(String newsId) async {
    final s = save!;
    final item = s.inbox.firstWhere((n) => n.id == newsId);
    item.read = true;
    await SaveService.save(s);
    notifyListeners();
  }

  Future<void> abandonCareer() async {
    await SaveService.deleteSave();
    save = null;
    phase = AppPhase.needsNewGame;
    notifyListeners();
  }
}
