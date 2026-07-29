extends RefCounted

## Small code-drawn art controls used by the prototype screens.
## Keeping them here prevents presentation details from obscuring screen flow.


class PixelSky:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#75d8f2"))
		draw_rect(Rect2(0, size.y * 0.69, size.x, size.y * 0.31), Color("#b7e888"))
		draw_rect(Rect2(0, size.y * 0.69, size.x, 8), Color("#2f2140"))
		_draw_cloud(Vector2(52, 172), 1.0)
		_draw_cloud(Vector2(485, 260), 0.8)
		_draw_cloud(Vector2(115, 510), 0.55)
		for x in range(24, int(size.x), 64):
			var y := int(size.y * 0.73) + (x * 17) % 205
			draw_rect(Rect2(x, y, 8, 18), Color("#65bb65"))
			draw_rect(Rect2(x - 4, y + 7, 4, 5), Color("#65bb65"))
			draw_rect(Rect2(x + 8, y + 4, 4, 5), Color("#65bb65"))

	func _draw_cloud(origin: Vector2, scale_factor: float) -> void:
		var blocks := [
			Rect2(30, 0, 90, 32),
			Rect2(0, 28, 166, 42),
			Rect2(22, 62, 120, 18),
		]
		for block in blocks:
			var scaled := Rect2(origin + block.position * scale_factor, block.size * scale_factor)
			draw_rect(scaled, Color("#fff1c9"))
			draw_rect(Rect2(scaled.position + Vector2(0, scaled.size.y - 6), Vector2(scaled.size.x, 6)), Color("#efcf9c"))


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


class BerryPickup:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		pivot_offset = size / 2.0
		queue_redraw()

	func _draw() -> void:
		var pixel := 6.0
		var berry := [
			Vector2i(3, 2), Vector2i(4, 2),
			Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3),
			Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4),
			Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5),
			Vector2i(2, 6), Vector2i(3, 6), Vector2i(4, 6), Vector2i(5, 6),
			Vector2i(3, 7), Vector2i(4, 7),
		]
		for cell in berry:
			draw_rect(Rect2(Vector2(cell) * pixel + Vector2(7, 5), Vector2(pixel, pixel)), Color("#e63e78"))
		draw_rect(Rect2(25, 11, 6, 12), Color("#49334f"))
		draw_rect(Rect2(31, 5, 12, 6), Color("#49a85b"))
		draw_rect(Rect2(37, 11, 12, 6), Color("#49a85b"))
		draw_rect(Rect2(19, 29, 6, 6), Color("#ff8cba"))
		draw_rect(Rect2(0, 54, 62, 7), Color(0.16, 0.10, 0.20, 0.22))


class PixelComb:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		pivot_offset = size / 2.0
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(5, 31, 55, 22), Color("#2f2140"))
		draw_rect(Rect2(9, 35, 51, 14), Color("#fff1c9"))
		draw_rect(Rect2(54, 18, 34, 18), Color("#2f2140"))
		draw_rect(Rect2(58, 22, 26, 10), Color("#f45b9d"))
		for tooth_x in range(58, 86, 7):
			draw_rect(Rect2(tooth_x, 32, 6, 30), Color("#2f2140"))
			draw_rect(Rect2(tooth_x + 1, 32, 4, 25), Color("#f45b9d"))
		draw_rect(Rect2(13, 38, 8, 5), Color("#ffffff"))


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


class PixelStar:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		pivot_offset = size / 2.0
		queue_redraw()

	func _draw() -> void:
		var center := size / 2.0
		var outer := _star_points(center, minf(size.x, size.y) * 0.48)
		var inner := _star_points(center, minf(size.x, size.y) * 0.35)
		draw_colored_polygon(outer, Color("#2f2140"))
		draw_colored_polygon(inner, Color("#ffc857"))
		draw_circle(center + Vector2(-8, -9), 4.0, Color("#fff1c9"))

	func _star_points(center: Vector2, radius: float) -> PackedVector2Array:
		var points := PackedVector2Array()
		for index in 10:
			var point_radius := radius if index % 2 == 0 else radius * 0.45
			var angle := -PI / 2.0 + float(index) * PI / 5.0
			points.append(center + Vector2(cos(angle), sin(angle)) * point_radius)
		return points


