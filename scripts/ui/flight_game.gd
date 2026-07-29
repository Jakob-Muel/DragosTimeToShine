extends Control

signal score_changed(score: int)
signal run_finished(score: int, completed: bool)

const DRAGON_TEXTURE := preload("res://assets/art/flight/flight_dragon.png")
const SPIKE_TEXTURE := preload("res://assets/art/flight/rock_spikes_game.png")
const DRAGON_SIZE := Vector2(126, 80)
const DRAGON_X := 105.0
const GRAVITY := 820.0
const FLAP_VELOCITY := -345.0
const OBSTACLE_SPEED := 235.0
const OBSTACLE_WIDTH := 118.0
const GAP_HEIGHT := 270.0
const SPAWN_INTERVAL := 1.72

var dragon: TextureRect
var velocity_y := 0.0
var spawn_time := 0.8
var score := 0
var running := false
var finished := false
var obstacles: Array[Dictionary] = []
var random := RandomNumberGenerator.new()


func _ready() -> void:
	random.randomize()
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	dragon = TextureRect.new()
	dragon.texture = DRAGON_TEXTURE
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
	queue_redraw()


func _process(delta: float) -> void:
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
	var dragon_hitbox := Rect2(dragon.position + Vector2(25, 18), dragon.size - Vector2(50, 36))
	for obstacle in obstacles:
		var root := obstacle["root"] as Control
		var top_height := float(obstacle["top_height"])
		var gap_bottom := top_height + GAP_HEIGHT
		# The rock art tapers sharply toward the gap, so a narrow central hitbox
		# avoids collisions with transparent corners and slightly grazed edges.
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


func _spawn_obstacle_pair() -> void:
	var minimum_center := GAP_HEIGHT * 0.5 + 100.0
	var maximum_center := size.y - GAP_HEIGHT * 0.5 - 120.0
	var gap_center := random.randf_range(minimum_center, maximum_center)
	var top_height := gap_center - GAP_HEIGHT * 0.5
	var root := Control.new()
	root.position = Vector2(size.x + 20.0, 0.0)
	root.size = Vector2(OBSTACLE_WIDTH, size.y)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 10
	add_child(root)

	var top_spikes := _spike_rect(Vector2(OBSTACLE_WIDTH, top_height), false)
	root.add_child(top_spikes)
	var gap_bottom := top_height + GAP_HEIGHT
	var bottom_spikes := _spike_rect(Vector2(OBSTACLE_WIDTH, size.y - gap_bottom), true)
	bottom_spikes.position.y = gap_bottom
	root.add_child(bottom_spikes)
	obstacles.append({
		"root": root,
		"top_height": top_height,
		"counted": false,
	})


func _spike_rect(spike_size: Vector2, flip_vertical: bool) -> TextureRect:
	var spike := TextureRect.new()
	spike.texture = SPIKE_TEXTURE
	spike.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spike.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	spike.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spike.size = spike_size
	spike.flip_v = flip_vertical
	spike.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spike


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
	draw_rect(Rect2(Vector2.ZERO, size), Color("#75d8f2"))
	draw_rect(Rect2(0, size.y * 0.82, size.x, size.y * 0.18), Color("#a8e57b"))
	draw_rect(Rect2(0, size.y * 0.82, size.x, 7), Color("#2f2140"))
	_draw_cloud(Vector2(70, 115), 0.9)
	_draw_cloud(Vector2(size.x - 260, 330), 0.65)
	_draw_cloud(Vector2(250, size.y * 0.68), 0.5)


func _draw_cloud(origin: Vector2, scale_factor: float) -> void:
	var cloud_color := Color(1.0, 0.95, 0.79, 0.88)
	draw_rect(Rect2(origin + Vector2(24, 0) * scale_factor, Vector2(104, 34) * scale_factor), cloud_color)
	draw_rect(Rect2(origin + Vector2(0, 27) * scale_factor, Vector2(166, 42) * scale_factor), cloud_color)
	draw_rect(Rect2(origin + Vector2(31, 63) * scale_factor, Vector2(108, 12) * scale_factor), Color("#efcf9c"))
