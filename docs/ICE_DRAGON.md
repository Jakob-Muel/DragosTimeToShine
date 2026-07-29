# Frost: Egg, Dragon, and Island

## Player flow

1. Win one gold coin by reaching Flight Level 5 and completing a 50-metre
   Flight Contest glide.
2. Buy the **Frost Crystal Egg** in the shop for one gold.
3. Start incubation and accumulate 1,000 steps.
4. Hatch Frost, whose saved species is `ice`.
5. Select Frost in the dragon den to visit the snow-and-crystal island.

Frost uses the same care, grooming, flight-training, and contest systems as the
starter dragon. Flight XP is stored on each dragon, so progress follows the
selected dragon.

## Species data

Eggs store a stable `kind`, and dragons store a stable `species`. The current
mapping is:

| Egg kind | Hatched dragon | Dragon species | Habitat |
| --- | --- | --- | --- |
| `ice` | Frost | `ice` | Ice island |
| `sunwing` | Nova | `sunwing` | Green island |

Older saves without these fields default to `sunwing`. Display names remain
localization keys rather than save-file text.

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

`tests/smoke_test.gd` verifies the purchase, `ice` egg kind, 1,000-step
incubation, Frost hatch, species-specific habitat texture, grooming, per-dragon
Flight Level 5 progression, contest completion, and gold reward.
