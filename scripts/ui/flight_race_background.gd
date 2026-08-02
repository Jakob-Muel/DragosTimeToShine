class_name FlightRaceBackground
extends Control

const LARGE_CLOUDS := [
	preload("res://assets/art/ui_redesign/clouds/large_wide.png"),
	preload("res://assets/art/ui_redesign/clouds/large_tall.png"),
	preload("res://assets/art/ui_redesign/clouds/large_wisp.png"),
]
const SMALL_CLOUDS := [
	preload("res://assets/art/ui_redesign/clouds/small_wide.png"),
	preload("res://assets/art/ui_redesign/clouds/small_tall.png"),
	preload("res://assets/art/ui_redesign/clouds/small_wisp.png"),
]

var scroll_speed := 185.0
var scroll_offset := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(true)
	queue_redraw()


func set_scroll_speed(value: float) -> void:
	scroll_speed = maxf(0.0, value)


func _process(delta: float) -> void:
	scroll_offset = fmod(scroll_offset + scroll_speed * delta, 1440.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#72d8f2"))
	draw_circle(Vector2(size.x - 105, 128), 58, Color("#ffe88d"))
	_draw_far_mountains()
	_draw_cloud_layer()
	_draw_hills()
	_draw_ground()


func _draw_far_mountains() -> void:
	var shift := fposmod(-scroll_offset * 0.22, 280.0) - 280.0
	var baseline := size.y * 0.70
	for index in 6:
		var x := shift + index * 280.0
		var points := PackedVector2Array([
			Vector2(x, baseline),
			Vector2(x + 92, baseline - 155),
			Vector2(x + 182, baseline),
		])
		draw_colored_polygon(points, Color("#8ca8bd"))
		var snow := PackedVector2Array([
			Vector2(x + 58, baseline - 98),
			Vector2(x + 92, baseline - 155),
			Vector2(x + 124, baseline - 101),
			Vector2(x + 105, baseline - 111),
			Vector2(x + 90, baseline - 92),
			Vector2(x + 76, baseline - 111),
		])
		draw_colored_polygon(snow, Color("#fff3d1"))


func _draw_cloud_layer() -> void:
	var shift := fposmod(-scroll_offset * 0.45, 360.0) - 360.0
	for index in 5:
		var x := shift + index * 360.0
		var y := 180.0 + float(index % 3) * 170.0
		var cloud_set := LARGE_CLOUDS if index % 2 == 0 else SMALL_CLOUDS
		var texture: Texture2D = cloud_set[index % cloud_set.size()]
		draw_texture(texture, Vector2(x, y))


func _draw_hills() -> void:
	var shift := fposmod(-scroll_offset * 0.62, 230.0) - 230.0
	var baseline := size.y - 160.0
	for index in 7:
		var x := shift + index * 230.0
		var points := PackedVector2Array([
			Vector2(x, baseline),
			Vector2(x + 72, baseline - 88),
			Vector2(x + 145, baseline - 34),
			Vector2(x + 230, baseline),
		])
		draw_colored_polygon(points, Color("#72b779"))


func _draw_ground() -> void:
	var ground_y := size.y - 158.0
	draw_rect(Rect2(0, ground_y, size.x, size.y - ground_y), Color("#9bdb70"))
	draw_rect(Rect2(0, ground_y, size.x, 8), Color("#2f2140"))
	var shift := fposmod(-scroll_offset, 92.0) - 92.0
	for index in 10:
		var x := shift + index * 92.0
		draw_rect(Rect2(x + 18, ground_y + 48, 24, 7), Color("#68b85d"))
		draw_rect(Rect2(x + 53, ground_y + 104, 16, 7), Color("#6fc161"))
