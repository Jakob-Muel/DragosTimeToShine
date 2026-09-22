class_name ProceduralDragonTextures
extends Node

## One seed -> the same dragon in every view. Render once on demand, then retain
## ordinary textures; no permanent offscreen viewports or per-frame readbacks.
const VIEWS := preload("res://scripts/ui/dragon_views.gd")
static var _instance: ProceduralDragonTextures
static var _textures: Dictionary = {}
static var pending_renders := 0

static func seed_for(dragon: Dictionary) -> int:
	if int(dragon.get("appearance_seed",0)) > 0:
		return int(dragon["appearance_seed"])
	# Stable migration for existing saves, independent of array order or locale.
	var identity := String(dragon.get("id", "luma"))
	var value := 5381
	for byte in identity.to_utf8_buffer():
		value = (value * 33 + byte) % 2147483647
	return maxi(1,value)

static func texture_for(seed: int, pose := "portrait") -> Texture2D:
	var key := "%d:%s" % [seed,pose]
	if _textures.has(key):
		return _textures[key]
	var placeholder := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	placeholder.fill(Color.TRANSPARENT)
	if DisplayServer.get_name() == "headless":
		placeholder = (load("res://assets/art/current_dragon.png") as Texture2D).get_image()
	var texture := ImageTexture.create_from_image(placeholder)
	texture.set_meta("dragon_seed",seed)
	texture.set_meta("dragon_pose",pose)
	texture.set_meta("procedural_ready",false)
	_textures[key] = texture
	# A headless backend cannot draw. Logic tests use the placeholder; the render
	# regression verifies the real views with a graphics device.
	if DisplayServer.get_name() == "headless":
		return texture
	if not is_instance_valid(_instance):
		_instance = ProceduralDragonTextures.new()
		_instance.name = "ProceduralDragonTextureCache"
		(Engine.get_main_loop() as SceneTree).root.call_deferred("add_child",_instance)
	pending_renders += 1
	_instance.call_deferred("_render",texture,seed,pose)
	return texture

func _render(texture: ImageTexture, seed: int, pose: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640,720) if pose == "portrait" else (Vector2i(640,440) if pose == "flight" else Vector2i(480,540))
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var dragon := VIEWS.new()
	dragon.dragon_seed = seed
	dragon.view_pose = pose
	dragon.animate = false
	dragon.size = viewport.size
	viewport.add_child(dragon)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	image.generate_mipmaps()
	texture.set_meta("procedural_ready",true)
	texture.set_image(image)
	viewport.queue_free()
	pending_renders -= 1
