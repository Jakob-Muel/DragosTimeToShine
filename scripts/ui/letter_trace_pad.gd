class_name LetterTracePad
extends Control

signal letter_completed(letter: String)

const TRACE_RADIUS := 40.0
const REQUIRED_COVERAGE := 0.72
const GUIDE_OUTLINE := Color(0.18, 0.13, 0.25, 0.28)
const GUIDE_FILL := Color(1.0, 0.95, 0.79, 0.72)
const TRACE_OUTLINE := Color("#2f2140")
const TRACE_COLOR := Color("#ffc857")

var target_letter := "F"
var guide_strokes: Array[PackedVector2Array] = []
var guide_samples: Array[Vector2] = []
var covered_samples: Array[bool] = []
var drawn_paths: Array[PackedVector2Array] = []
var active_path := PackedVector2Array()
var tracing := false
var completed := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	queue_redraw()


func set_letter(letter: String) -> void:
	target_letter = letter.to_upper()
	guide_strokes = _letter_strokes(target_letter)
	drawn_paths.clear()
	active_path = PackedVector2Array()
	tracing = false
	completed = false
	_rebuild_samples()
	queue_redraw()


func coverage() -> float:
	if covered_samples.is_empty():
		return 0.0
	var covered_count := 0
	for value: bool in covered_samples:
		if value:
			covered_count += 1
	return float(covered_count) / float(covered_samples.size())


func _gui_input(event: InputEvent) -> void:
	if completed:
		return
	if event is InputEventScreenTouch:
		_handle_pointer(event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_extend_trace(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer(event.position, event.pressed)
	elif event is InputEventMouseMotion and tracing:
		_extend_trace(event.position)


func _handle_pointer(at_position: Vector2, pressed: bool) -> void:
	if pressed:
		tracing = true
		active_path = PackedVector2Array([at_position])
		_mark_coverage(at_position, at_position)
		queue_redraw()
		return
	if not tracing:
		return
	tracing = false
	if not active_path.is_empty():
		drawn_paths.append(active_path)
	active_path = PackedVector2Array()
	queue_redraw()
	if coverage() >= REQUIRED_COVERAGE:
		completed = true
		call_deferred("_emit_completed")


func _extend_trace(at_position: Vector2) -> void:
	if not tracing:
		return
	var previous := active_path[-1] if not active_path.is_empty() else at_position
	active_path.append(at_position)
	_mark_coverage(previous, at_position)
	queue_redraw()


func _mark_coverage(from: Vector2, to: Vector2) -> void:
	for index in guide_samples.size():
		if covered_samples[index]:
			continue
		var closest := Geometry2D.get_closest_point_to_segment(guide_samples[index], from, to)
		if guide_samples[index].distance_to(closest) <= TRACE_RADIUS:
			covered_samples[index] = true


func _rebuild_samples() -> void:
	guide_samples.clear()
	for stroke: PackedVector2Array in guide_strokes:
		if stroke.size() == 1:
			guide_samples.append(stroke[0])
			continue
		for index in stroke.size() - 1:
			var start := stroke[index]
			var finish := stroke[index + 1]
			var segment_count := maxi(1, ceili(start.distance_to(finish) / 18.0))
			for segment in segment_count:
				guide_samples.append(start.lerp(finish, float(segment) / float(segment_count)))
			guide_samples.append(finish)
	covered_samples.clear()
	for _sample in guide_samples:
		covered_samples.append(false)


func _letter_strokes(letter: String) -> Array[PackedVector2Array]:
	match letter:
		"F":
			return [
				_points([Vector2(0.28, 0.16), Vector2(0.28, 0.84)]),
				_points([Vector2(0.28, 0.16), Vector2(0.75, 0.16)]),
				_points([Vector2(0.28, 0.48), Vector2(0.66, 0.48)]),
			]
		"U":
			return [_points([
				Vector2(0.25, 0.18), Vector2(0.25, 0.62), Vector2(0.28, 0.74),
				Vector2(0.38, 0.82), Vector2(0.50, 0.85), Vector2(0.62, 0.82),
				Vector2(0.72, 0.74), Vector2(0.75, 0.62), Vector2(0.75, 0.18),
			])]
		"S":
			return [_points([
				Vector2(0.74, 0.24), Vector2(0.65, 0.17), Vector2(0.48, 0.15),
				Vector2(0.34, 0.19), Vector2(0.26, 0.29), Vector2(0.29, 0.40),
				Vector2(0.40, 0.47), Vector2(0.60, 0.52), Vector2(0.71, 0.61),
				Vector2(0.74, 0.72), Vector2(0.66, 0.81), Vector2(0.50, 0.85),
				Vector2(0.35, 0.82), Vector2(0.25, 0.75),
			])]
		"I":
			return [
				_points([Vector2(0.31, 0.16), Vector2(0.69, 0.16)]),
				_points([Vector2(0.50, 0.16), Vector2(0.50, 0.84)]),
				_points([Vector2(0.31, 0.84), Vector2(0.69, 0.84)]),
			]
		"O":
			return [_points([
				Vector2(0.50, 0.14), Vector2(0.36, 0.17), Vector2(0.27, 0.27),
				Vector2(0.23, 0.43), Vector2(0.23, 0.60), Vector2(0.28, 0.75),
				Vector2(0.38, 0.84), Vector2(0.50, 0.87), Vector2(0.62, 0.84),
				Vector2(0.72, 0.75), Vector2(0.77, 0.60), Vector2(0.77, 0.43),
				Vector2(0.73, 0.27), Vector2(0.64, 0.17), Vector2(0.50, 0.14),
			])]
		"N":
			return [
				_points([Vector2(0.25, 0.84), Vector2(0.25, 0.16)]),
				_points([Vector2(0.25, 0.16), Vector2(0.75, 0.84)]),
				_points([Vector2(0.75, 0.84), Vector2(0.75, 0.16)]),
			]
	return []


func _points(normalized_points: Array[Vector2]) -> PackedVector2Array:
	var result := PackedVector2Array()
	var margin := 58.0
	var drawing_size := size - Vector2.ONE * margin * 2.0
	for point: Vector2 in normalized_points:
		result.append(Vector2(margin, margin) + point * drawing_size)
	return result


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#fff8e8"))
	draw_rect(Rect2(Vector2.ZERO, size), TRACE_OUTLINE, false, 6.0)
	for stroke: PackedVector2Array in guide_strokes:
		if stroke.size() < 2:
			continue
		draw_polyline(stroke, GUIDE_OUTLINE, 34.0, true)
		draw_polyline(stroke, GUIDE_FILL, 20.0, true)
	for index in guide_samples.size():
		if covered_samples[index]:
			draw_circle(guide_samples[index], 5.0, Color("#68c783"))
	for path: PackedVector2Array in drawn_paths:
		_draw_trace_path(path)
	_draw_trace_path(active_path)


func _draw_trace_path(path: PackedVector2Array) -> void:
	if path.is_empty():
		return
	if path.size() == 1:
		draw_circle(path[0], 10.0, TRACE_COLOR)
		return
	draw_polyline(path, TRACE_OUTLINE, 24.0, true)
	draw_polyline(path, TRACE_COLOR, 14.0, true)


func _emit_completed() -> void:
	letter_completed.emit(target_letter)


func debug_complete() -> void:
	for index in covered_samples.size():
		covered_samples[index] = true
	completed = true
	queue_redraw()
	call_deferred("_emit_completed")
