extends SceneTree

const SEEDED_DRAGON := preload("res://scripts/ui/seeded_dragon.gd")


func _init() -> void:
	var first := SEEDED_DRAGON.traits_for_seed(37)
	var repeated := SEEDED_DRAGON.traits_for_seed(37)
	var different := SEEDED_DRAGON.traits_for_seed(38)
	assert(first == repeated, "The same seed must always produce identical dragon traits.")
	assert(first != different, "Neighboring seeds must produce different dragon traits.")
	var signatures := {}
	for seed_value in range(1, 101):
		var traits: Dictionary = SEEDED_DRAGON.traits_for_seed(seed_value)
		var signature := "%s:%s:%s:%s:%s:%s:%s" % [
			traits["palette"], traits["body"], traits["wings"],
			traits["horns"], traits["pattern"], traits["tail"], traits["eyes"],
		]
		signatures[signature] = true
	assert(signatures.size() == 100, "The first 100 seeds should be visually unique.")
	print("Seeded dragon test: valid (%d unique appearances)" % signatures.size())
	quit()
