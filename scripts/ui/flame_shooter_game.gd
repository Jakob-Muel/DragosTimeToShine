class_name FlameShooterGame
extends "res://scripts/ui/talent_minigame.gd"

signal lives_changed(lives: int)
signal run_finished(score: int, reason: String)

const KNIGHT_TEXTURE := preload("res://assets/art/comic/flame_minigame/knight_top_down.png")
const FLAME_TEXTURE := preload("res://assets/art/comic/flame_minigame/flame.png")

const DRAGON_SIZE := Vector2(116, 142)
const KNIGHT_SIZE := Vector2(65, 78)
const FLAME_SIZE := Vector2(26, 32)
const DRAGON_EDGE_OVERHANG := 16.0
const DRAGON_MOVE_SPEED := 560.0
const DRAGON_FOLLOW_SPEED := 880.0
const GROUND_SCROLL_SPEED := 230.0
const KNIGHT_SPEED_START := 178.0
const FIRE_SPEED := 790.0
const AUTO_FIRE_INTERVAL := 0.34
const SPAWN_INTERVAL_START := 1.28
const SPAWN_INTERVAL_MIN := 0.56
const GROUND_TILE_HEIGHT := 840.0
const GROUND_TEXTURE := preload("res://assets/art/comic/flame_minigame/ground.png")

var dragon_seed := 34
var dragon: TextureRect
var score := 0
var lives := 3
var running := true
var finished := false
var spawn_time := 0.55
var auto_fire_time := 0.08
var target_x := 360.0
var scroll_offset := 0.0
var elapsed := 0.0
var random := RandomNumberGenerator.new()
var projectiles: Array[Dictionary] = []
var knights: Array[Dictionary] = []


func configure(session: Dictionary) -> void:
	super.configure(session)
	dragon_seed = int(session.get("appearance", {}).get("seed", 34))


func _ready() -> void:
	random.randomize()
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_build_dragon()
	queue_redraw()


func start_run() -> void:
	status_changed.emit({"remaining_attempts": lives})


func _build_dragon() -> void:
	dragon = _sprite(ProceduralDragonTextures.texture_for(dragon_seed, "overhead"), DRAGON_SIZE)
	dragon.position = Vector2(
		(size.x - DRAGON_SIZE.x) * 0.5,
		maxf(360.0, size.y - DRAGON_SIZE.y - 92.0)
	)
	dragon.z_index = 30
	add_child(dragon)
	target_x = dragon.position.x + DRAGON_SIZE.x * 0.5


func _process(delta: float) -> void:
	scroll_offset = fposmod(
		scroll_offset + GROUND_SCROLL_SPEED * delta,
		GROUND_TILE_HEIGHT
	)
	elapsed += delta
	queue_redraw()
	if finished or not running:
		return

	auto_fire_time -= delta
	if auto_fire_time <= 0.0:
		auto_fire_time += AUTO_FIRE_INTERVAL
		_fire()
	_update_dragon(delta)
	spawn_time -= delta
	if spawn_time <= 0.0:
		spawn_time += current_spawn_interval()
		_spawn_wave()
	_move_projectiles(delta)
	_move_knights(delta)
	_resolve_projectile_collisions()


func _update_dragon(delta: float) -> void:
	var keyboard_axis := Input.get_axis("ui_left", "ui_right")
	if not is_zero_approx(keyboard_axis):
		dragon.position.x += keyboard_axis * DRAGON_MOVE_SPEED * delta
		target_x = dragon.position.x + DRAGON_SIZE.x * 0.5
	else:
		var desired_x := target_x - DRAGON_SIZE.x * 0.5
		dragon.position.x = move_toward(
			dragon.position.x,
			desired_x,
			DRAGON_FOLLOW_SPEED * delta
		)
	dragon.position.x = clampf(
		dragon.position.x,
		-DRAGON_EDGE_OVERHANG,
		size.x - DRAGON_SIZE.x + DRAGON_EDGE_OVERHANG
	)
	dragon.rotation = lerpf(
		dragon.rotation,
		keyboard_axis * 0.075,
		minf(1.0, delta * 9.0)
	)


