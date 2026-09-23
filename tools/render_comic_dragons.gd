extends SceneTree

## Render collection portraits with the same anatomy and lighting as Dragon Lab.
const DRAGON := preload("res://scripts/ui/seeded_dragon.gd")
const PORTRAITS := {
	"dragon_pink_hd.png": [19, 4, 0, 0],
	"fire/fire_dragon_hd.png": [34, 0, 0, 0],
	"water/water_dragon_hd.png": [41, 1, 1, 2],
	"earth/earth_dragon_hd.png": [2, 2, 2, 3],
	"ice/ice_dragon_alpha.png": [37, 6, 1, 1],
	"fusion/voltara_dragon_hd.png": [77, 3, 1, 1],
	"fusion/lava/lavara_dragon_hd.png": [51, 0, 2, 4],
	"fusion/mud/mudara_dragon_hd.png": [83, 2, 0, 3],
}

func _init() -> void:
	call_deferred("_render")

func _render() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 720)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for relative: String in PORTRAITS:
		var traits: Array = PORTRAITS[relative]
		var dragon := DRAGON.new()
		dragon.animate = false
		dragon.dragon_seed = traits[0]
		dragon.size = viewport.size
		viewport.add_child(dragon)
		dragon.appearance["palette"] = traits[1]
		dragon.appearance["body"] = traits[2]
		dragon.appearance["horns"] = traits[3]
		dragon.appearance["rare"] = false
		dragon.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var output := "res://assets/art/comic/" + relative
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
		assert(viewport.get_texture().get_image().save_png(output) == OK)
		dragon.queue_free()
		await process_frame
	print("Rendered ", PORTRAITS.size(), " collection portraits")
	quit()
