# Art Prompts — Visual Style Cleanup

Image-generation prompts for replacing the code-drawn UI (buttons, panels, clouds, ground)
with real pixel art assets.

**Read the Ground Rules first** — the shared style block goes at the top of *every* prompt.
AI image models default to fake pixel art (anti-aliased edges, 5000 colors, off-grid pixels).
The constraints below are what force real output.

---

## 0. Ground Rules

### Target resolution

Virtual canvas: **240 × 428** portrait (240 wide is a deliberate GBA nod; 428 tall covers 9:16 phones).
One virtual pixel = 1/240 of screen width. Godot: `stretch/mode = "viewport"`, `scale_mode = "integer"`.

Every asset below is sized in **virtual pixels**. Generate small, scale up with nearest-neighbour.

### Palette (24 colors — do not exceed)

| Role | Hex |
|---|---|
| Ink (all outlines) | `#382b3d` |
| Ink soft | `#6f5a70` |
| Pink light / base / dark | `#f08bb0` `#e75d91` `#9e3f68` |
| Cream light / base / deep / shade | `#fffaf0` `#fff1d2` `#f3d9ae` `#d9b98a` |
| Sky light / base / dark | `#a8e6f5` `#78d6ed` `#4fb3d0` |
| Green light / base / dark | `#a9d69a` `#4f956c` `#35684d` |
| Gold light / base / dark | `#f5c877` `#e9aa46` `#ad6f31` |
| Lilac / lilac dark | `#9a78b3` `#6d5085` |
| Rock light / base / dark | `#8a6f5c` `#5f4a42` `#3d2f2e` |

### Shared style block — paste at the START of every prompt

```
16-bit GBA-era pixel art, in the style of Pokémon Ruby/Sapphire UI.
STRICT: hard-edged pixels only, NO anti-aliasing, NO gradients, NO blur,
NO soft or drop shadows, NO transparency except fully transparent background.
Every pixel snapped to the grid. Limited palette, flat color fills with
2-tone shading only. Single 1px dark outline (#382b3d) around every shape.
Light source is top-left: highlights on top and left faces, shade on bottom
and right faces. Front-facing orthographic, no perspective.
Palette restricted to: [paste palette hexes]
```

### Negative block — paste at the END of every prompt

```
NOT: anti-aliased, smooth, vector, flat design, Material Design, iOS style,
3D render, glossy, bevel, gloss highlight, soft shadow, gaussian blur,
gradient mesh, photorealistic, painterly, watercolor, high resolution detail,
gridlines, checkerboard, watermark, text, letters, numbers.
```

### Post-process every output (non-negotiable)

The model will still cheat. Always run this on the result:

1. Downscale to the exact target size with **nearest-neighbour** (never bicubic/Lanczos)
2. Quantize to the palette above (Aseprite: `Sprite > Color Mode > Indexed` with the palette loaded)
3. Delete stray semi-transparent pixels on the alpha edge
4. For tiles and 9-slices: manually verify the seams tile/stretch cleanly

Prompts 1–6 are the ones that fix the "modern app" feel. Do those first.

---

## 1. Style Reference Sheet — generate this FIRST

Lock the look once, then reference this image in every later prompt.

```
[STYLE BLOCK]

A pixel art UI style reference sheet on a plain dark grey background,
arranged in a neat grid with generous spacing between elements:
- one pink rectangular button with a 1px dark outline and a 3px hard
  offset shadow in dark pink, square corners with a single 2px chamfer
  cut off each corner
- one cream rectangular panel frame with a 2px dark outline and a 1px
  inner highlight line along the top and left edges
- three small fluffy clouds, opaque cream, with a lit top edge, a shaded
  underside, and a full dark outline
- one horizontal progress bar: dark outlined trough with a gold fill
- four 16x16 icons: a heart, a coin, a gear, a red berry

Total image 240x180 pixels. Chunky, readable, cozy, cheerful.

[NEGATIVE BLOCK]
```

---

## 2. Button Frames — the highest-impact asset

Replaces the `StyleBoxFlat` in `scripts/ui/widget_factory.gd`.

Generate as a **9-slice source**: 32×32 with 10px corner margins. If the 9-slice edges come
out uneven, fall back to generating each button at its final fixed size (216×34 full-width,
104×34 half-width) — you only use two or three sizes anyway.

### 2a. Primary button (pink) — idle

```
[STYLE BLOCK]

A single pixel art game UI button frame, 32x32 pixels, transparent background.
Rectangular with square corners, except each corner has one 2px diagonal
chamfer cut. Fill is flat pink #e75d91. A 1px outline of #382b3d wraps the
entire shape. A 1px highlight line of #f08bb0 runs along the inside of the
top and left edges only. A 1px shade line of #9e3f68 runs along the inside
of the bottom and right edges only. Below and right of the button sits a
HARD offset shadow: a solid 3px block of #9e3f68 with NO transparency and
NO blur, offset 3px down and 3px right, following the button silhouette.
Completely empty in the center — no text, no icon, no decoration.

[NEGATIVE BLOCK]
```

