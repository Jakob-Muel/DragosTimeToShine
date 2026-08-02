class_name FusionStone
extends Control

signal dragon_dropped(slot_index: int, dragon_id: String)

var slot_index := 0
var occupied := false:
	set(value):
		occupied = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and not String(data.get("dragon_id", "")).is_empty()


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	dragon_dropped.emit(slot_index, String(data.get("dragon_id", "")))


func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.72)
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for index in 12:
		var angle := TAU * float(index) / 12.0
		var wobble := 1.0 if index % 2 == 0 else 0.9
		outer.append(center + Vector2(cos(angle) * size.x * 0.43 * wobble, sin(angle) * size.y * 0.20))
		inner.append(center + Vector2(cos(angle) * size.x * 0.37 * wobble, sin(angle) * size.y * 0.14))
	draw_colored_polygon(outer, Color("#2f2140"))
	draw_colored_polygon(inner, Color("#7d6a78") if not occupied else Color("#ffc857"))
	draw_arc(center, size.x * 0.25, 0.0, TAU, 24, Color("#fff1c9"), 5.0)
