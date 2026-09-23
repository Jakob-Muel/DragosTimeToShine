# Roadmap

Plan from the 2026-09-22 prototype to a releasable version one. Written for agents: each
milestone lists concrete tasks, the files involved and acceptance criteria. Work in order
unless the user says otherwise. Every milestone must leave the game playable.

Product constraints come from `docs/PRODUCT_DECISIONS.md`. Current state is in
`docs/STATUS.md`. The target architecture for talents, genomes and breeding is in
`docs/BREEDING_AND_TALENTS_ARCHITECTURE.md`; this roadmap schedules it.

**Platform rule (D-10): the product is a native Android and iOS game.** Scope every task
for both phones. A task is not done when it only works in the editor or the web build.
Platform features need a working path on both Android and iOS (or a graceful fallback on
both). Anything that can only be verified on a device must be listed in the task report.

Items marked **(needs decision Q-xx)** require an answer from the user before
implementation. Prepare options, do not decide alone.

## Next up (short list)

1. M0.7 Get an Android debug build running on a real phone.
2. M1.5 Android Health Connect plugin (egg hatching depends on steps).
3. M1.6 App lifecycle: Android back gesture, save on pause, re-query steps on resume.
4. M0.4 Remove dead code and decide what `gems` are for.
5. M1.2 Add the `hp` attribute (prepares survivor mode).

## M0 Housekeeping

Goal: a clean, trustworthy base before new features.

