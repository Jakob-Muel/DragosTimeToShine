extends Control

signal score_changed(score: int)
signal run_finished(score: int, completed: bool)

const DRAGON_TEXTURE := preload("res://assets/art/flight/flight_dragon.png")
const FLIGHT_PILLAR := preload("res://scripts/ui/flight_pillar.gd")
const LARGE_CLOUDS := [
	preload("res://assets/art/ui_redesign/clouds/large_wide.png"),
	preload("res://assets/art/ui_redesign/clouds/large_tall.png"),
	preload("res://assets/art/ui_redesign/clouds/large_wisp.png"),
]
const SMALL_CLOUDS := [
	preload("res://assets/art/ui_redesign/clouds/small_wide.png"),
	preload("res://assets/art/ui_redesign/clouds/small_tall.png"),
	preload("res://assets/art/ui_redesign/clouds/small_wisp.png"),
]
const LANDSCAPE := preload("res://assets/art/ui_redesign/flight_environment/landscape.png")
const DRAGON_SIZE := Vector2(156, 98)
const DRAGON_X := 105.0
const GRAVITY := 820.0
const FLAP_VELOCITY := -345.0
const OBSTACLE_SPEED := 235.0
const OBSTACLE_WIDTH := 118.0
const GAP_HEIGHT_START := 300.0
const GAP_HEIGHT_MIN := 130.0
const GAP_HEIGHT_DECREASE := 15.0
const GAP_HEIGHT_SCORE_INTERVAL := 5
const SPAWN_INTERVAL := 1.72
const MIN_PILLAR_HEIGHT := 210.0
const GAP_CENTER_DELTA_START := 200.0
const GAP_CENTER_DELTA_MAX := 500.0
const GAP_CENTER_DELTA_PER_POINT := 15.0
const GAP_CENTER_MIN_DELTA_START_SCORE := 10
const GAP_CENTER_MIN_DELTA_START := 75.0
const GAP_CENTER_MIN_DELTA_MAX := 150.0
const GAP_CENTER_MIN_DELTA_INCREASE := 15.0
const GAP_CENTER_MIN_DELTA_SCORE_INTERVAL := 5
const CLOUD_FAR_SPEED := 10.0
const CLOUD_NEAR_SPEED := 18.0
const LANDSCAPE_SPEED := 40.0

var dragon: TextureRect
var velocity_y := 0.0
var spawn_time := 0.8
var score := 0
var running := false
var finished := false
var obstacles: Array[Dictionary] = []
var random := RandomNumberGenerator.new()
var dragon_texture: Texture2D = DRAGON_TEXTURE
var last_gap_center := 0.0
var obstacle_serial := 0
var parallax_distance := 0.0
var cloud_far_offset := 0.0
var cloud_near_offset := 0.0
var landscape_offset := 0.0


func _ready() -> void:
	random.randomize()
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	dragon = TextureRect.new()
	dragon.texture = dragon_texture if dragon_texture != null else DRAGON_TEXTURE
	dragon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dragon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dragon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dragon.flip_h = true
	dragon.position = Vector2(DRAGON_X, size.y * 0.45)
	dragon.size = DRAGON_SIZE
	dragon.pivot_offset = DRAGON_SIZE / 2.0
	dragon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dragon.z_index = 20
	add_child(dragon)
	last_gap_center = dragon.position.y + DRAGON_SIZE.y * 0.5
	queue_redraw()


