# Art Prompts — Visual Style Cleanup

Image-generation prompts for replacing the code-drawn UI (buttons, panels, clouds, ground)
with polished modern pixel-art assets. Dragons, islands, and eggs keep their existing art.

**Read the Ground Rules first** — the shared style block goes at the top of *every* prompt.
AI image models default to fake pixel art (anti-aliased edges, 5000 colors, off-grid pixels).
The constraints below are what force real output.

---

## 0. Ground Rules

### Responsive canvas and pixel-art grid

The GBA influence is a **visual language**, not a fixed GBA-sized screen. Do not force the
game into a 240 × 428 viewport or require integer-only whole-screen scaling. Those rules
letterbox or crop modern 19.5:9 and 20:9 phones, waste space on tablets, and make localized
UI unnecessarily cramped.

The project uses its existing responsive canvas:

- **720 logical units wide**; the logical height expands to match the device aspect ratio
- Godot: `stretch/mode = "canvas_items"`, `stretch/aspect = "expand"`
- width-based fitting through `GameCanvas`, with safe-area insets for camera cutouts,
  the Dynamic Island, and home indicators
- backgrounds may bleed through the entire viewport; controls and important artwork must
  remain inside the safe area

Use a separate **1× pixel-art authoring grid** for assets. A nominal 240-pixel art width maps
to the 720-unit design width at **3 logical units per art pixel**. All dimensions in the
prompts below are source art pixels unless a prompt explicitly says otherwise. For example,
a 32 × 32 source button is normally displayed at 96 × 96 logical units.

Keep each asset's on-screen scale an integer multiple of its source size whenever practical.
The final canvas-to-device scale may be fractional; that is expected on modern high-density
screens. Use nearest-neighbour texture filtering, disable mipmaps for UI art, and snap static
UI placement to whole logical units. Never stretch sprites non-uniformly.

Layout must be responsive rather than scaled as one fixed composition:

- anchor headers and resource counters below the safe top inset
- anchor bottom actions above the safe bottom inset
- allow flexible vertical spacing in the middle of the screen
- use containers and 9-slices for localized text and accessibility-sized controls
- test at minimum on 16:9, 19.5:9, 20:9, and a tablet aspect ratio

### Palette (24 colors — do not exceed)

| Role | Hex |
|---|---|
| Ink (all outlines) | `#382b3d` |
| Ink soft | `#6f5a70` |
| Pink light / base / dark | `#f08bb0` `#e75d91` `#9e3f68` |
| Cream light / base / deep / shade | `#fffaf0` `#fff1d2` `#f3d9ae` `#d9b98a` |
| Sky light / base / dark | `#a8e6f5` `#78d6ed` `#4fb3d0` |
| Sky haze | `#dff3ef` |
| Green light / base / dark | `#a9d69a` `#4f956c` `#35684d` |
| Gold light / base / dark | `#f5c877` `#e9aa46` `#ad6f31` |
| Lilac / lilac dark | `#9a78b3` `#6d5085` |
| Rock light / base / dark | `#8a6f5c` `#5f4a42` `#3d2f2e` |

### Shared style block — paste at the START of every prompt

```
Polished contemporary mobile-game pixel art with a restrained 16-bit handheld
influence. Stylized and visibly pixelated, but fresh and current rather than
nostalgic or old-fashioned. Clean mobile UI hierarchy and generous spacing.
STRICT: hard-edged pixels only, NO anti-aliasing, NO gradients, NO blur,
NO soft or drop shadows, NO transparency except fully transparent background.
Every pixel snapped to the grid. Limited palette, flat color fills with
2-tone shading only. Single 1px dark outline (#382b3d) around every shape.
Light source is top-left: highlights on top and left faces, shade on bottom
and right faces. Playful stepped silhouettes and subtle asymmetry, with no
ornate decoration. Front-facing orthographic, no perspective.
Palette restricted to: [paste palette hexes]
```

### Negative block — paste at the END of every prompt

```
NOT: anti-aliased, smooth, vector, flat design, Material Design, iOS style,
3D render, glossy, bevel, gloss highlight, soft shadow, gaussian blur,
gradient mesh, photorealistic, painterly, watercolor, high resolution detail,
gridlines, checkerboard, watermark, text, letters, numbers, dated retro UI,
literal imitation of an existing game interface, excessive nostalgia styling.
```

### Post-process every output (non-negotiable)

The model will still cheat. Always run this on the result:

1. Downscale to the exact source-asset size with **nearest-neighbour** (never bicubic/Lanczos)
2. Quantize to the palette above (Aseprite: `Sprite > Color Mode > Indexed` with the palette loaded)
3. Delete stray semi-transparent pixels on the alpha edge
4. For tiles and 9-slices: manually verify the seams tile/stretch cleanly
5. Import UI textures with nearest-neighbour filtering and mipmaps disabled
6. Preview at the intended in-game size on both a high-density phone and a tablet; judge
   readability at actual size, not only while zoomed into the source asset