| Task | Files | Acceptance |
| --- | --- | --- |
| ~~M0.1 Merge `progressTowards05` into `main`~~ **Done 2026-09-23** (PR #1) | whole repo | CI green on `main`; PWA deploys |
| ~~M0.2 Run all headless suites in CI with timeouts~~ **Done 2026-09-23:** `tests/run_tests.sh` (auto-discovery, fail-fast on errors, timeouts), CI on every push/PR | `.github/workflows/deploy-pages.yml`, `tests/run_tests.sh` | Verified: assert, runtime error, engine error, hang, bad exit code and missing marker all fail |
| ~~M0.3 Show Dragon Lab only in debug builds~~ **Done 2026-09-23** | `build_info.gd`, `main_menu_screen.gd`, `main.gd` | `dev_tools_test`: button hidden and route refused when disabled |
| M0.4 Remove dead code: `next_unowned_egg`, unused contest wrappers, and decide on `gems` (remove or give it a purpose) | `collection_service.gd`, `game_state.gd`, `main_menu_screen.gd` | No unused public API; save migration drops or keeps `gems` explicitly |
| M0.5 Replace the `main.gd` route match with a registry dictionary (route to scene + param handler) | `main.gd`, `screen_router.gd` | Adding a screen touches one registry entry; routing test passes |
| M0.7 Android debug build on a real phone: document the steps in `MOBILE_PIPELINE.md`, check layout, safe areas, touch, fonts and performance | `export_presets.cfg`, `docs/MOBILE_PIPELINE.md` | The core loop runs on an Android phone; issues are listed in `STATUS.md` |
| ~~M0.8 Fit wide windows by height~~ **Done 2026-09-23:** tablets, foldables and desktop browsers no longer cut off the bottom | `game_canvas.gd` | `canvas_fit_test`; screenshots at phone, tablet and desktop sizes |
| M0.6 Decide on legacy art and screenshots (keep curated subset, move rest out) | `assets/art/*`, `docs/screenshots/` | Repo size reduced; no runtime reference broken (grep `res://` paths) |

## M1 Data model and save safety

Goal: saves cannot be lost, and every dragon carries the data future features need.

| Task | Files | Acceptance |
| --- | --- | --- |
| ~~M1.1 Crash-safe save~~ **Done 2026-09-23:** temp file + rename, `.bak` rotation, SHA-256 footer, recovery order main/temp/backup, damaged files quarantined | `scripts/save_repository.gd`, `game_state.gd` | `save_repository_test`: truncation, edits, crash between renames, stale temp, legacy JSON, GameState recovery |
| M1.2 Add `hp` attribute (potential + value, same rules as others) with migration | `dragon_attributes.gd`, `game_state.gd`, `attributes_screen.gd`, strings | Old saves gain `hp`; attribute tests cover it |
| M1.3 Store `generator_version` with every dragon and egg appearance seed | `game_state.gd`, `seeded_dragon.gd` | Changing the generator later cannot change existing dragons |
| M1.4 Child-friendly stat names in the UI **(needs decision Q-08)** | `strings.json` | Both locales updated; internal IDs unchanged |
| M1.5 Android Health Connect plugin: package `StepHealthProvider.kt` as a Godot Android v2 plugin with the same `StepCounterPlugin` signals as iOS; custom Gradle build; `READ_STEPS` permission | `native/android/`, `export_presets.cfg`, `step_counter.gd` | Egg incubation works with real steps on Android; denial leaves the game playable; the test-step button is not shown in release builds |
| M1.6 App lifecycle on both platforms: Android back gesture navigates back (quit only from the main menu), save on pause/background, re-query steps on resume | `main.gd`, `game_state.gd`, `step_counter.gd` | Tested headlessly where possible (notification handling) plus a device checklist |

## M2 Stats that matter

Goal: training an attribute visibly changes a minigame. Bonuses only, never penalties;
a dragon at base values must still be able to play and progress.

| Task | Files | Acceptance |
| --- | --- | --- |
| M2.1 Shooter: `attack_speed` lowers fire interval, `attack_power` raises damage (knights take N hits), `movement_speed` raises steering speed | `flame_shooter_game.gd`, session dict from `GameState.create_training_session` | Session carries a read-only stat snapshot; test checks two stat levels produce different fire intervals |
| M2.2 Flight: pick one gentle effect (for example `movement_speed` slightly widens the gap or slows gravity) | `flight_game.gd` | Effect is bounded and tested; base dragon unchanged from today |
| M2.3 Show the effect in the result panel ("Faster flames thanks to Speed 42") | `training_session_screen.gd` | Kid-readable line in both locales |
| M2.4 Element Power theme for young players **(needs decision Q-05)** | `flame_shooter_game.gd`, `assets/art/comic/flame_minigame/` | Only if the user chooses a new theme |

## M3 Visible genetics and breeding

Goal: children see what they inherited from their parents. Implements stages 3 to 5 of
`BREEDING_AND_TALENTS_ARCHITECTURE.md`. **(needs decisions Q-04, Q-06)**

| Task | Files | Acceptance |
| --- | --- | --- |
| M3.1 Extract trait generation from `SeededDragon` into pure `DragonGenomeGenerator`; renderer draws from a genome snapshot | `scripts/domain/dragon_genome_generator.gd`, `seeded_dragon.gd`, `dragon_views.gd` | Same snapshot renders identically; existing dragons migrate to a snapshot equal to their current look |
| M3.2 Breeding blueprint: child genome derived from both parents' genomes (palette, body, wings, horns, pattern, tail), fixed on the egg | `fusion_service.gd` (to become `BreedingService`), `game_state.gd` | Same parents + seed + version give the same child; reopening cannot reroll |
| M3.3 Egg look hints at the parents (colors) | egg rendering | Bred eggs are visually distinguishable |
| M3.4 Lineage panel: parents' portraits and "inherited from" labels | new detail screen or dragon list panel | Works for generation 0 (no parents) |
| M3.5 Recipe coverage: define species for every base pair or a generic hybrid rule | `data/fusion/` | No silent "parent A species" fallback |

## M4 Care loop and contests

Goal: the Tamagotchi side feels alive, and each talent has a contest.

| Task | Files | Acceptance |
| --- | --- | --- |
| M4.1 Gentle care decay over real time **(needs decision Q-03)** | `care_rules.gd`, `game_state.gd` | Decay computed from timestamps on load; never harms beyond "sad"; tested with fake time |
| M4.2 Element Power contest using the generic contest API | new screen, `training_category_definition.gd` | Unlocks at contest level, awards gold once per goal |
| M4.3 Talent cards with stars and records on the dragon detail view | `dragon_list_screen.gd` / habitat | Default layer icons + stars; detail layer numbers |
| M4.4 Economy pass: gold, Fusion Stars and possibly stones **(needs decision Q-02)** | `game_state.gd`, data | Documented earn/spend table in `GAMEPLAY_LOOP.md` |

## M5 Survivor mode

Goal: the confirmed long-term mode (D-03). **(needs decision Q-01)**

| Task | Files | Acceptance |
| --- | --- | --- |
| M5.1 Design doc `docs/SURVIVOR_MODE.md`: loop, stats used, upgrades, rewards, session length for kids | docs | User approves before code |
| M5.2 Implement as a `TalentMinigame` scene so it reuses session, results and duplicate guard | `scenes/minigames/`, `scripts/ui/` | Registered through a training resource; no new navigation branch |
| M5.3 Uses `hp`, `attack_power`, `attack_speed`, `movement_speed` from the stat snapshot | same | Tests cover stat scaling and one-result-per-run |
| M5.4 Performance check with many enemies on an older iPhone | device | Stable frame rate |

## M6 Release readiness (both stores)

| Task | Files | Acceptance |
| --- | --- | --- |
| M6.1 Device test pass on iPhone and Android (HealthKit / Health Connect grant, deny, retry, restart, real walk) | devices | Checklist in `MOBILE_PIPELINE.md` all green on both |
| M6.2 Step alternative without HealthKit **(needs decision Q-07)** | egg flow | Player can hatch without health access |
| M6.3 Accessibility: reduced motion, adjustable minigame speed, larger text option | settings, minigames | Toggles persist and work |
| M6.4 Audio: music and effects with mute toggle | new `audio` autoload | Playable without sound |
| M6.5 TestFlight build and Google Play internal testing track | `MOBILE_PIPELINE.md` | Internal testers can install on both platforms |
| M6.6 Store compliance for a children's game: privacy labels / data safety form, Families policy and Kids category rules, age rating, health permission texts | store listings, `strings.json` | Both store submissions pass review |
| M6.7 Performance on a mid-range Android phone and an older iPhone (frame rate, memory, app size) | devices | Stable frame rate in all minigames |

## Out of scope

Turn-based battles, PvP, an adaptive opponent ladder, online features, and a native Swift
rewrite (see D-01, D-03, D-05).
