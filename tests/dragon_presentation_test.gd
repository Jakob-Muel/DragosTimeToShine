extends SceneTree

const DRAGON_PRESENTATION := preload("res://scripts/ui/dragon_presentation.gd")
const DRAGON_TEXTURES := [
	preload("res://assets/art/dragon_pink_hd.png"),
	preload("res://assets/art/fire/fire_dragon_hd.png"),
	preload("res://assets/art/water/water_dragon_hd.png"),
	preload("res://assets/art/earth/earth_dragon_hd.png"),
	preload("res://assets/art/ice/ice_dragon_alpha.png"),
	preload("res://assets/art/fusion/lava/lavara_dragon_hd.png"),
	preload("res://assets/art/fusion/mud/mudara_dragon_hd.png"),
	preload("res://assets/art/fusion/voltara_dragon_hd.png"),
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for texture in DRAGON_TEXTURES:
		_assert_shadow_tracks_visible_feet(texture)
	print("Dragon presentation test: valid")
	quit()


func _assert_shadow_tracks_visible_feet(texture: Texture2D) -> void:
	var presentation: Control = DRAGON_PRESENTATION.new()
	presentation.size = Vector2(250, 224)
	presentation.call("configure", texture, CanvasItem.TEXTURE_FILTER_NEAREST)
	root.add_child(presentation)

	var shadow: Control = presentation.get("shadow")
	assert(shadow != null and shadow.visible, "Every standing dragon must have a shared shadow.")
	var bounds := texture.get_image().get_used_rect()
	assert(bounds.size.x > 0 and bounds.size.y > 0, "Dragon art must have visible pixels.")
	assert(
		bounds != Rect2i(0, 0, texture.get_width(), texture.get_height()),
		"Standing dragon art must have a transparent perimeter: %s." % texture.resource_path
	)
	var texture_size := Vector2(texture.get_width(), texture.get_height())
	var scale_factor := minf(presentation.size.x / texture_size.x, presentation.size.y / texture_size.y)
	var displayed_size := texture_size * scale_factor
	var display_origin := (presentation.size - displayed_size) * 0.5
	var visible_feet_y := display_origin.y + float(bounds.end.y) * scale_factor
	var shadow_center_y := shadow.position.y + shadow.size.y * 0.5
	assert(
		absf(shadow_center_y - visible_feet_y) <= 1.1,
		"Shadow center must follow the visible feet for %s." % texture.resource_path
	)
	assert(
		shadow.position.y < visible_feet_y and shadow.position.y + shadow.size.y > visible_feet_y,
		"Visible feet must overlap the ground shadow for %s." % texture.resource_path
	)
	presentation.free()