### 2b. Primary button — pressed

```
[Same as 2a] but with these changes: the fill is the darker #9e3f68, the
inner highlight and shade lines are swapped (shade on top-left, highlight
on bottom-right, giving an inset look), and the offset shadow is reduced to
1px down and 1px right.
```

### 2c–2e. Color variants

Re-run 2a and 2b substituting the palette triplet:

| Variant | Light | Base | Dark |
|---|---|---|---|
| Green (secondary) | `#a9d69a` | `#4f956c` | `#35684d` |
| Gold (tertiary) | `#f5c877` | `#e9aa46` | `#ad6f31` |
| Cream (neutral / back) | `#fffaf0` | `#f3d9ae` | `#d9b98a` |

---

## 3. Panel & Card Frames

Replaces the cream rounded cards (stat panel, dialogs, header bar).

```
[STYLE BLOCK]

A single pixel art dialog box frame, 48x48 pixels, transparent background,
designed as a 9-slice with 16px corners. Cream fill #fff1d2. A 2px outline
of #382b3d wraps the whole shape. Corners are square with a 3px stepped
diagonal chamfer. Inside the outline, a 1px inner border line of #fffaf0
along the top and left, and #f3d9ae along the bottom and right, giving a
subtle raised bevel. Each of the four corners has one small decorative
2x2 pixel dot of #e75d91 set 4px in from the corner. Completely empty in
the center.

[NEGATIVE BLOCK]
```

### 3b. Header bar frame

```
[Same as 3] but a wide short frame, 48x24 pixels, 12px corner margins,
no decorative corner dots, and a 1px horizontal divider line of #d9b98a
running along the very bottom inside edge.
```

### 3c. Small badge / counter pill

For the top-bar currency counters (shield, coin).

```
[STYLE BLOCK]

A small pixel art UI badge frame, 24x16 pixels, transparent background,
9-slice with 8px left/right margins. Cream #fff1d2 fill, 1px #382b3d
outline, square corners with a 1px chamfer. A 1px #fffaf0 highlight along
the top inside edge. Empty center.

[NEGATIVE BLOCK]
```

---

## 4. Cloud Sheet

Replaces `_draw_cloud()` in `scripts/ui/pixel_art.gd`. The current clouds are semi-transparent
flat rectangles with a blur-like offset copy — this is the second most visible problem.

```
[STYLE BLOCK]

A pixel art sprite sheet of six fluffy clouds on a fully transparent
background, arranged in two rows of three with clear empty space between
each cloud so they do not touch.

Row 1 (large, roughly 48x24 pixels each): three distinct cloud shapes.
Row 2 (small, roughly 24x12 pixels each): three distinct smaller shapes.

Each cloud is built from stacked rectangular blocks with a stepped,
blocky silhouette — never smooth or circular. Each cloud is FULLY OPAQUE.
Each has: a 1px outline of #6f5a70 around the entire shape, a bright
#fffaf0 fill across the upper two thirds, and a #f3d9ae shaded band along
the underside and lower-right, following the bumps of the silhouette.
Vary the silhouettes clearly — one wide and flat, one tall and puffy, one
with a small trailing wisp.

Total image 160x48 pixels.

[NEGATIVE BLOCK]
```

**Note:** vary placement in code and add 2–3 parallax layers on the flight screen, which
currently shows only two clouds in a large empty sky.

---

## 5. Flight Screen Ground & Parallax

Replaces the solid green ColorRect with a hard black line (shots 3/4).

### 5a. Ground strip (tileable)

```
[STYLE BLOCK]

A seamlessly horizontally tileable pixel art ground strip, exactly
32x48 pixels. The top 6px is a grass surface layer in #a9d69a with an
irregular 2px stepped edge of #4f956c along the very top, and a few
scattered single-pixel #35684d blades. Below the grass, a soil layer in
#5f4a42 filling the remainder, with scattered 2x2 blocks of #3d2f2e and
#8a6f5c as pebbles and dirt variation. A 1px #382b3d line separates grass
from soil. The LEFT and RIGHT edges must match exactly so the strip tiles
seamlessly. No outline on the left or right edges.

[NEGATIVE BLOCK]
```

### 5b. Distant parallax hills

```
[STYLE BLOCK]

A seamlessly horizontally tileable pixel art background layer of distant
rolling hills, exactly 96x40 pixels, transparent above the hills. The hills
are flat silhouettes in a single desaturated blue-green #4f956c, no interior
detail, with a 1px lighter #a9d69a rim along the top ridge only. Blocky
stepped ridge line. Left and right edges must match exactly for seamless
tiling.

[NEGATIVE BLOCK]
```

