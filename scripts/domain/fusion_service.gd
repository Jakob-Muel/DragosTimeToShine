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
	var first_definition := StringName(String(first.get("definition_id", "")))
	var second_definition := StringName(String(second.get("definition_id", "")))
	var recipe := catalog.get_fusion_recipe(first_definition, second_definition)
	if recipe == null:
		return &"no_recipe"
	if collection.owns_definition(owned_dragons, recipe.result):
		return &"already_owned"
	if fusion_stars < recipe.fusion_star_cost:
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
	return recipe.result if recipe != null else StringName()
