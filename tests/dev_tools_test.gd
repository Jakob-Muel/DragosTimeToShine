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

	BUILD_INFO.reset_for_tests()
	assert(BUILD_INFO.dev_tools_enabled() == OS.is_debug_build(), "Automatic mode follows the build type.")

	_test_unlock_gesture()
	await _test_version_label_toggle(scene, lab_label)
	BUILD_INFO.reset_for_tests()
	print("Dev tools test: valid")
	quit()


func _test_unlock_gesture() -> void:
	BUILD_INFO.reset_for_tests()
	var start := OS.is_debug_build()
	var taps: int = BUILD_INFO.UNLOCK_TAPS
	var gap: int = BUILD_INFO.UNLOCK_TAP_GAP_MS

	# Too slow: a pause longer than the gap restarts the count.
	var t := 1000
	for i in taps - 1:
		assert(not BUILD_INFO.register_unlock_tap(t), "Early taps never toggle.")
		t += gap - 100
	t += gap + 200
	assert(not BUILD_INFO.register_unlock_tap(t), "A slow tap restarts the gesture.")
	assert(BUILD_INFO.dev_tools_enabled() == start, "An unfinished gesture changes nothing.")

	# Fast enough: the last tap toggles and the choice beats the build default.
	t += 10000
	for i in taps - 1:
		assert(not BUILD_INFO.register_unlock_tap(t), "Taps before the last never toggle.")
		t += 100
	assert(BUILD_INFO.register_unlock_tap(t), "The last quick tap completes the gesture.")
	assert(BUILD_INFO.dev_tools_enabled() == not start, "The gesture flips dev tools.")

	# Doing it again switches back.
	t += 10000
	for i in taps:
		BUILD_INFO.register_unlock_tap(t)
		t += 100
	assert(BUILD_INFO.dev_tools_enabled() == start, "A second gesture switches back.")


func _test_version_label_toggle(scene: Control, lab_label: String) -> void:
	BUILD_INFO.reset_for_tests()
	BUILD_INFO.set_dev_tools_enabled(false)
	scene.call("_show_main_menu")
	await process_frame
	assert(_find_button(scene, lab_label) == null, "Dev tools off hides the Dragon Lab button.")
	var version := _find_named(scene, "VersionLabel") as Label
	assert(version != null, "The main menu has a version label.")
	assert(not version.text.contains("DEV"), "The DEV tag is hidden while dev tools are off.")

	for i in BUILD_INFO.UNLOCK_TAPS:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		version.gui_input.emit(click)
	await process_frame
	assert(BUILD_INFO.dev_tools_enabled(), "Tapping the version label turns dev tools on.")
	assert(_find_button(scene, lab_label) != null, "The menu rebuilds with the Dragon Lab button.")
	version = _find_named(scene, "VersionLabel") as Label
	assert(version.text.contains("DEV"), "The DEV tag shows while dev tools are on.")


func _find_named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child: Node in node.get_children():
		var found := _find_named(child, node_name)
		if found != null:
			return found
	return null


func _find_button(node: Node, label: String) -> Button:
	if node is Button and (node as Button).text == label:
		return node
	for child: Node in node.get_children():
		var found := _find_button(child, label)
		if found != null:
			return found
	return null
