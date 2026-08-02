extends Control

const FLIGHT_GAME := preload("res://scripts/ui/flight_game.gd")
const MAIN_MENU_SCREEN := preload("res://scenes/screens/main_menu_screen.tscn")
const DEN_SCREEN := preload("res://scenes/screens/den_screen.tscn")
const DRAGON_LIST_SCREEN := preload("res://scenes/screens/dragon_list_screen.tscn")
const EGG_LIST_SCREEN := preload("res://scenes/screens/egg_list_screen.tscn")
const EGG_DETAIL_SCREEN := preload("res://scenes/screens/egg_detail_screen.tscn")
const SHOP_SCREEN := preload("res://scenes/screens/shop_screen.tscn")
const SETTINGS_SCREEN := preload("res://scenes/screens/settings_screen.tscn")
const FUSION_SCREEN := preload("res://scenes/screens/fusion_screen.tscn")
const FLIGHT_DRAGON_SELECT_SCREEN := preload("res://scenes/screens/flight_dragon_select_screen.tscn")
const FLIGHT_HUB_SCREEN := preload("res://scenes/screens/flight_hub_screen.tscn")
const FLIGHT_TRAINING_SCREEN := preload("res://scenes/screens/flight_training_screen.tscn")
const FLIGHT_CONTEST_SCREEN := preload("res://scenes/screens/flight_contest_screen.tscn")
const HABITAT_SCREEN := preload("res://scenes/screens/habitat_screen.tscn")
const GROOM_SCREEN := preload("res://scenes/screens/groom_screen.tscn")

const DESIGN_WIDTH := 720.0
const BASE_DESIGN_HEIGHT := 1565.373

var screen_layer: GameCanvas
var screen_router: ScreenRouter
var canvas_size := Vector2(DESIGN_WIDTH, BASE_DESIGN_HEIGHT)
var layout_ready := false
var layout_rebuild_queued := false
var current_screen := "main"
var current_egg_id := ""
var selected_dragon_id := "luma"
var hunger: int:
	get:
		return GameState.get_dragon_hunger(selected_dragon_id)
	set(value):
		GameState.set_dragon_hunger(selected_dragon_id, value)
var cleanliness: float:
	get:
		return GameState.get_dragon_cleanliness(selected_dragon_id)
	set(value):
		GameState.set_dragon_cleanliness(selected_dragon_id, value)
var care_points: int:
	get:
		return GameState.get_dragon_care_points(selected_dragon_id)
	set(value):
		GameState.set_dragon_care_points(selected_dragon_id, value)


func _ready() -> void:
	var game_theme := Theme.new()
	game_theme.default_font = UiTokens.FONT_REGULAR
	game_theme.default_font_size = 26
	theme = game_theme
	screen_layer = GameCanvas.new()
	add_child(screen_layer)
	screen_router = ScreenRouter.new()
	add_child(screen_router)
	screen_router.configure(screen_layer)
	screen_router.navigation_requested.connect(_on_screen_navigation)
	_fit_design_canvas()
	Localization.locale_changed.connect(_on_locale_changed)
	_show_main_menu()
	layout_ready = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(screen_layer):
		var layout_changed := _fit_design_canvas()
		if layout_changed and layout_ready and not layout_rebuild_queued:
			layout_rebuild_queued = true
			call_deferred("_apply_responsive_rebuild")


func _fit_design_canvas() -> bool:
	var changed := screen_layer.fit_to(size)
	canvas_size = screen_layer.logical_size
	return changed


func _apply_responsive_rebuild() -> void:
	layout_rebuild_queued = false
	_rebuild_current_screen()


func _clear_screen() -> void:
	if screen_router != null:
		screen_router.clear()
	for child in screen_layer.get_children():
		child.queue_free()


func _show_routed_screen(
	route: String,
	scene: PackedScene,
	extra_context: Dictionary = {}
) -> void:
	_clear_screen()
	current_screen = route
	var screen_context := {
		"canvas_size": canvas_size,
		"safe_top_inset": screen_layer.safe_top_inset(),
		"safe_bottom_inset": screen_layer.safe_bottom_inset(),
	}
	screen_context.merge(extra_context, true)
	screen_router.show_scene(route, scene, screen_context)


