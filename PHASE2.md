# Phase 2 — Architecture Review & Integration Notes

This documents what changed from the Phase 1 single-league skeleton
to the Phase 2 multi-league foundation, file by file, plus what's
still ahead. Read this alongside `football_manager_spec.md` (original
architecture) — this doc only covers the delta.

## Why these changes, in order of how much they ripple

1. **Club needed a `leagueId`** before anything else could exist —
   every other multi-league feature (fixtures, tables, promotion)
   depends on a club knowing which competition it's in.
2. **Fixture needed a `competitionId`** so multiple leagues' matches
   could live in one flat list instead of one implicit division.
3. **SaveState needed a World layer** (`countries`, `leagues`) above
   `clubs` — this is the actual "multi-league support" ask.
4. Everything else (attributes, tactics, transfers-as-objects, news)
   layers on top without touching the World/Fixture backbone.

That ordering matters if you're reviewing the diff: the first three
are structural and everything downstream assumes they're in place.

## File-by-file changes

| File | Change |
|---|---|
| `lib/models/player.dart` | Attribute set expanded to Technical (pace, shooting, passing, tackling, dribbling, goalkeeping) / Physical (physical, staminaRating, injuryProneness) / Mental (workRate, leadership). Added `injured`, `injuryDaysRemaining`, `contractYearsRemaining`. `fromJson` is backward-compatible with Phase 1's 6-attribute shape (defaults fill the gaps) — **but see the save-compatibility note below, this doesn't save you from a full save-format break.** |
| `lib/models/club.dart` | Added `leagueId`, `stadiumCapacity`, `weeklySponsorship`. Added `weeklyWageBill`, `estimatedHomeGateReceipts()`, `availableSquad` (excludes injured). |
| `lib/models/fixture.dart` | Added `competitionId`. |
| `lib/models/country.dart` | **New.** Just `id`/`name`. |
| `lib/models/league.dart` | **New.** `countryId`, `tier`, promotion/relegation/continental-qualification spot counts. |
| `lib/models/tactics.dart` | **New.** `Formation` (4-3-3 / 4-2-3-1 / 3-5-2), `TacticalStyle` (high press / counter / possession), `Mentality` (moved here from `save_state.dart`). |
| `lib/models/transfer_offer.dart` | **New.** A persisted negotiation object (`status`: pending/accepted/rejected/withdrawn/countered) — currently resolved synchronously by `TransferService`, but the object exists so multi-week negotiation is an additive change later, not a rewrite. |
| `lib/models/news_item.dart` | **New.** Category + headline/body/gameWeek/read, for the Inbox tab. |
| `lib/models/save_state.dart` | This is your `GameState`. Added `countries`, `leagues`, `transferOffers`, `inbox`; replaced the bare `mentality` field with `tactics: Tactics`. |
| `lib/services/world_service.dart` | **New.** Multi-league fixture generation, per-league tables, promotion/relegation resolution across country tiers, continental-qualifier identification. |
| `lib/services/season_service.dart` | `generateRoundRobin` now takes a `competitionId` and tags every fixture with it. |
| `lib/services/data_importer_service.dart` | **New.** JSON and CSV parsing into the World schema, with real validation (even club counts per league, valid league references, per-row error messages) — not just `jsonDecode` and hope. |
| `lib/services/content_pack_service.dart` | `ContentPack` now carries `countries`/`leagues` alongside `clubs`. |
| `lib/services/lineup_service.dart` | `autoPick` takes a `Formation` instead of being hardcoded to 4-3-3. |
| `lib/sim/match_engine.dart` | Rating math updated for the new attributes (tackling for defense, dribbling/workRate blended into attack/midfield); added `homeStyle` as a second home-side shift alongside mentality. |
| `lib/state/game_controller.dart` | Rewritten: `_startCareer` (shared by sample data and imports), multi-league `playNextMatchday` (every league's round-fixtures resolve together), fitness/injury drain tied to `staminaRating`/`injuryProneness`, per-match finances, news generation, season-end promotion/relegation. |
| `lib/screens/home_shell.dart` | Bottom nav is now Dashboard / Squad / Transfers / Standings / Inbox (5 tabs, matching the spec). |
| `lib/screens/squad_screen.dart` | Merged with a tactics board (formation/style/mentality selectors) — this is your "Squad & Tactics" tab. |
| `lib/screens/table_screen.dart` | Now a league picker + table, with promotion/relegation/continental zones color-coded — this is "League Standings." |
| `lib/screens/transfer_market_screen.dart` | Added a scouting banner (weakest-position heuristic) — "Transfers & Scouting." |
| `lib/screens/inbox_screen.dart` | **New.** Objectives + news feed, replacing the standalone Objectives tab. |
| `lib/screens/data_import_screen.dart` | **New.** JSON file picker, CSV pair picker, or paste-JSON fallback. |
| `lib/screens/new_game_screen.dart` | Clubs grouped by country → league; entry point to the importer. |
| `assets/content/sample_world_pack.json` | Replaced `sample_pack.json`. 2 countries × 2 tiers × 8 clubs = 32 clubs, 640 players. |
| `pubspec.yaml` | Added `file_picker` for the import screen. |

## Breaking change: Phase 1 saves don't load

`SaveState`'s shape changed too much for a clean migration (world
layer added, `mentality` replaced by `tactics`, fixture shape changed).
If you have a Phase 1 save on a device, abandon that career (the
in-app button) and start fresh — there's no migration path in this
patch. A real migration ("bump a save-format version, write an
upgrade function per version jump") is worth building before this
ships to actual users who'd be upset to lose a save; it's not built
here because a single save slot to a codebase, not a live user base,
was what needed migrating this time.

## Import schema reference

JSON (single file):
```json
{
  "countries": [{"id": "england", "name": "England"}],
  "leagues": [{
    "id": "england_tier1", "country_id": "england",
    "name": "Premier Division", "tier": 1,
    "promotion_spots": 0, "relegation_spots": 2,
    "continental_qualification_spots": 2
  }],
  "clubs": [{
    "id": "club_x", "league_id": "england_tier1", "name": "...",
    "short_name": "CLX", "reputation": 70, "balance": 1000000,
    "stadium_capacity": 30000, "weekly_sponsorship": 25000,
    "squad": [{
      "id": "p1", "name": "...", "nationality": "ENG", "position": "fwd",
      "attributes": {"pace": 80, "shooting": 78, "passing": 60,
        "tackling": 30, "dribbling": 75, "goalkeeping": 10,
        "physical": 65, "stamina_rating": 70, "injury_proneness": 20,
        "work_rate": 60, "leadership": 40},
      "wage": 5000, "value": 2000000, "contract_years_remaining": 3
    }]
  }]
}
```

CSV (two files, joined by `club_id`):
- `clubs.csv` columns: `id, name, short_name, country_name, league_name, tier, reputation, balance, stadium_capacity, weekly_sponsorship, promotion_spots, relegation_spots, continental_spots`
- `players.csv` columns: `id, club_id, name, nationality, position, pace, shooting, passing, tackling, dribbling, goalkeeping, physical, stamina_rating, injury_proneness, work_rate, leadership, wage, value, contract_years_remaining`

Every league must have an even number of clubs (the round-robin
generator requires it) — the importer rejects odd counts with a clear
error rather than silently dropping a club.

## What's next (honest scope list, not done here)

- **Continental cup fixtures.** `WorldService.continentalQualifiers`
  identifies who qualifies; the cup's own bracket/group stage isn't
  built. It reuses the same `Fixture.competitionId` mechanism, so it's
  additive, not a rewrite.
- **AI-initiated transfer offers** for your own players — `TransferOffer`
  exists as a model but nothing currently creates one in the `incoming`
  direction.
- **Multi-week negotiation** — offers resolve synchronously today;
  the `pending`/`countered` states on `TransferOffer` are unused until
  negotiation spans game weeks.
- **Save format versioning/migration**, mentioned above.
- **Leagues of different sizes.** `WorldService`'s lockstep-round
  assumption (documented in its class doc) breaks if two leagues in
  the world have different club counts.
- **Live match commentary / sub management mid-match** — the engine
  still resolves a whole match in one call; turning it into a
  step-through simulation with in-match tactical changes is a
  genuinely different architecture for `MatchEngine`, not a small
  patch.
