class_name TrainingCategoryDefinition
extends Resource

@export var id: StringName
@export var xp_per_level := 10
@export var contest_level := 5
@export var units_per_level := 10
@export var gold_reward := 1


func level_for_xp(xp: int) -> int:
	return maxi(0, xp) / maxi(1, xp_per_level)


func contest_value_for_xp(xp: int) -> int:
	return level_for_xp(xp) * maxi(0, units_per_level)
