# AGENTS.md

Entry point for AI coding agents working on **Drago's Time to Shine** (internal name DraGO).
Read this file first, then only the docs relevant to your task. Humans start at `README.md`.

## 1. What this project is

A mobile-first, fully offline 2D dragon care and breeding game built with **Godot 4.6
(GDScript, GL Compatibility renderer)**. Players care for dragons (feed, groom), train them
in short minigames, enter peaceful contests, hatch eggs by walking real steps
(HealthKit on iOS, test button on desktop/web), and breed new dragons whose appearance is
generated procedurally from a seed.

Target players: children around 6 and 11. Primary platform: iPhone. A PWA web build is the
fast review channel (GitHub Pages, deployed on every push to `main`).

## 2. Source-of-truth order

When documents disagree, the higher entry wins:

1. The user's latest explicit instruction in the current task.
2. `docs/PRODUCT_DECISIONS.md` (confirmed decisions, dated).
3. The code and its tests (what actually ships).
4. `docs/STATUS.md` and `docs/ROADMAP.md` (current state and agreed next steps).
5. Feature docs in `docs/` (see the index in section 9).
6. `docs/requirements/DRAGO_PRODUKTANFORDERUNGEN_UND_IMPLEMENTIERUNGSPLAN.html`
   (original product report, German). It describes the long-term vision, **not** a work
   order. Several of its points are overridden (see `PRODUCT_DECISIONS.md`).

If you find a contradiction that none of these resolves, ask the user instead of guessing,
and record the answer in `PRODUCT_DECISIONS.md`.

## 3. Non-negotiable product rules (short form)

- **Engine stays Godot.** Do not propose or start a SwiftUI/SpriteKit rewrite.
- **No Pokémon-style battles and no PvP.** No turn-based dragon-vs-dragon fights, no
  opponent ladder. Action minigames that contain combat mechanics are allowed
  (auto-firing Element Power shooter, a future survivor mode). Combat stats
  (attack power, attack speed, movement speed, later HP) exist to drive those minigames.
- **Art style is the current "comic" style**: soft shaded vector-like shapes, plum ink
  outlines, Nunito font, procedural dragons from `SeededDragon` / `DragonViews`.
  Strict pixel art was dropped because it cannot support generated dragons.
  `docs/art_prompts.md` is historical.
- **Fully offline.** No accounts, servers, analytics, ads or remote config.
- **Child-friendly.** No dragon is a bad result, parents are never consumed, nothing
  punishes the player harshly. Explain with icons and stars first, numbers second.
- **Privacy.** Never store raw health samples. Only aggregate step results.

## 4. Commands

Godot is not installed in cloud sandboxes. Tests can only run on the user's Mac or in CI.
Do not claim tests pass unless you ran them.

On the user's Mac the binary is `/Applications/Godot.app/Contents/MacOS/Godot`.
Always run headless with an explicit writable log file:

```sh
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --headless --log-file /tmp/dragos-test.log --path . --script tests/<name>_test.gd
```

Headless test suites (each prints `... valid` and quits on success):

| Suite | Covers |
| --- | --- |
| `smoke_test.gd` | Main player loop, save migration, shop, contest, reset |
| `domain_test.gd` | Catalog, fusion rules, care, letter trace pad |
| `starter_progression_test.gd` | Starter egg flow |
| `random_eggs_test.gd` | Shop random eggs, fixed hidden result |
| `attribute_genetics_test.gd` | Attribute potentials and selectable inheritance |
| `training_contract_test.gd` | `TalentMinigame` result contract, duplicate guard |
| `training_session_test.gd` | Shared training session screen |
| `flame_shooter_test.gd` | Element Power minigame |
| `screen_routing_test.gd` | Every screen instantiates through the router |
| `ui_safe_area_test.gd` | Safe-area layout at phone sizes |
| `font_coverage_test.gd` | Nunito covers German/English glyphs |
| `seeded_dragon_test.gd` | Deterministic dragon traits |

Suites that need a real graphics device (run without `--headless`, only when the user asks
for a visual run): `seeded_dragon_render_test.gd`, `procedural_dragon_views_test.gd`,
`comic_scrolling_render_test.gd`. `dragon_presentation_test.gd` reads rendered texture
images and probably needs one too (unverified).

CI (`.github/workflows/deploy-pages.yml`) currently runs only smoke, domain,
training_contract, training_session, screen_routing and font_coverage before exporting the
PWA.

Rules for launching Godot as an agent:

- Headless only, unless the user explicitly requests a visual run.
- Never launch the editor or a windowed game, and never stop an existing Godot process.
- Test scripts disable persistence (`GameState.persistence_enabled = false` when
  `--script` is present), so they never touch the player's save.

Web export: `$GODOT --headless --path . --export-release "Web PWA" build/web/index.html`.
iOS: see `docs/MOBILE_PIPELINE.md`.

## 5. Repository map