### Standing-dragon presentation

Standing dragon textures must have a fully transparent background and must not contain a
baked-in ground shadow. Present them through `WidgetFactory.dragon_presentation()` rather
than positioning a separate shadow per dragon. The shared presenter reads the texture's
visible alpha bounds, centers the pixel shadow beneath the actual feet, and keeps that
contact point correct when source images have different padding or aspect ratios.

Grooming and side-view flight sprites are interaction-specific exceptions and do not use
the standing-dragon presenter.

Prompts 1–6 are the ones that fix the "modern app" feel. Do those first.

---

## 1. Style Reference Sheet

Generated project references:

- Production-size palette-quantized sheet:
  `assets/art/ui_redesign/reference/style_reference.png` (240 × 180)
- Original generation retained for comparison:
  `assets/art/ui_redesign/reference/style_reference_source.png`

Use the production-size sheet as the style reference for every later generated UI asset.
It defines the visual direction but is not itself loaded by the game at runtime.

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

Current integrated assets:

- Runtime 3× textures: `assets/art/ui_redesign/buttons/*.png` (96 × 96)
- Palette-locked 1× masters: `assets/art/ui_redesign/buttons/source/*.png` (32 × 32)
- Visual exploration sheet: `assets/art/ui_redesign/reference/buttons_reference_source.png`
- Reproducible generator: `tools/generate_ui_button_assets.gd`

`WidgetFactory` selects the nearest palette family for existing button colors and uses
separate idle and pressed 9-slices. Pink, green, gold, cream, lilac, and sky variants are
integrated. Runtime textures are exact 3× nearest-neighbour enlargements of the masters so
one source art pixel maps to three 720-canvas logical units.

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

Current integrated assets:

- Runtime 3× textures: `assets/art/ui_redesign/clouds/*.png`
- Palette-locked 1× masters: `assets/art/ui_redesign/clouds/source/*.png`
- Visual exploration sheet: `assets/art/ui_redesign/reference/clouds_reference_source.png`
- Reproducible generator: `tools/generate_ui_cloud_assets.gd`

The six opaque cloud variants replace code-drawn clouds in `PixelSky`, `FlightGame`, and
`FlightRaceBackground`. Every consuming control forces nearest-neighbour filtering.

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

Current integrated assets:

- Runtime 3× scenery: `assets/art/ui_redesign/flight_environment/*.png`
- Palette-locked masters: `assets/art/ui_redesign/flight_environment/source/*.png`
- Generation references: `assets/art/ui_redesign/reference/flight_forest_reference_source.png`
  and `flight_towers_reference_source.png`
- Reproducible scenery post-process: `tools/generate_flight_environment_assets.gd`

`FlightGame` scrolls two cloud layers at 10 and 18 logical units per second and one unified
landscape at 40. The field, forest canopy, and meadow edge are composited into the single
`landscape.png` strip so no plain-color gaps separate them in game. Every background layer is
deliberately slower than the 235-unit foreground towers. Tower gap caps use broad, shallow
ruined battlements instead of narrow spikes so their visible and collision boundaries remain
readable.

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

Current integrated care sprites:

- Runtime 3× sprites: `assets/art/ui_redesign/icons/sunberry.png` and
  `grooming_comb.png`
- Palette-locked masters: `assets/art/ui_redesign/icons/source/*.png`
- Image-generation references: `assets/art/ui_redesign/icons/reference/*.png`
- Reproducible post-process: `tools/generate_ui_care_assets.gd`

The island status panel, care-action buttons, feeding animation, and draggable grooming tool
all use these textures through `WidgetFactory.pixel_icon()`. The former code-drawn berry and
comb placeholders have been removed.

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
- Use integer logical font sizes and place labels on whole logical units; do not require the
  entire device canvas to use an integer scale
- Disable MSDF and mipmaps; compare monochrome/no anti-aliasing with grayscale anti-aliasing
  on real high-density phones and keep the most readable option
- Verify long German labels at the narrowest supported safe width without shrinking them
  below the minimum readable size

---

## Suggested order of work

| # | Assets | Impact |
|---|---|---|
| 1 | Responsive-layout and safe-area audit | Very high — foundation already exists |
| 2 | Font swap (no art needed) | Very high — free |
| 3 | Prompt 2 (buttons) | Very high |
| 4 | Prompt 4 (clouds) | High |
| 5 | Prompt 3 (panels) | High |
| 6 | Prompt 5 (flight ground/parallax) | High — fixes the worst screen |
| 7 | Prompts 6, 7 (icons, bars) | Medium |
| 8 | Prompt 8 (flight dragons) | Medium |
