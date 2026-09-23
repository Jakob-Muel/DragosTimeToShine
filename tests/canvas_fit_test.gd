extends SceneTree

## The game canvas fits phones by width and wider windows (tablets, foldables, desktop
## browsers) by height, centered, so no screen is ever cut off at the bottom.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var canvas := GameCanvas.new()
	root.add_child(canvas)

	# Phones: full width, logical height follows the aspect ratio, no side margins.
	for phone: Vector2 in [Vector2(750, 1334), Vector2(1179, 2556), Vector2(1080, 2160), Vector2(1080, 2400)]:
		canvas.fit_to(phone)
		assert(is_equal_approx(canvas.scale.x, phone.x / 720.0), "Phones fit by width (%s)." % phone)
		assert(canvas.position == Vector2.ZERO, "Phones have no side margins (%s)." % phone)
		assert(canvas.logical_size.y >= GameCanvas.MIN_DESIGN_HEIGHT, "Phone canvas is tall enough (%s)." % phone)
		assert(not canvas.is_side_fitted(phone), "Phones are not side-fitted (%s)." % phone)

	# Tablets, foldables and desktop windows: fit by height, centered, never taller than the window.
	for wide: Vector2 in [Vector2(1536, 2048), Vector2(1600, 900), Vector2(2560, 1440), Vector2(1768, 2208), Vector2(900, 900)]:
		canvas.fit_to(wide)
		assert(is_equal_approx(canvas.logical_size.y, GameCanvas.MIN_DESIGN_HEIGHT), "Wide windows use the minimum height (%s)." % wide)
		assert(is_equal_approx(canvas.logical_size.y * canvas.scale.y, wide.y), "The whole canvas height is visible (%s)." % wide)
		var drawn_width := GameCanvas.DESIGN_WIDTH * canvas.scale.x
		assert(drawn_width <= wide.x + 0.5, "The canvas fits horizontally (%s)." % wide)
		assert(is_equal_approx(canvas.position.x * 2.0 + drawn_width, wide.x), "The canvas is centered (%s)." % wide)
		assert(canvas.is_side_fitted(wide), "Wide windows are side-fitted (%s)." % wide)
		assert(canvas.clip_contents, "Side-fitted canvases clip decorations.")

	# Safe-area conversion matches the active fit.
	assert(is_equal_approx(GameCanvas.logical_per_pixel(Vector2(1179, 2556)), 720.0 / 1179.0), "Phone insets scale by width.")
	assert(is_equal_approx(GameCanvas.logical_per_pixel(Vector2(1536, 2048)), 1280.0 / 2048.0), "Tablet insets scale by height.")

	# The real app shell uses the same rule.
	var scene: Control = load("res://main.tscn").instantiate()
	root.get_node("GameState").reset_for_tests()
	root.add_child(scene)
	await process_frame
	scene.size = Vector2(1600, 900)
	scene.call("_fit_design_canvas")
	assert(is_equal_approx(scene.get("canvas_size").y, GameCanvas.MIN_DESIGN_HEIGHT), "main.gd reports the fitted canvas size.")

	print("Canvas fit test: valid")
	quit()
