# Frosteros: Egg, Dragon, and Island

## Current status
> **Legacy doc.** Frosteros (`frost`) is now a normal member of the shop's random egg
> pool and is drawn with the shared procedural renderer and universal island like every
> other dragon. The dedicated Frost Crystal Egg and winter island below are legacy assets.

The separate ice egg kind is not sold. Old saves that contain a Frost egg migrate it to the
generic 5,000-step egg (schema 9 migrated old 1,000-step eggs). Existing Frosteros dragons
keep their care and training progress.

## Dragon data

Eggs and owned dragons store a stable dragon-definition ID. Definitions own names,
types, egg kinds, and art:

| Definition | Egg kind | Hatched dragon | Types | Habitat |
| --- | --- | --- | --- | --- |
| `frost` | `ice` | Frosteros | `ice` | Ice island |
| `nova` | `sunwing` | Nova | `sunwing` | Green island |

Older `kind` and `species` values migrate to definition IDs when loaded. Display names
remain localization keys rather than save-file text.

## Art assets

- `assets/art/ice/ice_egg.png`: transparent gameplay egg sprite.
- `assets/art/ice/ice_dragon_hd.png`: transparent Frosteros sprite prepared from
  the supplied dragon reference.
- `assets/art/ice/ice_island_hd.png`: portrait winter habitat background.
- `assets/art/ice/ice_egg_chroma.png`: generated egg source on a chroma
  background.
- `assets/art/ice/ice_dragon_source.png`: original supplied dragon reference.

The egg was generated to inherit Frosteros's pale-blue, white, cyan-crystal, and
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

`tests/domain_test.gd` verifies that the Frosteros definition remains available for
legacy data. `tests/smoke_test.gd` verifies that the active shop rejects ice-egg
purchases without spending gold.
