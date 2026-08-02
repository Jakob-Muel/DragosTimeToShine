class_name GameScreen
extends Control

signal navigation_requested(route: String, params: Dictionary)

var canvas_size := Vector2(GameCanvas.DESIGN_WIDTH, GameCanvas.BASE_DESIGN_HEIGHT)
var safe_top_inset := 0.0
var safe_bottom_inset := 0.0
var context: Dictionary = {}


func configure(screen_context: Dictionary) -> void:
	context = screen_context
	canvas_size = screen_context.get("canvas_size", canvas_size)
	safe_top_inset = float(screen_context.get("safe_top_inset", 0.0))
	safe_bottom_inset = float(screen_context.get("safe_bottom_inset", 0.0))
	position = Vector2.ZERO
	size = canvas_size


func build() -> void:
	pass


func safe_top_y(base_y: float = 32.0) -> float:
	return maxf(base_y, safe_top_inset)


func safe_bottom_y(base_margin: float = 24.0) -> float:
	return canvas_size.y - maxf(base_margin, safe_bottom_inset)


func navigate(route: String, params: Dictionary = {}) -> void:
	navigation_requested.emit(route, params)


func tr_text(key: String, values: Dictionary = {}) -> String:
	var localization := get_node("/root/Localization")
	return localization.text(key, values)