func _process(delta: float) -> void:
	if not finished:
		_advance_background(delta)
	if not running or finished:
		return
	velocity_y += GRAVITY * delta
	dragon.position.y += velocity_y * delta
	dragon.rotation = clampf(velocity_y / 760.0, -0.38, 0.72)
	spawn_time -= delta
	if spawn_time <= 0.0:
		spawn_time += SPAWN_INTERVAL
		_spawn_obstacle_pair()
	_move_obstacles(delta)
	if dragon.position.y < -8.0 or dragon.position.y + dragon.size.y > size.y + 8.0:
		_finish(false)
		return
	# The visible sprite has wide wings and a long tail. Keep the gameplay hitbox
	# around its body so near misses feel fair on a small touch screen.
	var dragon_hitbox := Rect2(
		dragon.position + Vector2(35, 25),
		dragon.size - Vector2(70, 50)
	)
	for obstacle in obstacles:
		var root := obstacle["root"] as Control
		var top_height := float(obstacle["top_height"])
		var gap_height := float(obstacle.get("gap_height", GAP_HEIGHT_START))
		var gap_bottom := top_height + gap_height
		# Keep a forgiving inner collision lane even though the new ruined caps
		# have a broader, clearer silhouette than the old needle-like peaks.
		var top_hitbox := Rect2(root.position + Vector2(30, 0), Vector2(OBSTACLE_WIDTH - 60, maxf(0.0, top_height - 24)))
		var bottom_hitbox := Rect2(
			root.position + Vector2(30, gap_bottom + 24),
			Vector2(OBSTACLE_WIDTH - 60, maxf(0.0, size.y - gap_bottom - 24))
		)
		if dragon_hitbox.intersects(top_hitbox) or dragon_hitbox.intersects(bottom_hitbox):
			_finish(false)
			return


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = (
		(event is InputEventScreenTouch and event.pressed)
		or (
			event is InputEventMouseButton
			and event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed
		)
	)
	if not pressed or finished:
		return
	if not running:
		running = true
		spawn_time = 0.7
	velocity_y = FLAP_VELOCITY
	accept_event()


func _move_obstacles(delta: float) -> void:
	for index in range(obstacles.size() - 1, -1, -1):
		var obstacle := obstacles[index]
		var root := obstacle["root"] as Control
		root.position.x -= OBSTACLE_SPEED * delta
		if not bool(obstacle["counted"]) and root.position.x + OBSTACLE_WIDTH < DRAGON_X:
			obstacle["counted"] = true
			obstacles[index] = obstacle
			score += 1
			score_changed.emit(score)
		if root.position.x + OBSTACLE_WIDTH < -20.0:
			root.queue_free()
			obstacles.remove_at(index)


func _advance_background(delta: float) -> void:
	parallax_distance += LANDSCAPE_SPEED * delta
	cloud_far_offset = fmod(cloud_far_offset + CLOUD_FAR_SPEED * delta, 360.0)
	cloud_near_offset = fmod(cloud_near_offset + CLOUD_NEAR_SPEED * delta, 520.0)
	landscape_offset = fmod(
		landscape_offset + LANDSCAPE_SPEED * delta,
		float(LANDSCAPE.get_width())
	)
	queue_redraw()


func _spawn_obstacle_pair() -> void:
	var gap_height := current_gap_height()
	var minimum_center := gap_height * 0.5 + MIN_PILLAR_HEIGHT
	var maximum_center := size.y - gap_height * 0.5 - MIN_PILLAR_HEIGHT
	if maximum_center < minimum_center:
		var middle := size.y * 0.5
		minimum_center = middle
		maximum_center = middle
	var gap_center := _choose_gap_center(
		minimum_center,
		maximum_center,
		current_gap_center_min_delta(),
		current_gap_center_delta()
	)
	last_gap_center = gap_center
	var top_height := gap_center - gap_height * 0.5
	var root := Control.new()
	root.position = Vector2(size.x + 20.0, 0.0)
	root.size = Vector2(OBSTACLE_WIDTH, size.y)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 10
	add_child(root)

	var top_spikes := _pillar(
		Vector2(OBSTACLE_WIDTH, top_height),
		false,
		obstacle_serial % 3
	)
	root.add_child(top_spikes)
	var gap_bottom := top_height + gap_height
	var bottom_spikes := _pillar(
		Vector2(OBSTACLE_WIDTH, size.y - gap_bottom),
		true,
		(obstacle_serial + 1) % 3
	)
	bottom_spikes.position.y = gap_bottom
	root.add_child(bottom_spikes)
	obstacle_serial += 1
	obstacles.append({
		"root": root,
		"top_height": top_height,
		"gap_center": gap_center,
		"gap_height": gap_height,
		"counted": false,
	})


func current_gap_center_delta() -> float:
	return minf(
		GAP_CENTER_DELTA_START + float(score) * GAP_CENTER_DELTA_PER_POINT,
		GAP_CENTER_DELTA_MAX
	)


func current_gap_center_min_delta() -> float:
	if score < GAP_CENTER_MIN_DELTA_START_SCORE:
		return 0.0
	var increase_steps := floori(
		float(score - GAP_CENTER_MIN_DELTA_START_SCORE)
		/ float(GAP_CENTER_MIN_DELTA_SCORE_INTERVAL)
	)
	return minf(
		GAP_CENTER_MIN_DELTA_START
		+ float(increase_steps) * GAP_CENTER_MIN_DELTA_INCREASE,
		GAP_CENTER_MIN_DELTA_MAX
	)


