class_name FlightRaceBackground
extends Control

## Each texture owns its repeat period. Never reset a shared distance at an
## unrelated width: doing so changes the visible pattern at the wrap boundary.
const SKY := preload("res://assets/art/comic/sky.png")
const MOUNTAINS := preload("res://assets/art/comic/ui_redesign/flight_environment/mountains.png")
const HILLS := preload("res://assets/art/comic/ui_redesign/flight_environment/landscape.png")
const GROUND := preload("res://assets/art/comic/ui_redesign/flight_environment/foreground.png")
const CLOUD := preload("res://assets/art/comic/ui_redesign/clouds/large_wide.png")
var scroll_speed := 185.0
var scroll_offset := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func set_scroll_speed(value: float) -> void:
	scroll_speed = maxf(0.0, value)

func _process(delta: float) -> void:
	scroll_offset += scroll_speed * delta
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(SKY, Rect2(Vector2.ZERO, size), false)
	_tile(MOUNTAINS, size.y * 0.55, scroll_offset * 0.18, Color("#86a9ba"))
	# Repeat the entire three-cloud composition, including its varied heights.
	var period := 1260.0
	var shift := -fposmod(scroll_offset * 0.33, period)
	for cycle in range(-1, ceili(size.x / period) + 1):
		for index in 3:
			draw_texture(CLOUD, Vector2(shift + cycle * period + index * 420, 170 + index * 123))
	_tile(HILLS, size.y - 380.0, scroll_offset * 0.56, Color("#719c8b"))
	_tile(GROUND, size.y - 180.0, scroll_offset, Color("#83b27c"))

func _tile(texture: Texture2D, y: float, distance: float, bottom_color: Color) -> void:
	var bottom := y + texture.get_height() - 1.0
	if bottom < size.y:
		draw_rect(Rect2(0, bottom, size.x, size.y - bottom), bottom_color)
	var width := float(texture.get_width())
	var shift := -fposmod(distance, width)
	for index in range(-1, ceili(size.x / width) + 1):
		draw_texture(texture, Vector2(shift + index * width, y))
