class_name GameCanvas
extends Control

const DESIGN_WIDTH := 720.0
const BASE_DESIGN_HEIGHT := 1565.373
## The shortest logical canvas the layouts support (16:9 portrait, e.g. iPhone SE).
## Windows with a smaller height-to-width ratio (tablets, foldables, desktop browsers)
## are fitted by height instead and centered, so nothing is cut off at the bottom.
const MIN_DESIGN_HEIGHT := 1280.0

var logical_size := Vector2(DESIGN_WIDTH, BASE_DESIGN_HEIGHT)


func fit_to(viewport_size: Vector2) -> bool:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return false
	var fit_scale := viewport_size.x / DESIGN_WIDTH
	var logical_height := viewport_size.y / fit_scale
	if logical_height < MIN_DESIGN_HEIGHT:
		fit_scale = viewport_size.y / MIN_DESIGN_HEIGHT
		logical_height = MIN_DESIGN_HEIGHT
	var changed := absf(logical_height - logical_size.y) > 0.5
	logical_size = Vector2(DESIGN_WIDTH, logical_height)
	size = logical_size
	clip_contents = true # Decorations never spill into the side margins.
	scale = Vector2.ONE * fit_scale
	position = Vector2((viewport_size.x - DESIGN_WIDTH * fit_scale) * 0.5, 0.0)
	return changed


## Returns true when the window is wider than the tallest-supported phone shape and the
## canvas is centered with side margins.
func is_side_fitted(viewport_size: Vector2) -> bool:
	return viewport_size.y / (viewport_size.x / DESIGN_WIDTH) < MIN_DESIGN_HEIGHT


## Logical canvas units per physical window pixel, for converting safe-area insets.
static func logical_per_pixel(window_size: Vector2) -> float:
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return 1.0
	if window_size.y / (window_size.x / DESIGN_WIDTH) < MIN_DESIGN_HEIGHT:
		return MIN_DESIGN_HEIGHT / window_size.y
	return DESIGN_WIDTH / window_size.x


func safe_top_inset() -> float:
	if OS.get_name() not in ["iOS", "Android"]:
		return 0.0
	var safe_area := DisplayServer.get_display_safe_area()
	var window_size := DisplayServer.window_get_size()
	if safe_area.position.y <= 0 or window_size.x <= 0:
		return 104.0 if OS.get_name() == "iOS" else 64.0
	return float(safe_area.position.y) * logical_per_pixel(Vector2(window_size)) + 18.0


func safe_bottom_inset() -> float:
	if OS.get_name() not in ["iOS", "Android"]:
		return 0.0
	var safe_area := DisplayServer.get_display_safe_area()
	var window_size := DisplayServer.window_get_size()
	if safe_area.size.y <= 0 or window_size.x <= 0:
		return 58.0 if OS.get_name() == "iOS" else 28.0
	var unsafe_bottom := maxi(
		0,
		window_size.y - safe_area.position.y - safe_area.size.y
	)
	return float(unsafe_bottom) * logical_per_pixel(Vector2(window_size)) + 14.0


func safe_top_y(base_y: float = 32.0) -> float:
	return maxf(base_y, safe_top_inset())


func island_vertical_offset() -> float:
	return clampf((logical_size.y - 1280.0) * 0.5, 0.0, 180.0)
