# Drago's Time to Shine

A mobile-first Godot 4.6 prototype of a cozy dragon care, breeding and training game.

## Current prototype loop

1. Start a new game with **one free egg**. Press **Hatch now** to meet your first dragon immediately.
2. Visit your dragon in its habitat. Later, choose **Den → Dragons** or **Eggs** to manage your collection.
3. Select a dragon and press **Feed** to drop a berry. The dragon walks over
   with a paper-sprite bob, eats it, and gains care/hunger progress.
4. Press **Groom** for a close-up care view. Drag the comb inside the
   framed grooming area. Clean and stretching react over the dragon's visible body.
5. Choose **Contest**, pick a dragon, and open its Flight hub. In **Flight Training**, tap
   to flap between rock spikes. Each cleared obstacle awards one XP, every ten XP adds one
   Flight Level, and training continues until the dragon hits an obstacle.
6. Reach Flight Level 5 to unlock the first **Flight Contest** (50 m). Later goals are
   70 m (Level 7) and 100 m (Level 10). Each win awards one gold coin.
   **Element Power** training (main menu) is a top-down shooter in which the dragon fires
   automatically.
7. Open **Shop** from the main menu and spend one gold coin on a **Dragon Egg**.
   It contains a random base dragon with individual attribute potentials. Start incubation and walk 5,000 steps
   to reveal it. Desktop/web builds provide a test-step button.
8. Select the new dragon in the den to visit its island. Care, grooming, flight XP, and contest progress remain attached to
   the selected dragon.

Game state is saved locally between sessions.

Use the gear button on the main menu to open **Settings**, switch between
English and German, or reset all game progress after a confirmation step.
Older saves gain individual attribute potentials while retaining their dragons and progress.
Multiple dragons of the same type are supported. Open **Stats / Werte** in a dragon’s
habitat to train attack power, attack speed, and movement speed up to their limits.
Fusion lets you select one parent’s potential per attribute; offspring start untrained.

## Run

Open this folder in Godot 4.6 and run the project, or launch it from a terminal:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

The UI is authored on a 720-pixel-wide logical canvas and rendered at each
device's native resolution. The logical height adapts to the phone's aspect
ratio, keeping text and controls at readable sizes without letterboxing or
crushing a device-sized framebuffer into a preview window. On iOS and Android,
top headers and menu resources also use the system safe-area inset so they stay
below notches, camera cutouts, and the Dynamic Island. The grooming view also
switches to a compact vertical arrangement on shorter phones.

The responsive layouts are tested at 750×1334 (iPhone SE), 1179×2556
(current iPhone Pro), 1080×2160 (compact Android), and 1080×2400 (tall
Android). Android and iOS export presets are included; platform signing and
toolchains still need to be configured on the export machine.

For iOS, install Godot 4.6.1 and its export templates, then run
`tools/repair_godot_ios_template.sh` once on a new Mac. After that, Godot's normal
**Export Project** flow produces an Xcode project that builds for both an arm64 iPhone
and an arm64 Simulator without manual linker edits. Use `tools/export_ios.sh debug`
when you also want the full device-and-Simulator validation pass.

## Project documentation

AI agents: start with [AGENTS.md](AGENTS.md). Current state and plan:
[Status](docs/STATUS.md), [Roadmap](docs/ROADMAP.md),
[Product decisions](docs/PRODUCT_DECISIONS.md).

- [DraGO: Produktanforderungen und Implementierungsplan (Originalbericht)](docs/requirements/DRAGO_PRODUKTANFORDERUNGEN_UND_IMPLEMENTIERUNGSPLAN.html)

- [Soll-Ist-Abgleich zum Produktbericht](docs/requirements/SOLL_IST_ABGLEICH.md)
- [Intended gameplay loop and progression](docs/GAMEPLAY_LOOP.md)
- [Architecture and module boundaries](docs/ARCHITECTURE.md)
- [Modular breeding and talent architecture](docs/BREEDING_AND_TALENTS_ARCHITECTURE.md)
- [Flight training, contest, and reward rules](docs/FLIGHT_GAMEPLAY.md)
- [Procedural dragons and universal island](docs/UNIFIED_DRAGONS.md)
- [Comic art direction](docs/COMIC_ART.md)
- [Frosteros (legacy)](docs/ICE_DRAGON.md)
- [Native iOS/Android build pipeline](docs/MOBILE_PIPELINE.md)
- [Step-counter plugin contract](native/README.md)

During assistant work, use only headless Godot checks with an explicit writable
log file (for example `--headless --log-file /tmp/dragos-test.log`). Do not launch
windowed Godot, the editor, or screenshot/render checks unless the user requests
a visual run; these launches interrupt their other work. Do not stop an existing
Godot process. A captured macOS crash from an assistant-launched graphical process
occurred during AppKit application registration, before game startup.

Run the deterministic project tests without opening a window:

```sh
/Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/dragos-test.log --path . --script tests/smoke_test.gd
/Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/dragos-test.log --path . --script tests/domain_test.gd
/Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/dragos-test.log --path . --script tests/screen_routing_test.gd
/Applications/Godot.app/Contents/MacOS/Godot \
  --headless --log-file /tmp/dragos-test.log --path . --script tests/font_coverage_test.gd
```

The full list of suites (and which need a graphics device) is in `AGENTS.md`.

## Installable Web App

The **Web PWA** export produces an installable, portrait-mode web app in
`build/web`. It runs as a standalone home-screen app and caches the game for
offline use after the first successful load.

Export it locally after installing the Godot 4.6.1 export templates:

```sh
mkdir -p build/web
/Applications/Godot.app/Contents/MacOS/Godot \
  --headless --path . \
  --export-release "Web PWA" build/web/index.html
```

The included `deploy-pages.yml` workflow exports and deploys the PWA whenever
the `main` branch is pushed to GitHub. In the repository's **Settings → Pages**
screen, select **GitHub Actions** as the publishing source.

On iPhone or iPad, open the deployed HTTPS page in Safari and choose
**Share → Add to Home Screen**. On Android, use the browser's
**Install app** or **Add to Home screen** command.

## Adding a language

All player-facing labels use translation keys. To add another language:

1. Open `localization/strings.json`.
2. Copy the `en` object to a new locale code such as `fr`.
3. Translate its values while leaving the keys unchanged.

The localization autoload registers every locale in that catalog with Godot's
`TranslationServer`. The language button on the main menu automatically cycles
through the available locale codes. English and German are included.
