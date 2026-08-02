# Flight gameplay

## Player flow

The main-menu **Contest** button opens **Flight School**, which has two choices:

1. **Flight Training** is always available.
2. **Flight Contest** unlocks when the selected dragon reaches Flight Level 5.

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

The contest is unlocked at Flight Level 5. Contest distance is:

```text
Flight Level × 10 metres
```

The dragon glides across the contest screen and descends to the ground while the distance
counter advances. Level 5 reaches 50 metres. A glide of at least 50 metres awards one gold
coin and offers a direct route to the shop.

Each new egg costs one gold coin. This closes the progression loop:

```text
train → reach Level 5 → glide 50 m → win 1 gold → buy 1 egg
```

## Art assets

- `assets/art/flight/flight_dragon.png` is the transparent, cropped game sprite prepared
  from the supplied flight-dragon image.
- `scripts/ui/flight_pillar.gd` draws the complete pixel-rock obstacle, including its
  tapered peak, irregular shaft stones, facet lighting, cracks, chips, and crystal
  clusters. Three palette and pattern variants are used for ceiling and ground pillars.
- `tools/prepare_flight_assets.gd` reproducibly crops and scales the checked-in source
  images with nearest-neighbour filtering.

The runtime uses nearest-neighbour texture filtering so the pixel edges remain crisp at
phone resolutions. The dragon sprite is horizontally flipped in training and the glide
contest so it faces the direction of travel. Collision boxes cover the dragon's body and the central
rock cores rather than every visible wing, tail, or transparent spike corner, making close
passes more forgiving.
