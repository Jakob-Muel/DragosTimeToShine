class_name FlightPillar
extends Control

const NATURAL_PEAK_HEIGHT := 250.0

var flip_vertical := false
var variant := 0


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var peak_height := minf(size.y, NATURAL_PEAK_HEIGHT)

	var body_start := peak_height - 12.0 if flip_vertical else 0.0
	var body_end := size.y if flip_vertical else size.y - peak_height + 12.0
	var row_height := 34.0
	var row := 0
	var y := body_start
	var dark := Color("#352b38")
	var shadow_colors: Array[Color] = [
		Color("#4d3d43"),
		Color("#493b49"),
		Color("#57443e"),
	]
	var mid_colors: Array[Color] = [
		Color("#725b55"),
		Color("#66515a"),
		Color("#806457"),
	]
	var light_colors: Array[Color] = [
		Color("#a57d6e"),
		Color("#96717d"),
		Color("#ad856c"),
	]
	var shadow: Color = shadow_colors[variant % 3]
	var mid: Color = mid_colors[variant % 3]
	var light: Color = light_colors[variant % 3]

	while size.y > peak_height - 10.0 and y < body_end:
		var height := minf(row_height + 3.0, body_end - y)
		var inset := float(3 + ((row * 2 + variant) % 4) * 3)
		_draw_stone_row(
			Rect2(inset, y, size.x - inset * 2.0, height),
			row,
			dark,
			shadow,
			mid,
			light
		)

		if (row + variant) % 3 == 1:
			var crystal_x := inset + 15.0 + float((row * 23 + variant * 17) % 48)
			_draw_crystal_cluster(Vector2(crystal_x, y + 12.0), row % 2 == 0)
		if (row + variant) % 4 == 2:
			var chip_on_left := row % 2 == 0
			_draw_side_chip(
				Vector2(
					inset - 2.0 if chip_on_left else size.x - inset + 2.0,
					y + 9.0
				),
				chip_on_left,
				dark,
				mid
			)

		y += row_height
		row += 1

	_draw_peak(peak_height, dark, shadow, mid, light)


func _draw_peak(
	peak_height: float,
	dark: Color,
	shadow: Color,
	mid: Color,
	light: Color
) -> void:
	var outer_points := PackedVector2Array([
		Vector2(8, 0),
		Vector2(110, 0),
		Vector2(110, 15),
		Vector2(104, 15),
		Vector2(104, 35),
		Vector2(98, 35),
		Vector2(98, 58),
		Vector2(91, 58),
		Vector2(91, 82),
		Vector2(84, 82),
		Vector2(84, 108),
		Vector2(77, 108),
		Vector2(77, 137),
		Vector2(70, 137),
		Vector2(70, 169),
		Vector2(64, 169),
		Vector2(59, 250),
		Vector2(53, 169),
		Vector2(47, 169),
		Vector2(47, 137),
		Vector2(40, 137),
		Vector2(40, 108),
		Vector2(33, 108),
		Vector2(33, 82),
		Vector2(26, 82),
		Vector2(26, 58),
		Vector2(19, 58),
		Vector2(19, 35),
		Vector2(13, 35),
		Vector2(13, 15),
		Vector2(8, 15),
	])
	draw_colored_polygon(_map_peak_points(outer_points, peak_height), dark)

	var face_points := PackedVector2Array([
		Vector2(14, 6),
		Vector2(104, 6),
		Vector2(104, 18),
		Vector2(98, 18),
		Vector2(98, 39),
		Vector2(91, 39),
		Vector2(91, 62),
		Vector2(84, 62),
		Vector2(84, 87),
		Vector2(77, 87),
		Vector2(77, 114),
		Vector2(70, 114),
		Vector2(70, 144),
		Vector2(64, 144),
		Vector2(59, 229),
		Vector2(54, 144),
		Vector2(48, 144),
		Vector2(48, 114),
		Vector2(41, 114),
		Vector2(41, 87),
		Vector2(34, 87),
		Vector2(34, 62),
		Vector2(27, 62),
		Vector2(27, 39),
		Vector2(20, 39),
		Vector2(20, 18),
		Vector2(14, 18),
	])
	draw_colored_polygon(_map_peak_points(face_points, peak_height), mid)

	var highlight_facet := PackedVector2Array([
		Vector2(18, 10),
		Vector2(57, 10),
		Vector2(50, 42),
		Vector2(38, 72),
		Vector2(30, 52),
		Vector2(24, 28),
	])
	draw_colored_polygon(_map_peak_points(highlight_facet, peak_height), light)

	var shadow_facet := PackedVector2Array([
		Vector2(61, 8),
		Vector2(100, 8),
		Vector2(94, 42),
		Vector2(83, 75),
		Vector2(73, 118),
		Vector2(64, 169),
		Vector2(59, 221),
		Vector2(57, 88),
	])
	draw_colored_polygon(_map_peak_points(shadow_facet, peak_height), shadow)

	var center_facet := PackedVector2Array([
		Vector2(53, 20),
		Vector2(66, 17),
		Vector2(70, 52),
		Vector2(62, 91),
		Vector2(58, 154),
		Vector2(51, 104),
		Vector2(45, 68),
	])
	draw_colored_polygon(_map_peak_points(center_facet, peak_height), mid.lightened(0.10))

	_draw_peak_crack(
		[Vector2(32, 38), Vector2(47, 52), Vector2(42, 76), Vector2(54, 91)],
		peak_height,
		dark
	)
	_draw_peak_crack(
		[Vector2(84, 51), Vector2(70, 65), Vector2(74, 91), Vector2(64, 111)],
		peak_height,
		dark
	)
	_draw_peak_crystals(peak_height)


