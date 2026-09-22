extends RefCounted

## Shared comic illustrations. Legacy class names remain for scene compatibility.
## Keeping them here prevents presentation details from obscuring screen flow.


class PixelSky:
	extends Control
	const LARGE_CLOUDS := [
		preload("res://assets/art/comic/ui_redesign/clouds/large_wide.png"),
		preload("res://assets/art/comic/ui_redesign/clouds/large_tall.png"),
		preload("res://assets/art/comic/ui_redesign/clouds/large_wisp.png"),
	]
	const SMALL_CLOUDS := [
		preload("res://assets/art/comic/ui_redesign/clouds/small_wide.png"),
		preload("res://assets/art/comic/ui_redesign/clouds/small_tall.png"),
		preload("res://assets/art/comic/ui_redesign/clouds/small_wisp.png"),
	]

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		queue_redraw()

	const SKY := preload("res://assets/art/comic/sky.png")

	func _draw() -> void:
		draw_texture_rect(SKY, Rect2(Vector2.ZERO, size), false)
		_draw_cloud(Vector2(42, 270), true, 0)
		_draw_cloud(Vector2(602, 376), false, 1)
		_draw_cloud(Vector2(72, size.y * 0.57), false, 0)
		_draw_cloud(Vector2(-72, size.y - 134), true, 2)
		_draw_cloud(Vector2(548, size.y - 196), true, 1)

	func _draw_cloud(origin: Vector2, large: bool, variant: int) -> void:
		var cloud_set := LARGE_CLOUDS if large else SMALL_CLOUDS
		var texture: Texture2D = cloud_set[variant % cloud_set.size()]
		draw_texture(texture, origin)


class BlobShadow:
	extends Control

	var squish := 1.0:
		set(value):
			squish = value
			queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _draw() -> void:
		var center := size / 2.0
		draw_set_transform(center, 0, Vector2(1, size.y / maxf(1, size.x) * squish))
		for layer in range(12, 0, -1):
			var radius := size.x * (0.25 + float(layer) * 0.018)
			draw_circle(Vector2.ZERO, radius, Color(0.16, 0.10, 0.20, 0.018), true, -1, true)
		draw_set_transform(Vector2.ZERO)


class PixelChevron:
	extends Control

	var icon_color := Color("#382b3d")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		var points := PackedVector2Array([center + Vector2(7, -13), center + Vector2(-7, 0), center + Vector2(7, 13)])
		draw_polyline(points, icon_color, 5.0, true)
		for point in points:
			draw_circle(point, 2.5, icon_color, true, -1, true)


class ResourceIcon:
	extends Control

	var icon_kind := "gem"

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _draw() -> void:
		if icon_kind == "coin":
			_draw_coin()
		else:
			_draw_gem()

	func _draw_gem() -> void:
		var outline := PackedVector2Array([
			Vector2(18, 1), Vector2(34, 10), Vector2(31, 27),
			Vector2(18, 39), Vector2(5, 27), Vector2(2, 10),
		])
		var fill := PackedVector2Array([
			Vector2(18, 6), Vector2(29, 12), Vector2(27, 24),
			Vector2(18, 33), Vector2(9, 24), Vector2(7, 12),
		])
		draw_colored_polygon(outline, Color("#2f2140"))
		draw_colored_polygon(fill, Color("#f45b9d"))
		draw_line(Vector2(7, 12), Vector2(29, 12), Color("#ffb2d1"), 3.0, true)
		draw_line(Vector2(18, 6), Vector2(18, 33), Color("#fff1c9"), 3.0, true)

	func _draw_coin() -> void:
		draw_circle(Vector2(19, 21), 18, Color("#382b3d"), true, -1, true)
		draw_circle(Vector2(19, 20), 15, Color("#e9aa46"), true, -1, true)
		draw_circle(Vector2(17, 18), 12, Color("#f8d783"), true, -1, true)
		draw_arc(Vector2(18, 20), 10, PI, TAU * 0.88, 32, Color("#fff1d2"), 2, true)
		draw_line(Vector2(19, 13), Vector2(19, 27), Color("#ad6f31"), 3, true)
		draw_line(Vector2(14, 20), Vector2(24, 20), Color("#ad6f31"), 3, true)


class PixelEgg:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	const EGG := preload("res://assets/art/comic/sun_egg.png")

	func _draw() -> void:
		draw_texture_rect(EGG, Rect2(Vector2.ZERO, size), false)


class ConfettiPiece:
	extends Control

	var velocity := Vector2.ZERO
	var spin := 0.0
	var lifetime := 1.35
	var piece_color := Color.WHITE

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		pivot_offset = size / 2.0
		queue_redraw()

	func _process(delta: float) -> void:
		position += velocity * delta
		velocity.y += 720.0 * delta
		rotation += spin * delta
		lifetime -= delta
		if lifetime < 0.28:
			modulate.a = maxf(0.0, lifetime / 0.28)
		if lifetime <= 0.0:
			queue_free()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#2f2140"))
		draw_rect(Rect2(3, 3, maxf(1.0, size.x - 6), maxf(1.0, size.y - 6)), piece_color)