class PixelScore:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		pivot_offset = size / 2.0
		queue_redraw()

	func _draw() -> void:
		_draw_five(Vector2(20, 5))
		for block_index in 4:
			draw_rect(Rect2(101 - block_index * 9, 12 + block_index * 13, 10, 14), Color("#2f2140"))
		_draw_five(Vector2(144, 5))

	func _draw_five(origin: Vector2) -> void:
		var thickness := 10.0
		var digit_width := 50.0
		var digit_height := 64.0
		draw_rect(Rect2(origin, Vector2(digit_width, thickness)), Color("#2f2140"))
		draw_rect(Rect2(origin, Vector2(thickness, digit_height * 0.52)), Color("#2f2140"))
		draw_rect(Rect2(origin + Vector2(0, 27), Vector2(digit_width, thickness)), Color("#2f2140"))
		draw_rect(Rect2(origin + Vector2(digit_width - thickness, 27), Vector2(thickness, digit_height - 27)), Color("#2f2140"))
		draw_rect(Rect2(origin + Vector2(0, digit_height - thickness), Vector2(digit_width, thickness)), Color("#2f2140"))
		draw_rect(Rect2(origin + Vector2(10, 10), Vector2(18, 5)), Color("#f45b9d"))


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


class AccessoryArt:
	extends Control

	var item_kind := ""

	func _init(kind: String = "") -> void:
		item_kind = kind

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		pivot_offset = size / 2.0
		queue_redraw()

	func _draw() -> void:
		match item_kind:
			"hat":
				_rect(8, 63, 84, 18, Color("#2f2140"))
				_rect(14, 67, 72, 10, Color("#f45b9d"))
				_rect(24, 14, 52, 56, Color("#2f2140"))
				_rect(30, 20, 40, 42, Color("#fff1c9"))
				_rect(30, 50, 40, 12, Color("#f45b9d"))
			"sword":
				_poly([Vector2(43, 4), Vector2(59, 4), Vector2(59, 62), Vector2(51, 78), Vector2(43, 62)], Color("#2f2140"))
				_poly([Vector2(47, 10), Vector2(55, 10), Vector2(55, 60), Vector2(51, 69), Vector2(47, 60)], Color("#e9f6ff"))
				_rect(27, 64, 48, 12, Color("#2f2140"))
				_rect(33, 67, 36, 6, Color("#ffc857"))
				_rect(44, 74, 14, 22, Color("#2f2140"))
				_rect(48, 76, 6, 17, Color("#b86f43"))
			"shield":
				_poly([Vector2(12, 12), Vector2(88, 12), Vector2(84, 65), Vector2(50, 94), Vector2(16, 65)], Color("#2f2140"))
				_poly([Vector2(20, 20), Vector2(80, 20), Vector2(76, 61), Vector2(50, 84), Vector2(24, 61)], Color("#ffc857"))
				_rect(44, 29, 12, 44, Color("#fff1c9"))
				_rect(30, 43, 40, 12, Color("#fff1c9"))
			"bowtie":
				_poly([Vector2(7, 24), Vector2(43, 42), Vector2(43, 62), Vector2(7, 80)], Color("#2f2140"))
				_poly([Vector2(93, 24), Vector2(57, 42), Vector2(57, 62), Vector2(93, 80)], Color("#2f2140"))
				_poly([Vector2(14, 34), Vector2(41, 47), Vector2(41, 57), Vector2(14, 70)], Color("#f45b9d"))
				_poly([Vector2(86, 34), Vector2(59, 47), Vector2(59, 57), Vector2(86, 70)], Color("#f45b9d"))
				_rect(40, 39, 20, 28, Color("#2f2140"))
				_rect(45, 44, 10, 18, Color("#fff1c9"))
			"tie":
				_poly([Vector2(36, 8), Vector2(64, 8), Vector2(69, 28), Vector2(50, 41), Vector2(31, 28)], Color("#2f2140"))
				_poly([Vector2(40, 13), Vector2(60, 13), Vector2(63, 25), Vector2(50, 34), Vector2(37, 25)], Color("#f45b9d"))
				_poly([Vector2(42, 35), Vector2(58, 35), Vector2(70, 82), Vector2(50, 96), Vector2(30, 82)], Color("#2f2140"))
				_poly([Vector2(46, 42), Vector2(54, 42), Vector2(63, 78), Vector2(50, 87), Vector2(37, 78)], Color("#f45b9d"))

	func _rect(x: float, y: float, width: float, height: float, color: Color) -> void:
		draw_rect(Rect2(x * size.x / 100.0, y * size.y / 100.0, width * size.x / 100.0, height * size.y / 100.0), color)

	func _poly(source_points: Array[Vector2], color: Color) -> void:
		var points := PackedVector2Array()
		for point in source_points:
			points.append(Vector2(point.x * size.x / 100.0, point.y * size.y / 100.0))
		draw_colored_polygon(points, color)
