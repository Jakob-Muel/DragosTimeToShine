class_name GameCatalog
extends RefCounted

const DRAGON_DEFINITIONS := [
	preload("res://data/dragons/luma.tres"),
	preload("res://data/dragons/nova.tres"),
	preload("res://data/dragons/frost.tres"),
	preload("res://data/dragons/ember.tres"),
	preload("res://data/dragons/marina.tres"),
	preload("res://data/dragons/terra.tres"),
	preload("res://data/dragons/voltara.tres"),
	preload("res://data/dragons/lavara.tres"),
	preload("res://data/dragons/mudara.tres"),
]
const TRAINING_DEFINITIONS := [
	preload("res://data/training/flight.tres"),
]
const FUSION_RECIPES := [
	preload("res://data/fusion/ember_marina.tres"),
	preload("res://data/fusion/ember_terra.tres"),
	preload("res://data/fusion/marina_terra.tres"),
]

var _dragons: Dictionary = {}
var _training_categories: Dictionary = {}
var _fusion_recipes: Dictionary = {}


func _init() -> void:
	for definition: DragonDefinition in DRAGON_DEFINITIONS:
		register_dragon(definition)
	for definition: TrainingCategoryDefinition in TRAINING_DEFINITIONS:
		register_training_category(definition)
	for recipe: FusionRecipe in FUSION_RECIPES:
		register_fusion_recipe(recipe)


func register_dragon(definition: DragonDefinition) -> void:
	if definition == null or definition.id.is_empty():
		return
	_dragons[definition.id] = definition


func get_dragon(definition_id: StringName) -> DragonDefinition:
	return _dragons.get(definition_id) as DragonDefinition


func has_dragon(definition_id: StringName) -> bool:
	return _dragons.has(definition_id)


func egg_candidates(egg_kind: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	for definition: DragonDefinition in _dragons.values():
		if definition.egg_kind == egg_kind:
			result.append(definition.id)
	result.sort()
	return result


func resolve_legacy_dragon(dragon: Dictionary) -> StringName:
	var existing := StringName(String(dragon.get("definition_id", "")))
	if has_dragon(existing):
		return existing
	if bool(dragon.get("starter", false)) or String(dragon.get("id", "")) == "luma":
		return &"luma"
	match String(dragon.get("species", "sunwing")):
		"ice":
			return &"frost"
		"fire":
			return &"ember"
		"water":
			return &"marina"
		"earth":
			return &"terra"
	return &"nova"


func resolve_legacy_egg(egg: Dictionary) -> StringName:
	var existing := StringName(String(egg.get("definition_id", "")))
	if has_dragon(existing):
		return existing
	var candidates := egg_candidates(StringName(String(egg.get("kind", "sunwing"))))
	return candidates[0] if not candidates.is_empty() else StringName()


func register_training_category(definition: TrainingCategoryDefinition) -> void:
	if definition == null or definition.id.is_empty():
		return
	_training_categories[definition.id] = definition


func get_training_category(category_id: StringName) -> TrainingCategoryDefinition:
	return _training_categories.get(category_id) as TrainingCategoryDefinition


func register_fusion_recipe(recipe: FusionRecipe) -> void:
	if recipe == null or recipe.result.is_empty():
		return
	_fusion_recipes[recipe.pair_key()] = recipe


func get_fusion_recipe(first: StringName, second: StringName) -> FusionRecipe:
	return _fusion_recipes.get(FusionRecipe.make_pair_key(first, second)) as FusionRecipe
