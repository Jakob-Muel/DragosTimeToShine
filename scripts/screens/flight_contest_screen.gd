extends GameScreen

const PIXEL_ART := preload("res://scripts/ui/pixel_art.gd")
const RACE_BACKGROUND := preload("res://scripts/ui/flight_race_background.gd")
const OPPONENT_TEXTURES := [
	preload("res://assets/art/flight/opponents/red_flight.png"),
	preload("res://assets/art/flight/opponents/green_flight.png"),
	preload("res://assets/art/flight/opponents/blue_flight.png"),
]
const OPPONENT_COLORS := [
	Color("#e83d4b"),
	Color("#27a96b"),
	Color("#357de4"),
]
const RACER_SIZE := Vector2(156, 98)
const START_X := 42.0
const FINISH_X := 530.0

var selected_dragon_id := "luma"
var player_distance := 0
var opponent_distances: Array[int] = []
var racers: Array[Dictionary] = []
var background: FlightRaceBackground
var random := RandomNumberGenerator.new()
var race_finished := false


func build() -> void:
	random.randomize()
	selected_dragon_id = String(context.get("selected_dragon_id", "luma"))
	player_distance = GameState.flight_contest_distance(selected_dragon_id)
	opponent_distances = GameState.flight_contest_opponent_distances(selected_dragon_id)
	var top_y := safe_top_y(28.0)

	background = RACE_BACKGROUND.new()
	background.size = canvas_size
	add_child(background)

	var top_panel := Panel.new()
	top_panel.position = Vector2(24, top_y)
	top_panel.size = Vector2(672, 112)
	top_panel.z_index = 100
	top_panel.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(Color(1, 0.98, 0.91, 0.97), UiTokens.INK, 18, 6)
	)
	add_child(top_panel)
	var back := WidgetFactory.small_button("‹", Rect2(16, 20, 74, 68), UiTokens.CREAM)
	back.disabled = true
	top_panel.add_child(back)
	var title := WidgetFactory.label(
		tr_text(
			"FLIGHT_CONTEST_ROUND",
			{"round": GameState.flight_contest_wins(selected_dragon_id) + 1}
		),
		34,
		UiTokens.INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	title.position = Vector2(94, 8)
	title.size = Vector2(484, 48)
	top_panel.add_child(title)
	var goal := WidgetFactory.label(
		tr_text("FLIGHT_CONTEST_GOAL", {"meters": GameState.flight_contest_goal(selected_dragon_id)}),
		22,
		UiTokens.PINK_DARK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	goal.position = Vector2(94, 58)
	goal.size = Vector2(484, 36)
	top_panel.add_child(goal)

	var selected_dragon := GameState.get_dragon(selected_dragon_id)
	_add_racer(
		tr_text(GameState.dragon_name_key(selected_dragon)),
		GameState.flight_texture(selected_dragon),
		player_distance,
		0,
		UiTokens.PINK_DARK,
		true,
		top_y
	)
	for index in 3:
		_add_racer(
			tr_text("FLIGHT_RIVAL_NAME", {"number": index + 1}),
			OPPONENT_TEXTURES[index],
			opponent_distances[index],
			index + 1,
			OPPONENT_COLORS[index],
			false,
			top_y
		)
	_start_race()


func _add_racer(
	racer_name: String,
	texture: Texture2D,
	target_distance: int,
	lane_index: int,
	accent: Color,
	is_player: bool,
	top_y: float
) -> void:
	var lane_y := top_y + 152.0 + lane_index * 242.0
	var lane := Panel.new()
	lane.position = Vector2(24, lane_y)
	lane.size = Vector2(672, 214)
	lane.z_index = 20
	lane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lane.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(
			Color(1.0, 0.98, 0.91, 0.78) if is_player else Color(1.0, 1.0, 1.0, 0.67),
			accent,
			15,
			4
		)
	)
	add_child(lane)
	var name := WidgetFactory.label(
		racer_name,
		23,
		accent,
		HORIZONTAL_ALIGNMENT_LEFT,
		UiTokens.FONT_BOLD
	)
	name.position = Vector2(18, 10)
	name.size = Vector2(360, 36)
	lane.add_child(name)
	var distance := WidgetFactory.label(
		tr_text("FLIGHT_DISTANCE", {"meters": 0}),
		22,
		accent,
		HORIZONTAL_ALIGNMENT_RIGHT,
		UiTokens.FONT_BOLD
	)
	distance.position = Vector2(382, 10)
	distance.size = Vector2(270, 36)
	lane.add_child(distance)
	var track := ColorRect.new()
	track.position = Vector2(20, 177)
	track.size = Vector2(632, 7)
	track.color = Color("#d7c9ac")
	lane.add_child(track)
	var finish_marker := ColorRect.new()
	finish_marker.position = Vector2(FINISH_X + 75.0, 48)
	finish_marker.size = Vector2(6, 136)
	finish_marker.color = UiTokens.INK
	lane.add_child(finish_marker)
	var finish_flag := WidgetFactory.label("⚑", 28, UiTokens.INK, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD)
	finish_flag.position = Vector2(FINISH_X + 54.0, 43)
	finish_flag.size = Vector2(48, 36)
	lane.add_child(finish_flag)

	var dragon := WidgetFactory.texture_rect(
		texture,
		Rect2(START_X, 58, RACER_SIZE.x, RACER_SIZE.y),
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	dragon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dragon.flip_h = true
	dragon.pivot_offset = RACER_SIZE / 2.0
	dragon.z_index = 10
	lane.add_child(dragon)
	racers.append({
		"dragon": dragon,
		"distance_label": distance,
		"target_distance": target_distance,
		"lane": lane,
	})


func _start_race() -> void:
	var race_duration := 6.2
	var comparison_distance := maxi(
		player_distance,
		GameState.flight_contest_goal(selected_dragon_id)
	)
	for index in racers.size():
		var racer: Dictionary = racers[index]
		var dragon := racer["dragon"] as TextureRect
		var target_distance := int(racer["target_distance"])
		var finish_ratio := clampf(
			float(target_distance) / float(maxi(1, comparison_distance)),
			0.0,
			1.0
		)
		var target_x := START_X + (FINISH_X - START_X) * finish_ratio
		var flight_time := maxf(2.4, race_duration * finish_ratio)
		var tween := create_tween()
		tween.tween_interval(0.65)
		tween.set_parallel(true)
		tween.tween_property(dragon, "position:x", target_x, flight_time).set_trans(Tween.TRANS_SINE)
		tween.tween_method(
			_update_racer_distance.bind(index),
			0.0,
			float(target_distance),
			flight_time
		)
		tween.tween_method(
			_bob_racer.bind(index),
			0.0,
			TAU * 4.0,
			flight_time
		)
	var finish_tween := create_tween()
	finish_tween.tween_interval(0.65 + race_duration)
	finish_tween.tween_callback(_finish_race)


func _update_racer_distance(value: float, racer_index: int) -> void:
	if racer_index < 0 or racer_index >= racers.size():
		return
	var label := racers[racer_index]["distance_label"] as Label
	if is_instance_valid(label):
		label.text = tr_text("FLIGHT_DISTANCE", {"meters": floori(value)})


func _bob_racer(value: float, racer_index: int) -> void:
	if racer_index < 0 or racer_index >= racers.size():
		return
	var dragon := racers[racer_index]["dragon"] as TextureRect
	if is_instance_valid(dragon):
		dragon.position.y = 58.0 + sin(value + racer_index * 0.9) * 10.0
		dragon.rotation = sin(value * 0.5 + racer_index) * 0.04


func _finish_race() -> void:
	if race_finished:
		return
	race_finished = true
	background.set_scroll_speed(32.0)
	var reward := GameState.complete_flight_contest(selected_dragon_id, player_distance)
	_show_result(reward)


func _show_result(reward: int) -> void:
	var won := reward > 0
	var overlay := Control.new()
	overlay.size = canvas_size
	overlay.z_index = 4000
	add_child(overlay)
	var dim := ColorRect.new()
	dim.size = canvas_size
	dim.color = Color(0.10, 0.07, 0.14, 0.66)
	overlay.add_child(dim)
	var panel := Panel.new()
	panel.position = Vector2(60, canvas_size.y * 0.5 - 300)
	panel.size = Vector2(600, 600)
	panel.add_theme_stylebox_override(
		"panel",
		WidgetFactory.panel_style(UiTokens.WHITE, UiTokens.INK, 24, 10)
	)
	overlay.add_child(panel)
	var title := WidgetFactory.label(
		tr_text("FLIGHT_CONTEST_WIN" if won else "FLIGHT_CONTEST_LOSS"),
		40,
		UiTokens.PINK_DARK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	title.position = Vector2(25, 38)
	title.size = Vector2(550, 64)
	panel.add_child(title)
	var result_distance := WidgetFactory.label(
		tr_text("FLIGHT_DISTANCE_RESULT", {"meters": player_distance}),
		34,
		UiTokens.INK,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	result_distance.position = Vector2(25, 124)
	result_distance.size = Vector2(550, 58)
	panel.add_child(result_distance)
	var best_opponent := 0
	for distance: int in opponent_distances:
		best_opponent = maxi(best_opponent, distance)
	var rival_result := WidgetFactory.label(
		tr_text("FLIGHT_RIVAL_BEST", {"meters": best_opponent}),
		25,
		UiTokens.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	rival_result.position = Vector2(25, 192)
	rival_result.size = Vector2(550, 48)
	panel.add_child(rival_result)
	var reward_label := WidgetFactory.label(
		tr_text("FLIGHT_GOLD_REWARD", {"gold": reward}) if won else tr_text("FLIGHT_NO_REWARD"),
		31,
		UiTokens.GOLD if won else UiTokens.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	reward_label.position = Vector2(25, 258)
	reward_label.size = Vector2(550, 58)
	panel.add_child(reward_label)
	var primary := WidgetFactory.button(
		tr_text("FLIGHT_GO_TO_SHOP" if won else "FLIGHT_RETRY_TRAINING"),
		Rect2(80, 360, 440, 92),
		UiTokens.PINK,
		UiTokens.PINK_DARK
	)
	primary.add_theme_font_size_override("font_size", 29)
	primary.pressed.connect(navigate.bind("shop" if won else "flight_training", {}))
	panel.add_child(primary)
	var school := WidgetFactory.button(
		tr_text("FLIGHT_BACK_TO_HUB"),
		Rect2(80, 474, 440, 78),
		Color("#8ed5aa"),
		Color("#4d9a70")
	)
	school.add_theme_font_size_override("font_size", 26)
	school.pressed.connect(navigate.bind("flight_hub", {}))
	panel.add_child(school)
	if won:
		_burst_confetti(overlay, panel.position + Vector2(300, 205), 44, 20)


func _burst_confetti(parent: Control, origin: Vector2, piece_count: int, layer: int) -> void:
	var colors := [
		UiTokens.PINK,
		UiTokens.GOLD,
		UiTokens.MINT,
		UiTokens.SKY,
		Color("#9b7ede"),
		UiTokens.CREAM,
	]
	for piece_index in piece_count:
		var piece := PIXEL_ART.ConfettiPiece.new()
		piece.position = origin + Vector2(
			random.randf_range(-18.0, 18.0),
			random.randf_range(-8.0, 8.0)
		)
		piece.size = Vector2(random.randi_range(10, 17), random.randi_range(16, 27))
		piece.velocity = Vector2(
			random.randf_range(-330.0, 330.0),
			random.randf_range(-570.0, -280.0)
		)
		piece.spin = random.randf_range(-9.0, 9.0)
		piece.piece_color = colors[piece_index % colors.size()]
		piece.z_index = layer
		parent.add_child(piece)


func debug_complete_race() -> void:
	_finish_race()
