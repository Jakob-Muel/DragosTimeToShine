extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_script: GDScript = load("res://scripts/ui/flame_shooter_game.gd")
	var game: FlameShooterGame = game_script.new() as FlameShooterGame
	game.size = Vector2(720, 1200)
	root.add_child(game)
	await process_frame

	assert(game.dragon != null, "The shooter must create its top-down dragon.")
	assert(game.lives == 3, "The shooter must start with three lives.")
	assert(is_equal_approx(game.current_spawn_interval(), 1.28), "The first wave must be readable.")
	game.debug_spawn_knight()
	assert(game.knights.size() == 1, "A debug knight must enter the playfield.")
	game.auto_fire_time = 0.0
	game.call("_process", 0.01)
	assert(game.projectiles.size() == 1, "The dragon must fire automatically.")
	var knight_root := game.knights[0]["root"] as TextureRect
	var first_flame := game.projectiles[0]["root"] as TextureRect
	first_flame.position = knight_root.position
	game.call("_resolve_projectile_collisions")
	assert(game.score == 1, "A flame hitting a knight must increase the score.")
	assert(game.knights.is_empty(), "A defeated knight must leave the playfield.")
	game.score = 24
	assert(game.current_spawn_interval() < 1.0, "Knight waves must accelerate as score rises.")

	print("Flame shooter test: valid")
	quit()
