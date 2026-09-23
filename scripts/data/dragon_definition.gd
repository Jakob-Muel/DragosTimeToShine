class_name DragonDefinition
extends Resource

@export var id: StringName
@export var name_key: StringName
@export var types: Array[StringName] = []
@export var egg_kind: StringName
@export var egg_name_key: StringName
@export var hatch_message_key: StringName
@export var level_species_key: StringName
@export_file("*.png") var egg_texture_path := ""
@export_file("*.png") var dragon_texture_path := ""
@export_file("*.png") var island_texture_path := ""
@export_file("*.png") var flight_texture_path := ""


func has_type(type_id: StringName) -> bool:
	return types.has(type_id)