### 5c. Sky gradient strip

```
[STYLE BLOCK]

A vertical pixel art sky gradient, exactly 8x160 pixels, made of exactly
6 hard-edged horizontal color bands with NO dithering and NO blending
between them. From top to bottom: #4fb3d0, #78d6ed, #78d6ed, #a8e6f5,
#a8e6f5, #dff3ef. Each band is a solid flat block of color. The image
tiles horizontally.

[NEGATIVE BLOCK]
```

---

## 6. Icon Sheet

The existing top-bar icons are close; these unify them and fill the gaps.

```
[STYLE BLOCK]

A pixel art icon sheet on a fully transparent background: 12 icons in a
grid of 4 columns by 3 rows, each icon exactly 16x16 pixels with the cell
boundaries left empty (no gridlines drawn).

The icons, in reading order:
1. a heart, pink #e75d91
2. a gold coin with a small notch, #e9aa46
3. a gear/cog, cream #f3d9ae
4. a red berry with two green leaves
5. a grooming brush with a wooden handle
6. a dragon egg with spots
7. a feathered wing, cream
8. a five-pointed star, gold
9. a left-pointing chevron arrow, dark
10. a small water droplet, blue
11. a flame, orange-gold
12. a leaf, green

Every icon has a 1px #382b3d outline and flat 2-tone shading. Bold, chunky,
readable at actual size — minimal interior detail. Total image 64x48 pixels.

[NEGATIVE BLOCK]
```

---

## 7. Progress Bar

For the Hunger / Sauber bars, currently smooth rounded rectangles.

```
[STYLE BLOCK]

Two pixel art UI progress bar parts on a transparent background, stacked
vertically with empty space between them.

TOP: an empty bar trough, 48x12 pixels, 9-slice with 6px left/right
margins. A 1px #382b3d outline, interior filled with #d9b98a, and a 1px
#9e3f68 shade line along the top inside edge (inset look). Square corners.

BOTTOM: a bar fill, 48x8 pixels, 9-slice with 6px left/right margins.
Solid #e9aa46 with a 1px #f5c877 highlight line along the top edge and a
1px #ad6f31 line along the bottom edge. No outline.

Total image 48x28 pixels.

[NEGATIVE BLOCK]
```

---

## 8. Flight Dragon Re-render

The flight dragon (shot 4) is pale blue on pale blue sky and nearly invisible, and its pixel
density does not match the menu dragon.

```
[STYLE BLOCK]

A pixel art sprite of a small cute dragon in side-view flight, facing right,
exactly 32x24 pixels, on a fully transparent background. Body in pink
#e75d91 with a cream #fff1d2 belly and wing membranes. Small horns, a
rounded snout, one large friendly eye, wings spread and raised.

CRITICAL: a solid 1px #382b3d outline around the ENTIRE silhouette,
including the wings, so the sprite reads clearly against a light blue sky.
Flat 2-tone shading only — one base color plus one darker shade per body
part. Chunky and readable, minimal detail, exaggerated cute proportions
with a large head relative to the body.

[NEGATIVE BLOCK]
```

Repeat per element, swapping the body palette: fire `#e9aa46`/`#ad6f31`, water
`#78d6ed`/`#4fb3d0`, earth `#a9d69a`/`#4f956c`, ice `#a8e6f5`/`#fffaf0`, lava
`#e75d91`/`#ad6f31`. The cream belly and the dark outline stay constant in all variants.

**Also generate a 3-frame wing flap animation:** re-run with `wings raised high above the
body` / `wings level with the body` / `wings swept low below the body`, keeping everything
else identical.

---

## 9. Font

No image generation needed. `assets/fonts/PixelifySans-Bold.ttf` and `-Regular.ttf` are
already in the repo but unused — `scripts/ui/ui_tokens.gd` only preloads Nunito.

Before switching, verify:

- German umlauts `ä ö ü Ä Ö Ü ß` render correctly
- The font is used at exact integer multiples of its design size, or it will blur
- Enable `Nearest` filtering on the font import, and disable font anti-aliasing / MSDF

---

## Suggested order of work

| # | Assets | Impact |
|---|---|---|
| 1 | Font swap (no art needed) | Very high — free |
| 2 | Prompt 2 (buttons) | Very high |
| 3 | Prompt 4 (clouds) | High |
| 4 | Prompt 3 (panels) | High |
| 5 | Prompt 5 (flight ground/parallax) | High — fixes the worst screen |
| 6 | Prompts 6, 7 (icons, bars) | Medium |
| 7 | Prompt 8 (flight dragons) | Medium |
| 8 | Virtual-resolution migration | Highest, but invasive — do last |
