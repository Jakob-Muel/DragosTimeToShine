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
	draw_set_transform(center, 0, Vector2(1, 0.38))
	draw_circle(Vector2(0, 15), size.x * 0.43, UiTokens.INK, true, -1, true)
	draw_circle(Vector2.ZERO, size.x * 0.42, UiTokens.INK, true, -1, true)
	draw_circle(Vector2.ZERO, size.x * 0.39, Color("#a99ab6") if not occupied else UiTokens.GOLD, true, -1, true)
	draw_arc(Vector2.ZERO, size.x * 0.34, PI, TAU, 64, Color("#e5d8e3"), 5, true)
	draw_arc(Vector2.ZERO, size.x * 0.26, 0, TAU, 64, UiTokens.CREAM, 3, true)
	draw_set_transform(Vector2.ZERO)
