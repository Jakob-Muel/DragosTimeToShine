class_name CollectionService
extends RefCounted

var catalog: GameCatalog


func _init(game_catalog: GameCatalog) -> void:
	catalog = game_catalog


func owns_definition(dragons: Array[Dictionary], definition_id: StringName) -> bool:
	for dragon: Dictionary in dragons:
		if StringName(String(dragon.get("definition_id", ""))) == definition_id:
			return true
	return false


func has_pending_definition(eggs: Array[Dictionary], definition_id: StringName) -> bool:
	for egg: Dictionary in eggs:
		if StringName(String(egg.get("definition_id", ""))) == definition_id:
			return true
	return false


func next_unowned_egg(
	egg_kind: StringName,
	dragons: Array[Dictionary],
	eggs: Array[Dictionary]
) -> StringName:
	for definition_id: StringName in catalog.egg_candidates(egg_kind):
		if not owns_definition(dragons, definition_id) and not has_pending_definition(eggs, definition_id):
			return definition_id
	return StringName()
