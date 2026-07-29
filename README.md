# Drago's Time to Shine

A mobile-first Godot 4.6 proof of concept for a cozy dragon care game.

## Current prototype loop

1. Choose **Den** from the main menu.
2. Choose **Dragons** to visit Luma, or **Eggs** to inspect incubating eggs.
3. Select a dragon and press **Feed** to drop a berry. The dragon walks over
   with a paper-sprite bob, eats it, and gains care/hunger progress.
4. Press **Groom** for a close-up care view. Drag the pixel comb inside the
   framed grooming area. Clean and stretching react over the dragon's visible pixels.
5. Choose **Contest** to enter Flight School. In **Flight Training**, tap to
   flap between rock spikes. Each cleared obstacle awards one XP, every ten XP
   adds one Flight Level, and training continues until Luma hits an obstacle.
6. Reach Flight Level 5 to unlock the **Flight Contest**. The selected dragon
   then glides 50 metres and wins one gold coin.
7. Open **Shop** and spend one gold coin on a **Frost Crystal Egg**. Start
   incubation and walk 1,000 steps to hatch Frost, an ice dragon. Desktop/web
   builds provide a test-step button.
8. Select Frost in the den to visit a dedicated snow-and-crystal island. Care,
   grooming, flight XP, and contest progress remain attached to the selected
   dragon.

Game state is saved locally between sessions.

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

## Project documentation

- [Intended gameplay loop and progression](docs/GAMEPLAY_LOOP.md)
- [Architecture and module boundaries](docs/ARCHITECTURE.md)
- [Flight training, contest, and reward rules](docs/FLIGHT_GAMEPLAY.md)
- [Frost egg, ice dragon, and winter island](docs/ICE_DRAGON.md)
- [Native iOS/Android build pipeline](docs/MOBILE_PIPELINE.md)
- [Step-counter plugin contract](native/README.md)

Run the gameplay smoke test without opening a window:

```sh
/Applications/Godot.app/Contents/MacOS/Godot \
  --headless --path . --script tests/smoke_test.gd
```

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
