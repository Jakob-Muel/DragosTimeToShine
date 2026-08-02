class_name FusionRecipe
extends Resource

@export var parent_a: StringName
@export var parent_b: StringName
@export var result: StringName
@export var fusion_star_cost := 1


func pair_key() -> String:
	return FusionRecipe.make_pair_key(parent_a, parent_b)


static func make_pair_key(first: StringName, second: StringName) -> String:
	var ordered := [String(first), String(second)]
	ordered.sort()
	return "%s+%s" % ordered
