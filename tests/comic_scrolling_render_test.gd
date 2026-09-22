extends SceneTree

## Render real playfields immediately before/after their repeat boundaries.
## Run with a graphics device, not --headless. No save data is touched.
const FLIGHT := preload("res://scripts/ui/flight_game.gd")
const SHOOTER := preload("res://scripts/ui/flame_shooter_game.gd")
const RACE := preload("res://scripts/ui/flight_race_background.gd")
var viewport: SubViewport

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(720, 1200)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	_check_tile_edges("res://assets/art/comic/flame_minigame/ground.png", true)
	for tile: String in ["mountains", "landscape", "foreground"]:
		_check_tile_edges("res://assets/art/comic/ui_redesign/flight_environment/" + tile + ".png", false)
	var flight := FLIGHT.new()
	flight.size = viewport.size
	viewport.add_child(flight)
	flight.set_process(false)
	flight.dragon.hide()
	for boundary: Vector2 in [Vector2(360, 520), Vector2(1080, 1560)]:
		flight.cloud_far_offset = boundary.x - 0.1
		flight.cloud_near_offset = boundary.y - 0.1
		flight.landscape_offset = 1439.9
		flight.queue_redraw()
		var before := await _frame()
		flight.call("_advance_background", 0.02)
		var after := await _frame()
		_assert_continuity(before, after, "Flight clouds and hills at " + str(boundary))
	var before_motion := await _frame()
	flight.call("_advance_background", 1.0)
	assert(_difference(before_motion, await _frame()) > 0.001, "Parallax must visibly move.")
	flight.free()
	var race := RACE.new()
	race.size = viewport.size
	viewport.add_child(race)
	race.set_process(false)
	race.scroll_offset = 1439.9
	race.queue_redraw()
	var race_before := await _frame()
	race.call("_process", 0.002)
	_assert_continuity(race_before, await _frame(), "Race across the former global reset")
	race.free()
	var shooter := SHOOTER.new()
	shooter.size = viewport.size
	viewport.add_child(shooter)
	shooter.set_process(false)
	shooter.running = false
	shooter.dragon.hide()
	shooter.scroll_offset = SHOOTER.GROUND_TILE_HEIGHT - 0.1
	shooter.queue_redraw()
	var ground_before := await _frame()
	shooter.call("_process", 0.002)
	_assert_continuity(ground_before, await _frame(), "Vertical meadow wrap")
	shooter.scroll_offset = 0
	shooter.queue_redraw()
	var zero := await _frame()
	shooter.call("_process", SHOOTER.GROUND_TILE_HEIGHT / SHOOTER.GROUND_SCROLL_SPEED)
	assert(_difference(zero, await _frame()) < 0.00001, "One full meadow cycle must repeat exactly.")
	shooter.call("_process", 0.5)
	assert(_difference(zero, await _frame()) > 0.01, "Meadow landmarks must visibly travel downward.")
	print("Comic scrolling render test: valid")
	quit()

func _frame() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()

func _assert_continuity(before: Image, after: Image, description: String) -> void:
	var delta := _difference(before, after)
	print(description, ": mean pixel change ", delta)
	assert(delta < 0.002, description + " must not pop at the wrap boundary.")

func _difference(first: Image, second: Image) -> float:
	var total := 0.0
	var count := 0
	for y in range(0, first.get_height(), 3):
		for x in range(0, first.get_width(), 3):
			var a := first.get_pixel(x, y)
			var b := second.get_pixel(x, y)
			total += (absf(a.r-b.r) + absf(a.g-b.g) + absf(a.b-b.b)) / 3.0
			count += 1
	return total / count

func _check_tile_edges(asset: String, vertical: bool) -> void:
	var texture := load(asset) as Texture2D
	var art := texture.get_image()
	var length := art.get_width() if vertical else art.get_height()
	var total := 0.0
	for index in length:
		var a := art.get_pixel(index, 0) if vertical else art.get_pixel(0, index)
		var b := art.get_pixel(index, art.get_height()-1) if vertical else art.get_pixel(art.get_width()-1, index)
		# Compare premultiplied colors: RGB in transparent pixels is irrelevant.
		total += (absf(a.r*a.a-b.r*b.a) + absf(a.g*a.a-b.g*b.a) + absf(a.b*a.a-b.b*b.a) + absf(a.a-b.a)) / 4.0
	assert(total / length < 0.005, "Tile edges must meet without a seam: " + asset)