func _on_screen_navigation(route: String, params: Dictionary) -> void:
	match route:
		"main":
			_show_main_menu()
		"den":
			_show_den()
		"dragons":
			_show_dragons()
		"eggs":
			_show_eggs()
		"egg_detail":
			_show_egg_detail(
				String(params.get("egg_id", "")),
				bool(params.get("query_steps", true))
			)
		"shop":
			_show_shop()
		"settings":
			_show_settings()
		"fusion":
			_show_fusion()
		"reset_app":
			_reset_app()
		"purchase_egg":
			_purchase_egg(String(params.get("kind", "fire")))
		"select_dragon":
			_select_dragon(String(params.get("dragon_id", "luma")))
		"habitat":
			selected_dragon_id = String(params.get("selected_dragon_id", selected_dragon_id))
			_show_habitat()
		"groom":
			selected_dragon_id = String(params.get("selected_dragon_id", selected_dragon_id))
			_show_grooming()
		"flight_hub":
			_show_flight_hub()
		"flight_select":
			_show_flight_select()
		"select_flight_dragon":
			selected_dragon_id = String(params.get("dragon_id", "luma"))
			_show_flight_hub()
		"flight_training":
			_show_flight_training()
		"flight_contest":
			_show_flight_contest()
		_:
			push_warning("Unknown screen route: %s" % route)


func _call_active_screen(method: StringName, args: Array = []) -> Variant:
	if screen_router == null or not is_instance_valid(screen_router.active_screen):
		return null
	if not screen_router.active_screen.has_method(method):
		return null
	return screen_router.active_screen.callv(method, args)


func _show_main_menu() -> void:
	_show_routed_screen("main", MAIN_MENU_SCREEN)

func _show_den() -> void:
	_show_routed_screen("den", DEN_SCREEN)

func _show_dragons() -> void:
	_show_routed_screen("dragons", DRAGON_LIST_SCREEN)

func _select_dragon(dragon_id: String) -> void:
	selected_dragon_id = dragon_id
	_show_habitat()


func _show_eggs() -> void:
	_show_routed_screen("eggs", EGG_LIST_SCREEN)

func _show_egg_detail(egg_id: String, query_steps: bool = true) -> void:
	current_egg_id = egg_id
	_show_routed_screen(
		"egg_detail",
		EGG_DETAIL_SCREEN,
		{"egg_id": egg_id, "query_steps": query_steps}
	)

func _start_current_egg() -> void:
	_call_active_screen("start_incubation")

func _refresh_current_egg_steps() -> void:
	_call_active_screen("refresh_steps")

func _add_test_steps() -> void:
	_call_active_screen("add_test_steps")

func _hatch_current_egg() -> void:
	_call_active_screen("hatch")

func _show_shop() -> void:
	_show_routed_screen("shop", SHOP_SCREEN)


func _show_settings() -> void:
	_show_routed_screen("settings", SETTINGS_SCREEN)


func _show_fusion() -> void:
	_show_routed_screen("fusion", FUSION_SCREEN)


func _reset_app() -> void:
	GameState.reset_app()
	selected_dragon_id = "luma"
	current_egg_id = ""
	_show_main_menu()


func _purchase_egg(kind: String = "fire") -> void:
	var egg_id := GameState.purchase_egg(kind)
	if not egg_id.is_empty():
		_show_egg_detail(egg_id, false)


func _show_habitat() -> void:
	_show_routed_screen(
		"habitat",
		HABITAT_SCREEN,
		{"selected_dragon_id": selected_dragon_id}
	)

func _show_grooming() -> void:
	_show_routed_screen(
		"groom",
		GROOM_SCREEN,
		{"selected_dragon_id": selected_dragon_id}
	)

func _show_competition() -> void:
	_show_flight_select()


func _show_flight_select() -> void:
	_show_routed_screen("flight_select", FLIGHT_DRAGON_SELECT_SCREEN)


func _show_flight_hub() -> void:
	_show_routed_screen(
		"flight_hub",
		FLIGHT_HUB_SCREEN,
		{"selected_dragon_id": selected_dragon_id}
	)

func _show_flight_training() -> void:
	_show_routed_screen(
		"flight_training",
		FLIGHT_TRAINING_SCREEN,
		{"selected_dragon_id": selected_dragon_id}
	)

func _on_flight_score_changed(_score: int) -> void:
	# Compatibility entry point for deterministic smoke tests.
	GameState.add_flight_xp(selected_dragon_id, 1)

