class_name FusionService
extends RefCounted

var catalog: GameCatalog
var collection: CollectionService


func _init(game_catalog: GameCatalog, collection_service: CollectionService) -> void:
	catalog = game_catalog
	collection = collection_service


func eligibility_error(
	first: Dictionary,
	second: Dictionary,
	owned_dragons: Array[Dictionary],
	fusion_stars: int
) -> StringName:
	if first.is_empty() or second.is_empty():
		return &"missing_parent"
	if String(first.get("id", "")) == String(second.get("id", "")):
		return &"same_parent"
	if fusion_stars < cost_for(first, second):
		return &"not_enough_stars"
	return StringName()


func can_fuse(
	first: Dictionary,
	second: Dictionary,
	owned_dragons: Array[Dictionary],
	fusion_stars: int
) -> bool:
	return eligibility_error(first, second, owned_dragons, fusion_stars).is_empty()


func result_for(first: Dictionary, second: Dictionary) -> StringName:
	var first_definition := StringName(String(first.get("definition_id", "")))
	var second_definition := StringName(String(second.get("definition_id", "")))
	var recipe := catalog.get_fusion_recipe(first_definition, second_definition)
	return recipe.result if recipe != null else first_definition


func cost_for(first: Dictionary, second: Dictionary) -> int:
	var recipe := catalog.get_fusion_recipe(StringName(first.get("definition_id", "")), StringName(second.get("definition_id", "")))
	return recipe.fusion_star_cost if recipe != null else 1
