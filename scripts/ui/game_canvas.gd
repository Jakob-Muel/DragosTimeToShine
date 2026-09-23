class_name GameCanvas
extends Control

const DESIGN_WIDTH := 720.0
const BASE_DESIGN_HEIGHT := 1565.373

var logical_size := Vector2(DESIGN_WIDTH, BASE_DESIGN_HEIGHT)


func fit_to(viewport_size: Vector2) -> bool:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return false
	var width_scale := viewport_size.x / DESIGN_WIDTH
	var responsive_height := viewport_size.y / width_scale
	var changed := absf(responsive_height - logical_size.y) > 0.5
	logical_size = Vector2(DESIGN_WIDTH, responsive_height)
	size = logical_size
	scale = Vector2.ONE * width_scale
	position = Vector2.ZERO
	return changed


func safe_top_inset() -> float:
	if OS.get_name() not in ["iOS", "Android"]:
		return 0.0
	var safe_area := DisplayServer.get_display_safe_area()
	var window_size := DisplayServer.window_get_size()
	if safe_area.position.y <= 0 or window_size.x <= 0:
		return 104.0 if OS.get_name() == "iOS" else 64.0
	return float(safe_area.position.y) * DESIGN_WIDTH / float(window_size.x) + 18.0


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
	return float(unsafe_bottom) * DESIGN_WIDTH / float(window_size.x) + 14.0


func safe_top_y(base_y: float = 32.0) -> float:
	return maxf(base_y, safe_top_inset())


func island_vertical_offset() -> float:
	return clampf((logical_size.y - 1280.0) * 0.5, 0.0, 180.0)
