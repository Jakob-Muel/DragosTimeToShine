# Flight gameplay

## Player flow
The main-menu **Contest** button opens the flight dragon selection, then the **Flight
hub** for the chosen dragon:

1. **Flight Training** is always available. It runs through the generic
   `training_session` route with `talent_id = "flight"`.
2. **Flight Contest** unlocks when the dragon's contest distance reaches its next goal.

Progress belongs to the selected dragon. Newly hatched dragons begin with zero flight XP
and train independently.

## Flight Training

Training is a tap-to-flap obstacle game:

- tap or click anywhere in the flight area to gain height;
- gravity continually pulls the dragon down;
- rock-spike pairs move from right to left;
- the opening begins at 300 logical pixels high, shrinks by 15 pixels after
  every five cleared obstacles, and never becomes smaller than 130 pixels;
- neighboring opening centers begin with a 200-pixel movement delta; this
  grows by 15 pixels per cleared obstacle and is capped at 500 pixels;
- after ten obstacles, neighboring opening centers must differ by at least
  75 pixels; that required minimum grows by 15 pixels every five obstacles
  and is capped at 150 pixels from obstacle 35 onward;
- clearing one spike pair immediately awards and saves one flight XP;
- touching a spike or leaving the flight area ends the round;
- there is no round-length limit, so one strong run can gain multiple levels.

Ten accumulated XP adds one Flight Level. XP earned before a collision is kept, and the
counter continues past ten obstacles. Clearing 50 obstacles in one run therefore reaches
Flight Level 5; players can continue farming higher levels until they collide.

`scripts/ui/flight_game.gd` owns moment-to-moment physics and emits only the round result.
`GameState` stores persistent XP in the dragon's category map and derives its level from
the Flight Training definition.

## Flight Contest
Contest distance is `Flight Level × 10 metres` (`units_per_level` in
`data/training/flight.tres`). Each dragon has three contest goals in order, tracked by
`flight_contest_wins`:

| Win # | Goal | Needed level | Opponent distances |
| --- | --- | --- | --- |
| 1 | 50 m | 5 | 38, 44, 48 |
| 2 | 70 m | 7 | 56, 63, 68 |
| 3 | 100 m | 10 | 82, 91, 98 |

The contest is enterable only when the dragon's distance reaches the current goal, so an
entered contest is always won. The dragon races three opponent dragons across a scrolling
landscape and glides down while the distance counter advances. Each win awards one gold
coin (`gold_reward`) and offers a route to the shop. After three wins there are no more
flight goals for that dragon.

Values live in `GameState` (`FLIGHT_CONTEST_GOALS`, `flight_contest_opponent_distances`).

```text
train → reach the goal level → race → win 1 gold → buy 1 egg
```

## Art assets
- The player dragon is drawn procedurally from its `appearance_seed` in the flight pose
  (`ProceduralDragonTextures.texture_for(seed, "flight")`), with linear filtering in the
  comic style.
- Contest opponents use `assets/art/comic/flight/opponents/`.
- `scripts/ui/flight_pillar.gd` draws the rock obstacles in code.
- `scripts/ui/flight_race_background.gd` and `assets/art/comic/source/ui_redesign/flight_environment/`
  provide the scrolling contest landscape (see `docs/COMIC_ART.md` for the scrolling contract).
- Older sprites in `assets/art/flight/` and `tools/prepare_flight_assets.gd` are legacy.

Collision boxes cover the dragon's body and the rock cores rather than every visible wing,
tail or spike corner, making close passes more forgiving.

Attributes (`movement_speed`) are trained by flight runs but do not yet change flight
physics (see `docs/ROADMAP.md` M2.2).