func _map_peak_points(points: PackedVector2Array, peak_height: float) -> PackedVector2Array:
	var mapped := PackedVector2Array()
	var scale_y := peak_height / NATURAL_PEAK_HEIGHT
	for point in points:
		var depth := point.y * scale_y
		var y := peak_height - depth if flip_vertical else size.y - peak_height + depth
		mapped.append(Vector2(point.x, y))
	return mapped


func _draw_peak_crack(
	points: Array[Vector2],
	peak_height: float,
	color: Color
) -> void:
	var mapped := _map_peak_points(PackedVector2Array(points), peak_height)
	for index in mapped.size() - 1:
		draw_line(mapped[index], mapped[index + 1], color, 3.0, false)


func _draw_peak_crystals(peak_height: float) -> void:
	var clusters: Array[PackedVector2Array] = [
		PackedVector2Array([
			Vector2(23, 73),
			Vector2(29, 59),
			Vector2(35, 73),
			Vector2(30, 86),
		]),
		PackedVector2Array([
			Vector2(78, 116),
			Vector2(83, 101),
			Vector2(89, 116),
			Vector2(84, 130),
		]),
		PackedVector2Array([
			Vector2(52, 143),
			Vector2(57, 128),
			Vector2(63, 143),
			Vector2(58, 158),
		]),
	]
	for index in clusters.size():
		var crystal := _map_peak_points(clusters[index], peak_height)
		draw_colored_polygon(crystal, Color("#9a3566"))
		var center := crystal[1].lerp(crystal[3], 0.48)
		draw_rect(Rect2(center - Vector2(2, 3), Vector2(4, 7)), Color("#ff9bc3"))