func _show_flight_contest() -> void:
	if not GameState.can_enter_flight_contest(selected_dragon_id):
		_show_flight_hub()
		return
	_show_routed_screen(
		"flight_contest",
		FLIGHT_CONTEST_SCREEN,
		{"selected_dragon_id": selected_dragon_id}
	)

func _complete_flight_contest(distance: int) -> void:
	# Compatibility entry point for deterministic smoke tests.
	GameState.complete_flight_contest(selected_dragon_id, distance)

func _on_locale_changed(_locale: String) -> void:
	_rebuild_current_screen()


func _rebuild_current_screen() -> void:
	match current_screen:
		"den":
			_show_den()
		"dragons":
			_show_dragons()
		"eggs":
			_show_eggs()
		"egg_detail":
			_show_egg_detail(current_egg_id)
		"shop":
			_show_shop()
		"settings":
			_show_settings()
		"fusion":
			_show_fusion()
		"habitat":
			_show_habitat()
		"groom":
			_show_grooming()
		"flight_hub":
			_show_flight_hub()
		"flight_select":
			_show_flight_select()
		"flight_training":
			_show_flight_training()
		"flight_contest":
			_show_flight_contest()
		_:
			_show_main_menu()


func debug_groom_stroke() -> void:
	if current_screen != "groom":
		_show_grooming()
	_call_active_screen("debug_groom_stroke")

func debug_groom_off_sprite() -> void:
	if current_screen != "groom":
		_show_grooming()
	_call_active_screen("debug_groom_off_sprite")

func debug_set_locale(locale_code: String) -> void:
	Localization.set_locale(locale_code)


func debug_add_ice_dragon() -> String:
	for dragon in GameState.dragons:
		if String(dragon.get("definition_id", "")) == "frost":
			return String(dragon.get("id"))
	var dragon_id := "debug-ice-dragon"
	return GameState.unlock_dragon(&"frost", dragon_id, false, false)


func debug_add_fire_dragon() -> String:
	for dragon in GameState.dragons:
		if String(dragon.get("definition_id", "")) == "ember":
			return String(dragon.get("id"))
	return GameState.unlock_dragon(&"ember", "debug-fire-dragon", false, false)


func debug_add_water_dragon() -> String:
	for dragon in GameState.dragons:
		if String(dragon.get("definition_id", "")) == "marina":
			return String(dragon.get("id"))
	return GameState.unlock_dragon(&"marina", "debug-water-dragon", false, false)


func debug_add_earth_dragon() -> String:
	for dragon in GameState.dragons:
		if String(dragon.get("definition_id", "")) == "terra":
			return String(dragon.get("id"))
	return GameState.unlock_dragon(&"terra", "debug-earth-dragon", false, false)


func debug_add_lava_dragon() -> String:
	for dragon in GameState.dragons:
		if String(dragon.get("definition_id", "")) == "lavara":
			return String(dragon.get("id"))
	return GameState.unlock_dragon(&"lavara", "debug-lava-dragon", false, false)


func debug_add_mud_dragon() -> String:
	for dragon in GameState.dragons:
		if String(dragon.get("definition_id", "")) == "mudara":
			return String(dragon.get("id"))
	return GameState.unlock_dragon(&"mudara", "debug-mud-dragon", false, false)


