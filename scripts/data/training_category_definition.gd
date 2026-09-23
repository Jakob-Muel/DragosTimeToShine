class_name TrainingCategoryDefinition
extends Resource

@export var id: StringName
@export var name_key: StringName
@export var icon_glyph := "✦"
@export var accent_color := Color("#e9aa46")
@export var minigame_route: StringName # Legacy route for compatibility.
@export var minigame_scene: PackedScene
@export var instruction_key: StringName
@export var xp_per_level := 10
@export var xp_per_score := 1.0
@export var maximum_care_bonus := 0.25
@export var star_thresholds := PackedInt32Array([0, 5, 15, 30, 50])
@export var contest_level := 5
@export var units_per_level := 10
@export var gold_reward := 1


func level_for_xp(xp: int) -> int:
	return maxi(0, xp) / maxi(1, xp_per_level)


func contest_value_for_xp(xp: int) -> int:
	return level_for_xp(xp) * maxi(0, units_per_level)


func xp_for_score(score: int, multiplier := 1.0) -> int:
	return maxi(0, floori(float(maxi(0, score)) * maxf(0.0, xp_per_score) * maxf(1.0, multiplier)))


func stars_for_score(score: int) -> int:
	var stars := 1
	for index in star_thresholds.size():
		if score >= star_thresholds[index]:
			stars = index + 1
	return clampi(stars, 1, 5)
