extends RefCounted

## Small code-drawn art controls used by the prototype screens.
## Keeping them here prevents presentation details from obscuring screen flow.


class PixelSky:
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

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		queue_redraw()

	func _draw() -> void:
		# Deliberately visible color bands and stepped clouds keep utility
		# screens in the same pixel-art world as the islands.
		var band_count := 12
		var band_height := size.y / float(band_count)
		var sky_top := Color("#75d4ec")
		var sky_bottom := Color("#b9e8e7")
		for band in band_count:
			var amount := float(band) / float(band_count - 1)
			draw_rect(
				Rect2(0, band * band_height, size.x, band_height + 1.0),
				sky_top.lerp(sky_bottom, amount)
			)

		_draw_cloud(Vector2(42, 225), true, 0)
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
		var points := PackedVector2Array()
		var center := size / 2.0
		for index in 32:
			var angle := TAU * float(index) / 32.0
			points.append(center + Vector2(cos(angle) * size.x * 0.46, sin(angle) * size.y * 0.38 * squish))
		draw_colored_polygon(points, Color(0.16, 0.10, 0.20, 0.28))


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
		var pixel := 5.0
		var cells := [
			Vector2i(3, 0),
			Vector2i(2, 1), Vector2i(3, 1),
			Vector2i(1, 2), Vector2i(2, 2),
			Vector2i(0, 3), Vector2i(1, 3),
			Vector2i(1, 4), Vector2i(2, 4),
			Vector2i(2, 5), Vector2i(3, 5),
			Vector2i(3, 6),
		]
		var icon_size := Vector2(4.0 * pixel, 7.0 * pixel)
		var origin := ((size - icon_size) * 0.5).floor()
		for cell in cells:
			draw_rect(Rect2(origin + Vector2(cell) * pixel, Vector2(pixel, pixel)), icon_color)


class PixelGear:
	extends Control

	var icon_color := Color("#382b3d")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		var pixel := 4.0
		var rows := [
			"..##.##..",
			".#######.",
			"###...###",
			"###...###",
			".##...##.",
			"###...###",
			"###...###",
			".#######.",
			"..##.##..",
		]
		var icon_size := Vector2(9.0 * pixel, 9.0 * pixel)
		var origin := ((size - icon_size) * 0.5).floor()
		for y in rows.size():
			var row: String = rows[y]
			for x in row.length():
				if row[x] == "#":
					draw_rect(
						Rect2(origin + Vector2(x, y) * pixel, Vector2(pixel, pixel)),
						icon_color
					)


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
		draw_line(Vector2(7, 12), Vector2(29, 12), Color("#ffb2d1"), 3.0)
		draw_line(Vector2(18, 6), Vector2(18, 33), Color("#fff1c9"), 3.0)

	func _draw_coin() -> void:
		var outline := PackedVector2Array([
			Vector2(10, 2), Vector2(28, 2), Vector2(36, 10), Vector2(36, 30),
			Vector2(28, 38), Vector2(10, 38), Vector2(2, 30), Vector2(2, 10),
		])
		var fill := PackedVector2Array([
			Vector2(12, 7), Vector2(26, 7), Vector2(31, 12), Vector2(31, 28),
			Vector2(26, 33), Vector2(12, 33), Vector2(7, 28), Vector2(7, 12),
		])
		draw_colored_polygon(outline, Color("#2f2140"))
		draw_colored_polygon(fill, Color("#ffc857"))
		draw_rect(Rect2(15, 11, 8, 16), Color("#fff1c9"))
		draw_rect(Rect2(11, 15, 16, 8), Color("#fff1c9"))


class PixelEgg:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _draw() -> void:
		var outline := PackedVector2Array([
			Vector2(size.x * 0.50, size.y * 0.03), Vector2(size.x * 0.72, size.y * 0.12),
			Vector2(size.x * 0.88, size.y * 0.34), Vector2(size.x * 0.94, size.y * 0.64),
			Vector2(size.x * 0.82, size.y * 0.88), Vector2(size.x * 0.50, size.y * 0.98),
			Vector2(size.x * 0.18, size.y * 0.88), Vector2(size.x * 0.06, size.y * 0.64),
			Vector2(size.x * 0.12, size.y * 0.34), Vector2(size.x * 0.28, size.y * 0.12),
		])
		var fill := PackedVector2Array()
		var center := size * 0.5
		for point in outline:
			fill.append(center + (point - center) * 0.90)
		draw_colored_polygon(outline, Color("#2f2140"))
		draw_colored_polygon(fill, Color("#fff1c9"))
		draw_circle(Vector2(size.x * 0.36, size.y * 0.43), size.x * 0.09, Color("#f45b9d"))
		draw_circle(Vector2(size.x * 0.66, size.y * 0.62), size.x * 0.11, Color("#ffc857"))
		draw_circle(Vector2(size.x * 0.55, size.y * 0.27), size.x * 0.06, Color("#8ed5aa"))


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
