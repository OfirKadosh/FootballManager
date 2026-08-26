# Pocket Manager

A working, single-player, offline football management game skeleton
built in Flutter — companion code to `football_manager_spec.md`.

## What's actually playable

- Pick a club from an 8-club fictional league (`assets/content/sample_pack.json`,
  160 generated players, real-schema-shaped data standing in for a real
  licensed feed).
- A full double round-robin season (14 matchdays) is generated at
  career start.
- Play each matchday: your match (and every other match in the league)
  is simulated by the data-driven `MatchEngine`, using your chosen
  starting XI and mentality (defensive/balanced/attacking).
- Pick your starting XI from your squad (auto-picked at career start,
  editable anytime).
- Browse the league table, live-updated after every matchday.
- Buy players from other clubs' squads (simplified valuation +
  accept/reject roll) and sell your own.
- Two season objectives are generated based on your club's reputation
  (e.g. "Win the league" or "Finish top 3", plus a relegation-avoidance
  safety objective) and resolve at season end.
- Everything persists to disk automatically — close the app and your
  career is there when you reopen it.

## What's intentionally out of scope for this build

- Only one season is playable end-to-end; there's no "roll into a new
  season" flow yet (aging players, contract renewals, a fresh
  fixture list). See spec §4/§5 for how content-pack versioning is
  meant to handle that.
- No incoming transfer offers from AI clubs for your players — selling
  is user-initiated only.
- Lineup is a flat "toggle 11 players", not a real formation/tactics
  editor with player positions on a pitch.
- Data is fictional, matching the schema real licensed data would
  need to conform to (see spec §4-§5) — no real licensing integration.
- No cloud save backup — this is local-only persistence.

None of these are hard to add on top of what's here; they just weren't
needed to get a genuinely playable loop working end to end.

## Project layout

```
lib/
  models/       Player, Club, Fixture, Objective, SaveState
  sim/          MatchEngine (data-driven, deterministic), SimConfig, MatchResult
  services/     ContentPackService, SaveService, SeasonService,
                LineupService, TransferService
  state/        GameController — the single source of truth, wired to
                every screen via ChangeNotifier/ListenableBuilder
  screens/      NewGameScreen, HomeShell (nav), DashboardScreen,
                SquadScreen, TableScreen, TransferMarketScreen,
                ObjectivesScreen
assets/content/
  sample_pack.json   8 clubs, 160 players, versioned content pack
```

## Running it on your iPhone

### Option A — you have a Mac

1. **Install Flutter**: `https://docs.flutter.dev/get-started/install/macos`
2. **Install Xcode** from the Mac App Store, open it once, accept the
   license.
3. Unzip this project, then in Terminal:
   ```
   cd football_manager_app
   flutter create --platforms=ios .    # scaffolds the missing ios/ folder
   flutter pub get
   ```
4. Plug your iPhone into the Mac via cable.
5. Open `ios/Runner.xcworkspace` in Xcode once, select your iPhone as
   the run target, and under **Signing & Capabilities** pick your own
   Apple ID as the team (a free personal account works). One-time step.
6. On the iPhone: **Settings > General > VPN & Device Management**,
   trust your Apple ID.
7. From the project folder: `flutter run` — builds, installs, and
   launches on your phone. A free-tier signing profile expires after
   about a week, so re-run this (or rebuild from Xcode) periodically.

### Option B — you don't have a Mac and don't have a paid Apple Developer account

This project includes `.github/workflows/build-unsigned-ipa.yml`,
which builds an **unsigned** `.ipa` on GitHub's free macOS runners —
no Apple account touched at all in that step. You then sign it
yourself, for free, on your own Windows PC using a sideloading tool.
This works specifically *because* you're not going through Apple's
official distribution — no App Store, no TestFlight, no enrollment fee.

1. Create a free GitHub account if needed, and push this project
   (unzipped) as a new repository.
2. In the repo's **Actions** tab, the "Build unsigned iOS IPA"
   workflow runs automatically on push (or trigger it manually via
   "Run workflow"). It takes a few minutes.
3. When it finishes, open the run and download the
   `PocketManager-unsigned-ipa` artifact — that's your `.ipa`.
4. Install **Sideloadly** (`sideloadly.io`) on your Windows PC.
5. Plug your iPhone into the PC via USB, open Sideloadly, drag the
   `.ipa` in, enter any free Apple ID (a throwaway one is fine — this
   doesn't need to be your main Apple ID or a paid account), click
   **Start**. Sideloadly generates the free personal signing
   certificate itself and installs the app directly.
6. On the iPhone: **Settings > General > VPN & Device Management**,
   trust the certificate, then open the app.

Same 7-day expiry as Option A applies (an Apple platform limit on
free-tier signing, not something either tool controls) — re-run
Sideloadly against the same `.ipa` to refresh it, no need to rebuild.

**Why not Codemagic's automatic signing, which I initially
suggested?** That specifically requires a paid Apple Developer
Program membership ($99/year) — it authenticates through App Store
Connect's API, which doesn't exist for unenrolled accounts. The
free-Apple-ID path only exists inside Xcode itself or in tools like
Sideloadly/AltStore that replicate what Xcode does locally — which is
exactly what Option B uses instead.

## Where to go next

1. Season rollover: generate a new fixture list + apply aging/rating
   drift to players when a season completes, instead of stopping.
2. A real lineup/formation editor (assign specific players to specific
   pitch positions rather than a flat toggle list).
3. Incoming AI transfer offers for your own players.
4. Swap `ContentPackService.loadBundled` for a real CDN-fetched,
   licensed data feed per spec §4 once that's available.
