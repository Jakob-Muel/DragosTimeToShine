extends SceneTree

## Developer tools (Dragon Lab) must be hidden and unreachable in release builds.

const BUILD_INFO := preload("res://scripts/build_info.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.reset_for_tests()
	var scene: Control = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var lab_label: String = root.get_node("Localization").text("NAV_DRAGON_LAB")

	BUILD_INFO.dev_tools_override = 0
	scene.call("_show_main_menu")
	await process_frame
	assert(_find_button(scene, lab_label) == null, "Release builds must not show the Dragon Lab button.")
	scene.call("_show_dragon_lab")
	assert(scene.get("current_screen") == "main", "Release builds must refuse the Dragon Lab route.")

	BUILD_INFO.dev_tools_override = 1
	scene.call("_show_main_menu")
	await process_frame
	assert(_find_button(scene, lab_label) != null, "Debug builds show the Dragon Lab button.")
	scene.call("_show_dragon_lab")
	assert(scene.get("current_screen") == "dragon_lab", "Debug builds open the Dragon Lab.")

	BUILD_INFO.dev_tools_override = -1
	assert(BUILD_INFO.dev_tools_enabled() == OS.is_debug_build(), "Automatic mode follows the build type.")
	print("Dev tools test: valid")
	quit()


func _find_button(node: Node, label: String) -> Button:
	if node is Button and (node as Button).text == label:
		return node
	for child: Node in node.get_children():
		var found := _find_button(child, label)
		if found != null:
			return found
	return null
