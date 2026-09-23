class_name FusionDragonCard
extends Panel

signal dragon_tapped(dragon_id: String)

var dragon_id := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_DRAG


func _get_drag_data(_at_position: Vector2) -> Variant:
	if dragon_id.is_empty():
		return null
	var preview := duplicate() as Control
	if preview != null:
		preview.modulate.a = 0.88
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_drag_preview(preview)
	return {"dragon_id": dragon_id}


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			dragon_tapped.emit(dragon_id)
	elif event is InputEventScreenTouch and not event.pressed:
		dragon_tapped.emit(dragon_id)
