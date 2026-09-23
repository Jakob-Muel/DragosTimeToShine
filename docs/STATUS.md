# Implementation status

Snapshot: 2026-09-23, `main` plus branch `m0-3-save-safety`.
Based on reading the source and tests, not on a fresh device run. Update this file whenever
a feature ships, changes or is removed.

Legend: **Done** works end to end · **Partial** exists with known gaps · **Missing** not started.

## Feature status

| Area | Status | Where | Notes |
| --- | --- | --- | --- |
| Starter egg, instant hatch | Done | `game_state.gd` `_reset_defaults`, `egg_detail_screen.gd` | Random species from the pool, hatches with id `luma` |
| Shop, generic egg for 1 gold | Done | `shop_screen.gd`, `GameState.purchase_egg` | Pool: luma, frost, ember, marina, terra |
| Egg incubation by steps | Done | `egg_detail_screen.gd`, `step_counter.gd` | 5,000 steps; desktop/web +250 test button; progress never decreases |
| HealthKit plugin (iOS) | Partial | `ios/plugins/step_counter/`, `native/` | Built and enabled; needs fresh device testing of denial, restart, real walks |
| Health Connect (Android) | Missing | `native/android/` | Provider source only, no plugin packaging. **Required for launch (D-10)** |
| Step ledger / allocation | Missing | | Steps count per egg since incubation start; no shared ledger |
| No-HealthKit alternative | Missing | | Only the desktop/web test button |
| Den, dragon list, egg list | Done | `den_screen.gd`, `dragon_list_screen.gd`, `egg_list_screen.gd` | Capacity 12 (dragons + eggs) |
| Habitat: feed | Done | `habitat_screen.gd` | Berry drop, walk, eat animation |
| Grooming | Done | `groom_screen.gd` | Comb over visible dragon pixels, cleanliness to 100 % |
| Care decay over time | Missing | | Hunger/cleanliness never drop with real time (open question Q-03) |
| Happiness bonus to training XP | Done | `care_rules.gd` | Up to +25 % XP |
| Attributes (attack power, attack speed, movement speed) | Partial | `dragon_attributes.gd`, `attributes_screen.gd` | Trainable to potential; **do not yet affect minigame physics or damage** |
| HP attribute | Missing | | Needed for survivor mode |
| Talent system (shared session) | Done | `talent_minigame.gd`, `training_session_screen.gd`, `training_service.gd` | XP, levels, stars, personal best, duplicate-run guard |
| Flight training | Done | `flight_game.gd`, `data/training/flight.tres` | Tap-to-flap, 1 XP per obstacle |
| Flight contest | Done | `flight_contest_screen.gd` | Three goals 50/70/100 m vs three opponents, 1 gold per win |
| Element Power training (flame shooter) | Done | `flame_shooter_game.gd`, `data/training/element_power.tres` | Top-down auto-fire vs knights, 3 lives |
| Element Power contest | Missing | | Resource defines contest fields, no screen |
| Survivor mode | Missing | | Confirmed long-term goal (D-03) |
| Third/fourth talent (strength by steps, intelligence) | Missing | | From the report; not yet confirmed |
| Fusion / breeding | Partial | `fusion_screen.gd`, `fusion_service.gd` | Two distinct parents, pick potential per attribute, letter-trace ritual, Fusion Stars, 5,000-step egg; species from 3 recipes else parent A |
| Visual inheritance / genome | Missing | | Child gets a new random appearance seed; no genome snapshot or generator version |
| Lineage / family tree view | Missing | | Parent IDs and generation are stored |
| Procedural dragons | Done | `seeded_dragon.gd`, `dragon_views.gd`, `procedural_dragon_textures.gd` | Portrait, flight and top-down views from one seed |
| Dragon Lab (seed preview) | Done | `dragon_lab_screen.gd` | Developer tool, shown only in debug builds (`BuildInfo.dev_tools_enabled()`) |
| Localization en/de | Done | `localization/strings.json` | 231 keys each |
| Settings, language, reset | Done | `settings_screen.gd` | |
| Save and migration | Done | `game_state.gd`, `save_repository.gd` | Schema 11 with migrations; temp-file write, backup, SHA-256 check, recovery and quarantine |
| Responsive layout, safe areas | Done | `game_canvas.gd`, `ui_safe_area_test.gd` | 720-wide logical canvas |
| CI and PWA deploy | Done | `.github/workflows/deploy-pages.yml`, `tests/run_tests.sh` | All headless suites on PRs and pushes to `main`, fail-fast runner; Pages deploys from `main` |
| iOS export | Partial | `tools/export_ios.sh`, `docs/MOBILE_PIPELINE.md` | No TestFlight yet |
| Android export | Partial | `export_presets.cfg` (Android preset) | Preset exists; no documented device run, no custom Gradle build, no Play test track |
| Android back button / app lifecycle | Missing | | Back gesture, pause/resume and backgrounding not handled or tested |
| Accessibility (reduced motion, text size, game speed) | Missing | | |
| Audio | Missing | | No sound or music |

## Known issues and tech debt

1. **Attributes are cosmetic.** Trained values do not change flight physics or shooter
   damage/fire rate yet, so training them has no gameplay effect.
2. **Unused currency.** `gems` is saved and shown in the main menu but has no use.
3. **Dead code.** `CollectionService.next_unowned_egg` and generic
   `can_enter_training_contest` / `complete_training_contest` are unused. Flight-specific
   wrappers in `GameState` duplicate the generic path.
4. **Rendering suites are not in CI.** The three `## requires-graphics` suites need a
   display (run them on the Mac with `tests/run_tests.sh --graphics`). All 15 headless
   suites pass as of 2026-09-23.
5. **Fusion species fallback.** Pairs without a recipe produce parent A's species; the
   child's look is a fresh random seed, so inheritance is not visible.
6. **Routing is a hand-written match block** in `main.gd`; every new screen touches it.
7. **Repository size.** `docs/screenshots/` is about 45 MB, `assets/` about 136 MB,
    including legacy sprite sets that runtime no longer uses.
8. **Legacy sprites.** Dragon definitions still reference fixed species sprites and
    elemental islands. Runtime draws procedural dragons and the universal island.

## Mapping to the requirements report

The German gap analysis in `docs/requirements/SOLL_IST_ABGLEICH.md` remains valid for
details, with these updates from `PRODUCT_DECISIONS.md`: battle system, adaptive ladder
and battle rewards are out of scope (D-03); the survivor mode is added; the Swift stack is
not adopted (D-01).