func debug_show_screen(screen_name: String) -> void:
	match screen_name:
		"den":
			_show_den()
		"shop", "shop_elements":
			GameState.gold = 1
			_show_shop()
		"settings":
			_show_settings()
		"fusion":
			debug_add_fire_dragon()
			debug_add_water_dragon()
			GameState.fusion_stars = 1
			_show_fusion()
		"fusion_trace":
			debug_add_fire_dragon()
			debug_add_water_dragon()
			GameState.fusion_stars = 1
			_show_fusion()
			_call_active_screen("debug_select_parents")
			_call_active_screen("debug_begin_trace")
		"fusion_result":
			debug_add_fire_dragon()
			debug_add_water_dragon()
			GameState.fusion_stars = 1
			_show_fusion()
			_call_active_screen("debug_select_parents")
			_call_active_screen("debug_complete_all")
		"fusion_eggs":
			var fusion_list_fire_id := debug_add_fire_dragon()
			var fusion_list_water_id := debug_add_water_dragon()
			GameState.fusion_stars = 1
			GameState.fuse_dragons(fusion_list_fire_id, fusion_list_water_id)
			_show_eggs()
		"fusion_egg":
			var fusion_detail_fire_id := debug_add_fire_dragon()
			var fusion_detail_water_id := debug_add_water_dragon()
			GameState.fusion_stars = 1
			var fusion_detail_egg_id := GameState.fuse_dragons(
				fusion_detail_fire_id,
				fusion_detail_water_id
			)
			_show_egg_detail(fusion_detail_egg_id, false)
		"lava_egg":
			var lava_fire_id := debug_add_fire_dragon()
			var lava_earth_id := debug_add_earth_dragon()
			GameState.fusion_stars = maxi(1, GameState.fusion_stars)
			var lava_egg_id := GameState.fuse_dragons(lava_fire_id, lava_earth_id)
			_show_egg_detail(lava_egg_id, false)
		"mud_egg":
			var mud_water_id := debug_add_water_dragon()
			var mud_earth_id := debug_add_earth_dragon()
			GameState.fusion_stars = maxi(1, GameState.fusion_stars)
			var mud_egg_id := GameState.fuse_dragons(mud_water_id, mud_earth_id)
			_show_egg_detail(mud_egg_id, false)
		"fusion_island":
			selected_dragon_id = GameState.unlock_dragon(
				&"voltara",
				"debug-fusion-dragon",
				false,
				false
			)
			_show_habitat()
		"lava_island":
			selected_dragon_id = debug_add_lava_dragon()
			_show_habitat()
		"mud_island":
			selected_dragon_id = debug_add_mud_dragon()
			_show_habitat()
		"ice_egg":
			var debug_egg_id := GameState._append_egg(&"frost")
			_show_egg_detail(debug_egg_id, false)
		"fire_egg":
			GameState.gold = 1
			_purchase_egg("fire")
		"water_egg":
			GameState.gold = 1
			_purchase_egg("water")
		"earth_egg":
			GameState.gold = 1
			_purchase_egg("earth")
		"dragons_ice":
			debug_add_ice_dragon()
			_show_dragons()
		"dragons_elements":
			debug_add_fire_dragon()
			debug_add_water_dragon()
			debug_add_earth_dragon()
			_show_dragons()
		"dragons_fusions":
			debug_add_fire_dragon()
			debug_add_water_dragon()
			debug_add_earth_dragon()
			debug_add_lava_dragon()
			debug_add_mud_dragon()
			_show_dragons()
		"ice_island":
			selected_dragon_id = debug_add_ice_dragon()
			_show_habitat()
		"fire_island":
			selected_dragon_id = debug_add_fire_dragon()
			_show_habitat()
		"water_island":
			selected_dragon_id = debug_add_water_dragon()
			_show_habitat()
		"earth_island":
			selected_dragon_id = debug_add_earth_dragon()
			_show_habitat()
		"habitat":
			_show_habitat()
		"groom":
			_show_grooming()
		"groomed":
			_show_grooming()
			debug_groom_stroke()
		"groom_off":
			_show_grooming()
			debug_groom_off_sprite()
		"competition":
			_show_competition()
		"flight_choice":
			debug_add_fire_dragon()
			debug_add_water_dragon()
			debug_add_earth_dragon()
			debug_add_lava_dragon()
			debug_add_mud_dragon()
			_show_competition()
		"flight_hub":
			_show_flight_hub()
		"flight_hub_fire":
			selected_dragon_id = debug_add_fire_dragon()
			_show_flight_hub()
		"flight_training":
			_show_flight_training()
			for child in screen_router.active_screen.get_children():
				if child.get_script() == FLIGHT_GAME:
					child.call("debug_show_obstacle")
					break
		"flight_training_water":
			selected_dragon_id = debug_add_water_dragon()
			_show_flight_training()
			for child in screen_router.active_screen.get_children():
				if child.get_script() == FLIGHT_GAME:
					child.call("debug_show_obstacle")
					break
		"flight_contest":
			GameState.add_flight_xp(
				selected_dragon_id,
				maxi(0, GameState.FLIGHT_CONTEST_LEVEL * GameState.FLIGHT_XP_PER_LEVEL - GameState.get_flight_xp(selected_dragon_id))
			)
			_show_flight_contest()
		"result":
			GameState.add_flight_xp(
				selected_dragon_id,
				maxi(0, GameState.FLIGHT_CONTEST_LEVEL * GameState.FLIGHT_XP_PER_LEVEL - GameState.get_flight_xp(selected_dragon_id))
			)
			_show_flight_contest()
			_call_active_screen("debug_complete_race")
		_:
			_show_main_menu()
