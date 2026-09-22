# Unified dragons and island

The existing soft, shaded Dragon Lab portrait is the style reference. `DragonViews` inherits that renderer without changing its portrait anatomy. Flight uses a continuous curved torso, tucked legs and swept wing membranes, plus the portrait's actual head, face, horns, frills, crest and forehead markings. The overhead view uses the same palette, body/wing proportions, horn renderer, forehead marks and eye color, with foreshortened anatomy.

`ProceduralDragonTextures` renders each seed/pose once into a transparent viewport, generates mipmaps, updates a cached ImageTexture and releases the viewport. Ordinary sprites display the result thereafter. Texture-change callbacks refresh portrait ground contact and the grooming alpha mask. There are no permanent offscreen viewports or per-frame texture readbacks.

An explicit `appearance_seed` is honored. Existing saves derive a stable seed from the individual dragon ID, independent of locale, collection order or changing care stats. Existing names, progression and gameplay types remain compatible. Collection portraits, habitat, grooming, training, the main menu and race opponents all use the shared rendering path. Headless logic tests use a placeholder because the dummy rendering backend cannot draw; the dedicated graphics test checks actual procedural images.

The fire minigame uses logical sprite boxes of 116×142 for the dragon, 65×78 for knights and 26×32 for flames. Hitboxes scale with those dimensions. TextureRect expansion is configured before assigning the size, preventing source texture resolution from silently enlarging sprites. Flight and scrolling behavior remain unchanged.

## Universal island

Every habitat and the main menu use `assets/art/comic/universal_island.png`. The static illustration has a broad uninterrupted meadow, a connected pond and waterfall, one tree and a few large rounded bushes. It uses simple shapes and restrained shading to match the dragons.

Generated with the **built-in Imagegen tool**, then copied into the project. The final edit used the initial island as its target and `assets/art/comic/dragon_pink_hd.png` as the strict style reference. The more detailed initial island was rejected and is not the shipped asset.

Exact final prompt:

> Edit target Image 1 (island). Image 2 (dragon) is the STRICT STYLE REFERENCE only, do not add the dragon to the result. User rejected Image 1 as MUCH TOO FANCY and not fitting the dragon. Radically simplify the island so it looks designed with the EXACT SAME smooth shaded cartoon/vector forms and limited visual complexity as Image 2. Keep Image 1 portrait framing and broad empty central lawn suitable for placing the dragon. Eliminate painterly texture, photorealism, dramatic lighting, sun rays, tiny leaves, detailed roots, tiny rocks, dense flowers, complex geology and all decorative excess. Use big, appealing, softly rounded graphic shapes with clean muted plum contour lines and restrained satin gradients, like the dragon's skin and belly. One cohesive rounded grassy floating island with a sculpted grassy lip over a simple rounded mauve stone underside. One small turquoise pond on the LEFT with a smooth organically integrated shore and a short connected waterfall. Two simple rounded bushes and ONE small simple broad-canopy cartoon tree at the far back edge. Only a few tiny grouped flowers. A wide uninterrupted clean pale-green lawn occupies central half of island. No path across center. Soft flat pastel cyan sky with two or three large simple cream cartoon clouds, quiet at the top for UI, pale at the bottom. No distant islands, no scenic realism, no fantasy-concept-art embellishment. Think uncluttered polished casual game artwork: same degree of simplicity, material shading, muted outline and form scale as the provided dragon. Everything naturally joins into one island; avoid scattered sticker-like disconnected assets. No dragons, characters, text, icons or UI in output. Portrait 720:1565.

## Verification and previews

- `tests/procedural_dragon_views_test.gd` checks 12 distinct real renders, deterministic identity, texture reuse, transparent margins, viewport release, the selected shooter seed and actual sprite dimensions.
- Domain, smoke, routing, safe-area, font, portrait, generator, shooter, training contract and training session tests cover existing behavior.
- `tests/comic_scrolling_render_test.gd` checks actual rendered frames around wrap boundaries, repeating tile edges and visible motion.
- `tools/capture_dragon_views.gd` produces four dragons in all views, including small flight sprites.
- `tools/capture_unified_review.gd` captures eight real screens and an overview; `-- short` adds six compact-phone previews. Capture waits for procedural textures to finish and does not write player saves.

Outputs are in `docs/screenshots/unified/`. Graphics tests and captures require a graphics device. On macOS, launch outside the restricted GUI sandbox and always supply a writable explicit `--log-file /tmp/<name>.log`; restricted NSApplication initialization can abort before Godot runs the project.
