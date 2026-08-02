class_name ScreenRouter
extends Node

signal navigation_requested(route: String, params: Dictionary)

var host: Control
var active_screen: GameScreen
var current_route := ""


func configure(screen_host: Control) -> void:
	host = screen_host


func show_scene(
	route: String,
	scene: PackedScene,
	context: Dictionary
) -> GameScreen:
	clear()
	if host == null or scene == null:
		return null
	var screen := scene.instantiate() as GameScreen
	if screen == null:
		push_error("Route '%s' does not instantiate a GameScreen." % route)
		return null
	current_route = route
	active_screen = screen
	screen.configure(context)
	screen.navigation_requested.connect(_forward_navigation)
	host.add_child(screen)
	screen.build()
	return screen


func clear() -> void:
	current_route = ""
	if not is_instance_valid(active_screen):
		active_screen = null
		return
	if active_screen.get_parent() != null:
		active_screen.get_parent().remove_child(active_screen)
	active_screen.queue_free()
	active_screen = null


func _forward_navigation(route: String, params: Dictionary) -> void:
	navigation_requested.emit(route, params)
