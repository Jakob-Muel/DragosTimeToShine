# Comic art direction

> Canonical art style (`PRODUCT_DECISIONS.md` D-04). New art must follow this doc.

The runtime art now uses rounded ink contours, warm paper surfaces, soft gradient lighting and the bundled Nunito family. Standing collection dragons are rendered with the same curved anatomy and lighting as Dragon Lab. The Lab's seed contract is unchanged.

The comic raster library lives in `assets/art/comic/`: eggs, care/navigation icons, clouds, panels/buttons, and the shooter sprites and scenery. Runtime dragons now use the shared procedural renderer in portrait, flight and overhead views; all habitats use `universal_island.png`. Earlier fixed dragon sprites and elemental islands remain as legacy source material. See [Unified dragons and island](UNIFIED_DRAGONS.md) for the current pipeline and island generation prompt.

## Rebuild

Run from the project root, with Godot available at your platform's executable path:

```sh
python3 tools/generate_comic_assets.py
Godot --headless --path . --log-file /tmp/comic-assets.log --script tools/render_comic_assets.gd
Godot --path . --log-file /tmp/comic-dragons.log --script tools/render_comic_dragons.gd
Godot --headless --editor --path . --log-file /tmp/comic-import.log --import
```

The Python tool authors editable SVG; Godot rasterizes at double resolution and downsamples for clean small contours. Collection portrait export and screen capture require a graphics device. Use a writable explicit log file on macOS for every Godot invocation.

## Scrolling contract

- Flight clouds repeat their complete three-cloud arrangement (1,080 and 1,560 pixels), including each cloud's height. A one-cloud-width reset changes the visible composition and causes a jump.
- Each race layer wraps independently at its texture width. The shared travel distance never resets at an unrelated period.
- Horizontal scenery has matching heights, gradients and slopes at both edges. Only the skyline is outlined; outlining the tile's vertical boundary introduces a seam.
- The shooter's 840-pixel meadow repeats a continuous curved path with matching position and tangent. Flowers and rocks are part of the tile, so they retain their identity when it wraps.
- Foreground, hills and clouds move at different speeds to preserve depth and a clear sense of travel.

`tests/comic_scrolling_render_test.gd` checks texture edges, actual rendered frames on both sides of the wrap boundaries, exact full-cycle repetition, and visible motion. Existing domain, minigame, routing, font and safe-area tests continue to cover behavior.

`tools/capture_comic_review.gd` captures 21 actual game screens with demo state into `docs/screenshots/comic/`, without writing player saves. Pass `-- short` to capture six compact-phone layouts. SVG source and review screenshots are excluded from game exports with `.gdignore`. The legacy `PixelSky`, `PixelEgg`, `PixelChevron`, and `pixel_icon` names remain as compatibility interfaces; their rendering is comic art with linear filtering.


## Validation

The comic pass was checked with all ten existing test scripts (domain, smoke, routing, safe area, fonts, dragon presentation and generation, shooter, training contract and training session), plus the scrolling render regression. All passed. The review set contains 21 screens at the tall phone aspect and six at the compact phone aspect.