func _choose_gap_center(
	minimum_center: float,
	maximum_center: float,
	minimum_delta: float,
	maximum_delta: float
) -> float:
	var lower_start := maxf(minimum_center, last_gap_center - maximum_delta)
	var lower_end := minf(maximum_center, last_gap_center - minimum_delta)
	var upper_start := maxf(minimum_center, last_gap_center + minimum_delta)
	var upper_end := minf(maximum_center, last_gap_center + maximum_delta)
	var has_lower_range := lower_end >= lower_start
	var has_upper_range := upper_end >= upper_start

	if minimum_delta <= 0.0:
		var allowed_start := maxf(minimum_center, last_gap_center - maximum_delta)
		var allowed_end := minf(maximum_center, last_gap_center + maximum_delta)
		return random.randf_range(allowed_start, allowed_end)
	if has_lower_range and has_upper_range:
		return (
			random.randf_range(lower_start, lower_end)
			if random.randi_range(0, 1) == 0
			else random.randf_range(upper_start, upper_end)
		)
	if has_lower_range:
		return random.randf_range(lower_start, lower_end)
	if has_upper_range:
		return random.randf_range(upper_start, upper_end)

	# Extremely short viewports can make the requested minimum impossible.
	# Select the farthest valid edge instead of placing an opening off-screen.
	var distance_to_minimum := absf(minimum_center - last_gap_center)
	var distance_to_maximum := absf(maximum_center - last_gap_center)
	return minimum_center if distance_to_minimum >= distance_to_maximum else maximum_center


func current_gap_height() -> float:
	var decrease_steps := floori(
		float(score) / float(GAP_HEIGHT_SCORE_INTERVAL)
	)
	return maxf(
		GAP_HEIGHT_START - float(decrease_steps) * GAP_HEIGHT_DECREASE,
		GAP_HEIGHT_MIN
	)


func _pillar(pillar_size: Vector2, flip_vertical: bool, variant: int) -> Control:
	var pillar := FLIGHT_PILLAR.new() as FlightPillar
	pillar.size = pillar_size
	pillar.flip_vertical = flip_vertical
	pillar.variant = variant
	return pillar


func _finish(completed: bool) -> void:
	if finished:
		return
	finished = true
	running = false
	run_finished.emit.call_deferred(score, completed)


func debug_show_obstacle() -> void:
	if obstacles.is_empty():
		_spawn_obstacle_pair()
	var obstacle := obstacles[0]
	var root := obstacle["root"] as Control
	root.position.x = size.x * 0.67


func _draw() -> void:
	_draw_banded_sky()
	_draw_cloud_track(SMALL_CLOUDS, 110.0, cloud_far_offset, 360.0)
	_draw_cloud_track(LARGE_CLOUDS, 265.0, cloud_near_offset, 520.0)

	_draw_tiled_layer(LANDSCAPE, size.y - LANDSCAPE.get_height(), landscape_offset)


func _draw_banded_sky() -> void:
	var band_height := size.y / 5.0
	var colors := [
		Color("#4fb3d0"),
		Color("#78d6ed"),
		Color("#78d6ed"),
		Color("#a8e6f5"),
		Color("#dff3ef"),
	]
	for index in colors.size():
		draw_rect(Rect2(0, band_height * index, size.x, band_height + 1.0), colors[index])


func _draw_cloud_track(
	textures: Array,
	base_y: float,
	offset: float,
	spacing: float
) -> void:
	var shift := fposmod(-offset, spacing) - spacing
	var count := ceili(size.x / spacing) + 3
	for index in count:
		var texture: Texture2D = textures[index % textures.size()]
		var y_offset := float((index * 2 + 1) % 3) * 64.0
		draw_texture(texture, Vector2(shift + index * spacing, base_y + y_offset))


func _draw_tiled_layer(texture: Texture2D, y: float, offset: float) -> void:
	var tile_width := float(texture.get_width())
	var shift := fposmod(-offset, tile_width) - tile_width
	var count := ceili(size.x / tile_width) + 2
	for index in count:
		draw_texture(texture, Vector2(shift + index * tile_width, y))