```text
main.gd / main.tscn     App shell: canvas fitting, route dispatch (match block), debug helpers
project.godot           Autoloads: Localization, GameState, StepCounter. 720-wide canvas
scripts/game_state.gd   Save facade + gameplay API (autoload). All persistent mutations go here
scripts/domain/         Pure rules: care, training, fusion, attributes, catalog, collection
scripts/data/           Resource classes: DragonDefinition, TrainingCategoryDefinition, FusionRecipe
data/                   .tres content: dragons/, training/, fusion/
scripts/screens/        One controller per screen (extends GameScreen)
scenes/screens/         Matching .tscn per screen
scenes/minigames/       Talent minigame scenes (flight, flame shooter)
scripts/ui/             Shared UI: GameCanvas, ScreenRouter, WidgetFactory, UiTokens,
                        SeededDragon, DragonViews, ProceduralDragonTextures, minigames
scripts/step_counter.gd Platform-neutral step API with desktop/web mock
scripts/localization.gd Loads localization/strings.json (en, de)
native/ + ios/plugins/  HealthKit plugin (built) and Health Connect provider source
assets/art/comic/       Current runtime art (+ source/ SVGs, excluded from export)
assets/art/*            Older sprite sets kept for legacy/reference
tools/                  Headless asset generators and screenshot capture scripts
tests/                  SceneTree test scripts (see section 4)
docs/                   Design and architecture docs (index in section 9)
```

## 6. Architecture invariants

- **Screens never write saves.** Screens call `GameState` methods; `GameState` validates,
  mutates, then calls `_commit_change()` (save + `state_changed`).
- **Domain services are pure.** No nodes, textures, translations, file I/O or HealthKit in
  `scripts/domain/`.
- **Minigames never mutate progression.** They extend `TalentMinigame`, receive a session
  dict, and emit exactly one `run_completed(result)` or `run_cancelled`.
  `GameState.apply_training_result()` turns a result into XP, records and attribute gains,
  guarded by `applied_training_runs` against duplicates.
- **Content lives in resources, progress lives in the save.** Never write a resource into
  JSON. Saves store stable IDs (`definition_id`, talent IDs) and snapshots.
- **Hidden outcomes are fixed at creation.** An egg stores its `definition_id`,
  `appearance_seed`, attribute potentials and parents when granted, bought or bred.
  Reloading or hatching must never reroll it.
- **Platform APIs sit behind a service with a test fallback** (`StepCounter` pattern).
- **Navigation**: a screen emits `navigation_requested(route, params)`; `main.gd`
  dispatches in `_on_screen_navigation`. New screens need a scene, a controller, a
  preload constant and a match branch in `main.gd`.

## 7. Save format rules

- File: `user://dragos_save.json`, current `SAVE_SCHEMA_VERSION` is in
  `scripts/game_state.gd` (11 at the time of writing).
- Any change to the saved shape needs: a schema bump, normalization in
  `_normalize_dragon` / `_normalize_egg`, a migration branch in `load_payload`, and a
  test that loads an old-shape payload.
- Loading must tolerate missing keys, unknown talent IDs and wrong types. Never trust
  parsed JSON directly.
- Known weakness: writes are not atomic and there is no backup. See `docs/ROADMAP.md`.

## 8. Conventions

- GDScript with static types where practical, tabs for indentation, `class_name` for
  reusable classes, `StringName` (`&"id"`) for stable IDs.
- Every player-facing string is a key in `localization/strings.json` and must exist in
  **both** `en` and `de`. Use `Localization.text(key, values)` / `tr_text(...)`.
- UI is built in code on a 720-unit-wide logical canvas; height follows the device aspect.
  Respect the safe area (`GameScreen.safe_top_inset`, `safe_top_y()`, provided by `GameCanvas`). Test layouts at 750x1334,
  1179x2556, 1080x2160 and 1080x2400.
- Colors and fonts come from `scripts/ui/ui_tokens.gd`; widgets from `WidgetFactory`.
- New critical behavior gets an assertion in an existing or new headless test.
- Keep docs in English (the original requirements report stays German). Update
  `docs/STATUS.md` when you ship or remove a feature, and `PRODUCT_DECISIONS.md` when the
  user confirms a decision.
- Commit messages: conventional style (`feat:`, `fix:`, `docs:`, `chore:`).
- Do not commit regenerated screenshots or `.godot/` unless asked. `docs/screenshots/`
  is already about 45 MB.

## 9. Documentation index

| Doc | Purpose | Status |
| --- | --- | --- |
| `docs/PRODUCT_DECISIONS.md` | Confirmed decisions and overrides of the report | Current |
| `docs/STATUS.md` | What is implemented, known gaps and bugs | Current (2026-09-22) |
| `docs/ROADMAP.md` | Milestones and next tasks | Current (2026-09-22) |
| `docs/ARCHITECTURE.md` | Modules, screen flow, save data | Current |
| `docs/GAMEPLAY_LOOP.md` | Player loop and progression rules | Current |
| `docs/BREEDING_AND_TALENTS_ARCHITECTURE.md` | Target architecture for talents, genomes, breeding | Target design, partly implemented |
| `docs/FLIGHT_GAMEPLAY.md` | Flight training and contest rules | Current |
| `docs/UNIFIED_DRAGONS.md` | Procedural dragon rendering pipeline, universal island | Current |
| `docs/COMIC_ART.md` | Comic art direction and asset rebuild | Current, canonical style |
| `docs/MOBILE_PIPELINE.md` | iOS/Android export, HealthKit | Current |
| `native/README.md` | Step-counter plugin contract | Current |
| `docs/ICE_DRAGON.md` | Frosteros legacy notes | Legacy |
| `docs/REVIEW_PROMPTS.md` | Standalone review prompts for agents | Partly outdated |
| `docs/art_prompts.md` | Pixel-art prompt set | Superseded by comic style |
| `docs/requirements/` | Original report (German) and gap analysis | Vision, not a work order |

## 10. Definition of done for an agent change

1. Behavior change is covered by a headless test, or you state why it cannot be.
2. Both locales have every new key.
3. Save shape changes are migrated and tested.
4. The relevant docs (`STATUS.md` at minimum) are updated in the same change.
5. You report honestly which tests you ran and which you could not run.