func _gui_input(event: InputEvent) -> void:
	if finished:
		return
	if event is InputEventScreenTouch and event.pressed:
		target_x = event.position.x
		accept_event()
	elif event is InputEventScreenDrag:
		target_x = event.position.x
		accept_event()
	elif (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		target_x = event.position.x
		accept_event()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		target_x = event.position.x
		accept_event()


func _fire() -> void:
	if finished:
		return
	var flame := _sprite(FLAME_TEXTURE, FLAME_SIZE)
	flame.position = Vector2(
		dragon.position.x + DRAGON_SIZE.x * 0.5 - FLAME_SIZE.x * 0.5,
		dragon.position.y - FLAME_SIZE.y * 0.55
	)
	# Comic flame art already points toward the incoming knights.
	flame.rotation = 0.0
	flame.pivot_offset = FLAME_SIZE / 2.0
	flame.z_index = 24
	add_child(flame)
	projectiles.append({"root": flame})


func _spawn_wave() -> void:
	var maximum_knights := mini(3, 1 + score / 6)
	var knight_count := random.randi_range(1, maximum_knights)
	var lanes := [0, 1, 2, 3, 4]
	_shuffle_with_game_rng(lanes)
	for index in knight_count:
		var lane := int(lanes[index])
		_spawn_knight(_lane_x(lane), -KNIGHT_SIZE.y - float(index) * 34.0)


func _shuffle_with_game_rng(values: Array) -> void:
	for index in range(values.size() - 1, 0, -1):
		var other := random.randi_range(0, index)
		var temporary = values[index]
		values[index] = values[other]
		values[other] = temporary


func _lane_x(lane: int) -> float:
	var lane_width := size.x / 5.0
	return lane_width * (float(lane) + 0.5) - KNIGHT_SIZE.x * 0.5


func _spawn_knight(x: float, y: float) -> void:
	var knight := _sprite(KNIGHT_TEXTURE, KNIGHT_SIZE)
	knight.position = Vector2(x, y)
	knight.z_index = 18
	add_child(knight)
	knights.append({
		"root": knight,
		"speed": KNIGHT_SPEED_START + minf(105.0, float(score) * 3.5),
	})


func _move_projectiles(delta: float) -> void:
	for index in range(projectiles.size() - 1, -1, -1):
		var flame := projectiles[index]["root"] as TextureRect
		flame.position.y -= FIRE_SPEED * delta
		if flame.position.y + FLAME_SIZE.y < -24.0:
			_remove_entry(projectiles, index)


func _move_knights(delta: float) -> void:
	for index in range(knights.size() - 1, -1, -1):
		var entry := knights[index]
		var knight := entry["root"] as TextureRect
		knight.position.y += float(entry["speed"]) * delta
		knight.rotation = sin(elapsed * 4.2 + float(index)) * 0.025
		if knight.position.y > size.y + 12.0:
			_remove_entry(knights, index)
			_lose_life("knight_escaped")


func _resolve_projectile_collisions() -> void:
	for projectile_index in range(projectiles.size() - 1, -1, -1):
		if projectile_index >= projectiles.size():
			continue
		var flame := projectiles[projectile_index]["root"] as TextureRect
		var flame_hitbox := Rect2(
			flame.position + FLAME_SIZE * Vector2(0.24, 0.18),
			FLAME_SIZE * Vector2(0.52, 0.64)
		)
		var consumed := false
		for knight_index in range(knights.size() - 1, -1, -1):
			var knight := knights[knight_index]["root"] as TextureRect
			var knight_hitbox := Rect2(
				knight.position + KNIGHT_SIZE * Vector2(0.165, 0.10),
				KNIGHT_SIZE * Vector2(0.67, 0.80)
			)
			if flame_hitbox.intersects(knight_hitbox):
				_spawn_hit_flash(knight.position + KNIGHT_SIZE * 0.5, Color("#ffd268"))
				_remove_entry(projectiles, projectile_index)
				_remove_entry(knights, knight_index)
				score += 1
				score_changed.emit(score)
				consumed = true
				break
		if consumed:
			continue


func _spawn_hit_flash(center: Vector2, color: Color) -> void:
	var flash := Label.new()
	flash.text = "✦"
	flash.position = center - Vector2(38, 44)
	flash.size = Vector2(76, 76)
	flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flash.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	flash.add_theme_font_size_override("font_size", 54)
	flash.add_theme_color_override("font_color", color)
	flash.add_theme_color_override("font_outline_color", Color("#3f2f43"))
	flash.add_theme_constant_override("outline_size", 4)
	flash.z_index = 60
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(1.55, 1.55), 0.18)
	tween.tween_property(flash, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(flash.queue_free)


func _lose_life(reason: String) -> void:
	if finished:
		return
	lives = maxi(0, lives - 1)
	lives_changed.emit(lives)
	status_changed.emit({"remaining_attempts": lives})
	if lives <= 0:
		_finish(reason)


func _finish(reason: String) -> void:
	if finished:
		return
	finished = true
	running = false
	complete_talent_run(score, {"reason": reason})
	run_finished.emit.call_deferred(score, reason)


func current_spawn_interval() -> float:
	return maxf(
		SPAWN_INTERVAL_MIN,
		SPAWN_INTERVAL_START - float(score / 4) * 0.115
	)


func _sprite(texture: Texture2D, sprite_size: Vector2) -> TextureRect:
	var result := TextureRect.new()
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.texture = texture
	result.size = sprite_size
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


func _remove_entry(entries: Array[Dictionary], index: int) -> void:
	if index < 0 or index >= entries.size():
		return
	var root := entries[index]["root"] as Control
	if is_instance_valid(root):
		root.queue_free()
	entries.remove_at(index)


func _draw() -> void:
	# A single periodic illustration repeats vertically. Its sinuous path has
	# matching position and tangent at both edges; landmarks never change identity.
	var tile_count := ceili(size.y / GROUND_TILE_HEIGHT) + 2
	for tile_index in range(-1, tile_count):
		var tile_y := float(tile_index) * GROUND_TILE_HEIGHT + scroll_offset
		draw_texture_rect(GROUND_TEXTURE, Rect2(0, tile_y, size.x, GROUND_TILE_HEIGHT), false)


func debug_spawn_knight(x: float = -1.0) -> void:
	_spawn_knight(size.x * 0.5 - KNIGHT_SIZE.x * 0.5 if x < 0.0 else x, 240.0)


func debug_fire() -> void:
	_fire()