func _draw_stone_row(
	rect: Rect2,
	row: int,
	dark: Color,
	shadow: Color,
	mid: Color,
	light: Color
) -> void:
	var x := rect.position.x
	var y := rect.position.y
	var right := rect.end.x
	var bottom := rect.end.y

	if rect.size.y < 18.0:
		draw_rect(rect, dark)
		if rect.size.y > 8.0:
			draw_rect(rect.grow(-4.0), mid)
		return

	var outline := PackedVector2Array([
		Vector2(x + 5, y),
		Vector2(right - 8, y),
		Vector2(right - 8, y + 3),
		Vector2(right, y + 3),
		Vector2(right, bottom - 7),
		Vector2(right - 4, bottom - 7),
		Vector2(right - 4, bottom),
		Vector2(x + 8, bottom),
		Vector2(x + 8, bottom - 3),
		Vector2(x, bottom - 3),
		Vector2(x, y + 7),
		Vector2(x + 5, y + 7),
	])
	draw_colored_polygon(outline, dark)

	var face := PackedVector2Array([
		Vector2(x + 7, y + 4),
		Vector2(right - 11, y + 4),
		Vector2(right - 11, y + 7),
		Vector2(right - 5, y + 7),
		Vector2(right - 5, bottom - 10),
		Vector2(right - 9, bottom - 10),
		Vector2(right - 9, bottom - 5),
		Vector2(x + 11, bottom - 5),
		Vector2(x + 11, bottom - 8),
		Vector2(x + 5, bottom - 8),
		Vector2(x + 5, y + 10),
		Vector2(x + 7, y + 10),
	])
	draw_colored_polygon(face, mid)

	var split_x := x + rect.size.x * (0.40 + 0.08 * float((row + variant) % 3))
	var upper_facet := PackedVector2Array([
		Vector2(x + 8, y + 5),
		Vector2(split_x - 3, y + 5),
		Vector2(split_x - 10, y + 13),
		Vector2(x + 12, y + 15),
	])
	draw_colored_polygon(upper_facet, light)
	var lower_facet := PackedVector2Array([
		Vector2(split_x + 4, y + 8),
		Vector2(right - 7, y + 8),
		Vector2(right - 9, bottom - 7),
		Vector2(split_x + 10, bottom - 7),
	])
	draw_colored_polygon(lower_facet, shadow)

	# Broken L-shaped seams avoid the repeated brick-wall appearance.
	draw_rect(Rect2(split_x - 2, y + 7, 4, 10 + float(row % 3) * 3.0), dark)
	draw_rect(Rect2(split_x - 2, y + 15 + float(row % 3) * 3.0, 10, 4), dark)
	if row % 2 == 0:
		var crack_x := right - 28.0 - float((row + variant) % 3) * 6.0
		draw_rect(Rect2(crack_x, y + 10, 3, 8), dark)
		draw_rect(Rect2(crack_x - 6, y + 16, 8, 3), dark)
		draw_rect(Rect2(crack_x - 6, y + 18, 3, 7), dark)
	else:
		var crack_x := x + 22.0 + float(variant * 4)
		draw_rect(Rect2(crack_x, y + 15, 9, 3), dark)
		draw_rect(Rect2(crack_x + 7, y + 17, 3, 8), dark)


func _draw_crystal_cluster(origin: Vector2, lean_right: bool) -> void:
	var direction := 1.0 if lean_right else -1.0
	var crystal_dark := Color("#8e315f")
	var crystal_mid := Color("#d85b96")
	var crystal_light := Color("#ffacd0")
	var large := PackedVector2Array([
		origin + Vector2(0, 12),
		origin + Vector2(5 * direction, 0),
		origin + Vector2(10 * direction, 12),
		origin + Vector2(6 * direction, 19),
	])
	draw_colored_polygon(large, crystal_dark)
	var inner := PackedVector2Array([
		origin + Vector2(2 * direction, 11),
		origin + Vector2(5 * direction, 4),
		origin + Vector2(7 * direction, 12),
		origin + Vector2(5 * direction, 16),
	])
	draw_colored_polygon(inner, crystal_mid)
	draw_rect(
		Rect2(origin + Vector2(4 * direction - 1.0, 6), Vector2(3, 5)),
		crystal_light
	)
	draw_rect(
		Rect2(origin + Vector2(12 * direction - 2.0, 12), Vector2(5, 8)),
		crystal_mid
	)


func _draw_side_chip(
	origin: Vector2,
	on_left: bool,
	dark: Color,
	mid: Color
) -> void:
	var direction := -1.0 if on_left else 1.0
	var chip := PackedVector2Array([
		origin,
		origin + Vector2(9 * direction, 4),
		origin + Vector2(11 * direction, 13),
		origin + Vector2(3 * direction, 17),
	])
	draw_colored_polygon(chip, dark)
	draw_rect(
		Rect2(origin + Vector2(minf(0.0, 5.0 * direction), 5), Vector2(6, 7)),
		mid
	)
