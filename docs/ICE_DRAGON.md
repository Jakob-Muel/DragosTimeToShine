# Frost: Egg, Dragon, and Island

## Current status

Frost, the Frost Crystal Egg, and the snow-and-crystal island remain preserved
for compatible save loading and debug previews. The ice egg is currently not
offered in the shop or awarded by the normal game flow.

Existing saves that already contain a Frost egg can still complete the
1,000-step incubation and hatch Frost. Existing Frost dragons remain usable in
the den and retain their care and training progress.

Frost uses the same care, grooming, flight-training, and contest systems as the
starter dragon. Flight XP is stored on each dragon, so progress follows the
selected dragon.

## Dragon data

Eggs and owned dragons store a stable dragon-definition ID. Definitions own names,
types, egg kinds, and art:

| Definition | Egg kind | Hatched dragon | Types | Habitat |
| --- | --- | --- | --- | --- |
| `frost` | `ice` | Frost | `ice` | Ice island |
| `nova` | `sunwing` | Nova | `sunwing` | Green island |

Older `kind` and `species` values migrate to definition IDs when loaded. Display names
remain localization keys rather than save-file text.

## Art assets

- `assets/art/ice/ice_egg.png`: transparent gameplay egg sprite.
- `assets/art/ice/ice_dragon_hd.png`: transparent Frost sprite prepared from
  the supplied dragon reference.
- `assets/art/ice/ice_island_hd.png`: portrait winter habitat background.
- `assets/art/ice/ice_egg_chroma.png`: generated egg source on a chroma
  background.
- `assets/art/ice/ice_dragon_source.png`: original supplied dragon reference.

The egg was generated to inherit Frost's pale-blue, white, cyan-crystal, and
dark-outline visual language. The island was generated as a winter counterpart
to the original habitat, with snow, ice, a frozen pond, cyan crystals, and an
open center for the dragon and care interactions.

Run the preparation script after replacing either source sprite:

```sh
/Applications/Godot.app/Contents/MacOS/Godot \
  --headless --path . --script tools/prepare_ice_assets.gd
```

It removes connected near-white/chroma backgrounds, crops transparent margins,
and resizes sprites with nearest-neighbor sampling so their pixel edges remain
crisp.

## Validation

`tests/domain_test.gd` verifies that the Frost definition remains available for
legacy data. `tests/smoke_test.gd` verifies that the active shop rejects ice-egg
purchases without spending gold.
