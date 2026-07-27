# Drago's Time to Shine

A mobile-first Godot 4.6 proof of concept for a cozy dragon care game.

## Playable loop

1. Choose **Den** from the main menu.
2. Select **Luma**, the starter dragon.
3. Press **Feed** to drop a berry. Luma walks over with a paper-sprite bob,
   eats it, and gains care/hunger progress.
4. Press **Groom** for a close-up care view. Drag the pixel comb inside
   the framed grooming area with mouse or touch. The comb always follows;
   Clean and stretching only react over Luma's visible pixels.
5. Choose **Contest**, add a hat, sword, shield, bowtie, or tie, then drag
   each item into place. The last moved item stays on top. The MVP judge
   awards a fixed 5/5 result.

Shop is deliberately marked **Coming soon**.

## Run

Open this folder in Godot 4.6 and run the project, or launch it from a terminal:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

The UI is authored on a 720-pixel-wide logical canvas and rendered at each
device's native resolution. The logical height adapts to the phone's aspect
ratio, keeping text and controls at readable sizes without letterboxing or
crushing a device-sized framebuffer into a preview window. The grooming view
also switches to a compact vertical arrangement on shorter phones.

The responsive layouts are tested at 750×1334 (iPhone SE), 1179×2556
(current iPhone Pro), 1080×2160 (compact Android), and 1080×2400 (tall
Android). Android and iOS export presets are included; platform signing and
toolchains still need to be configured on the export machine.

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
