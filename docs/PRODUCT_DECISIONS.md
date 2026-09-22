# Product decisions

Confirmed decisions by the product owner (Jakob). They override the original requirements
report (`docs/requirements/DRAGO_PRODUKTANFORDERUNGEN_UND_IMPLEMENTIERUNGSPLAN.html`)
wherever they conflict. Add new entries at the bottom with a date; do not silently edit old
ones. Mark a replaced entry as **Superseded by D-xx**.

## Decisions

### D-01 Engine: Godot stays (2026-07, reconfirmed 2026-09-22)
The game is built in Godot 4.6 with GDScript. The report's SwiftUI/SpriteKit/SwiftData
stack is not adopted. Native code is limited to platform plugins (HealthKit, Health Connect).

### D-02 Genre and audience (2026-09)
A cozy care, breeding and training game in the spirit of Tamagotchi. Target players are
around 6 and 11 years old. Progressive disclosure: icons, stars and short sentences by
default, exact numbers in an optional detail layer.

### D-03 No Pokémon-style battles (2026-09-22)
There are no turn-based dragon-vs-dragon battles, no PvP and no adaptive opponent ladder.
The report's sections on the combat system, the ladder and battle rewards (9 to 11) are
out of scope.

Combat *mechanics inside training minigames* are allowed and wanted:

- The Element Power training is an auto-firing top-down flying shooter.
- A **survivor mode** (Vampire Survivors-like: auto attacks, waves, upgrades, survive as
  long as possible) is a confirmed long-term goal.

Therefore dragons keep combat-style stats. Current: `attack_power`, `attack_speed`,
`movement_speed`. Planned: `hp` (needed by survivor mode). These stats feed minigames,
never a dragon-vs-dragon fight.

### D-04 Art style: comic, procedural dragons (2026-09-22)
The canonical look is the current comic style: rounded plum ink contours, soft satin
shading, pastel palette, Nunito font, procedural dragons rendered by `SeededDragon` /
`DragonViews`. Strict pixel art (the original "old-school Pokémon" brief and
`docs/art_prompts.md`) was dropped because dragons must be generatable and the pixel style
could not support that. Pokémon influence remains in tone and structure (collect, raise,
contest), not in pixel rendering.

### D-05 Offline and private (2026-07)
No accounts, backend, cloud, ads, analytics or remote config. HealthKit is read-only,
optional, and only aggregate step counts are stored.

### D-06 Starter and eggs (2026-09)
- A new game has one free starter egg that hatches immediately (no steps, no gold).
- The shop sells one generic Dragon Egg for 1 gold. It contains a random base dragon.
- Bought and bred eggs need 5,000 steps.
- The hidden result (species, appearance seed, attribute potentials, parents) is fixed when
  the egg is created and never rerolled.
- The shop is reachable only from the main menu. The den manages dragons, eggs and fusion.
- The report's rarity tiers (2,000 to 20,000 steps, legendary tasks) are not adopted yet.

### D-07 Economy (2026-09)
Gold is earned by winning contests and spent on eggs. Fusion Stars pay for fusion.
How the report's elemental stones and level stones fit in is **open** (see Q-02).

### D-08 Collection (2026-09)
Multiple dragons of the same species are allowed. Den capacity is 12 (dragons + eggs).
The old one-dragon-per-type rule is removed.

### D-09 Attributes and inheritance (2026-09)
Each dragon has a trained value and a fixed individual potential per attribute. New
dragons start at 10. Shop/starter potentials roll 30 to 100 (provisional). In fusion the
player picks, per attribute, which parent supplies the potential. Trained values are never
inherited. Parents are never consumed.

## Open questions

Record the answer as a new decision when the user settles one.

- **Q-01 Survivor mode scope.** Which stats beyond HP (defense, pickup range, crit)? Is it
  a training category with XP and records, a contest, or its own mode with rewards?
- **Q-02 Stones and catch-up.** Adopt elemental stones and level stones from the report,
  or keep only gold and Fusion Stars?
- **Q-03 Care over time.** Should hunger and cleanliness decay with real time (Tamagotchi
  pressure), and how gently for young players?
- **Q-04 Genetics depth.** How far should visual inheritance go (palette, body, wings,
  horns, pattern, tail), and do mutations or rarity exist in version one?
- **Q-05 Element Power theme.** The shooter's enemies are knights. Keep them, or switch to
  a softer target set (for example storm clouds or shadow blobs) for the younger audience?
- **Q-06 One child per pair.** The breeding architecture proposes one permanent child per
  parent pair. The current fusion allows repeated fusion. Which rule applies?
- **Q-07 Step alternative.** What is the equivalent progression for players without
  HealthKit (minigame, timer, tasks)?
- **Q-08 Stat naming for kids.** Keep "attack power / attack speed" labels, or use softer
  names like "Power", "Speed", "Agility" in the UI?
