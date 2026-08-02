class_name DragonPresentation
extends Control

## Shared static-dragon presenter. It derives the ground contact from the texture's
## visible alpha bounds, so transparent padding cannot move the shadow away from feet.

const PIXEL_ART := preload("res://scripts/ui/pixel_art.gd")
const SHADOW_WIDTH_RATIO := 0.60
const SHADOW_HEIGHT_RATIO := 0.24
const SHADOW_VERTICAL_OFFSET := 1.0

static var _visible_bounds_cache: Dictionary = {}

var sprite: TextureRect
var shadow: Control
var _texture: Texture2D
var _texture_filter := CanvasItem.TEXTURE_FILTER_LINEAR
var _bounce_height := 0.0


func configure(
	texture_value: Texture2D,
	filter_value := CanvasItem.TEXTURE_FILTER_LINEAR
) -> void:
	_texture = texture_value
	_texture_filter = filter_value
	_ensure_children()
	sprite.texture = _texture
	sprite.texture_filter = _texture_filter
	_layout_presentation()


func set_bounce(height: float) -> void:
	_bounce_height = maxf(0.0, height)
	if is_instance_valid(sprite):
		sprite.position = Vector2(0, -_bounce_height)
	if is_instance_valid(shadow):
		shadow.set("squish", clampf(1.0 - _bounce_height / 55.0, 0.55, 1.0))


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	resized.connect(_layout_presentation)
	_ensure_children()
	_layout_presentation()


func _ensure_children() -> void:
	if not is_instance_valid(shadow):
		shadow = PIXEL_ART.BlobShadow.new()
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shadow)
	if not is_instance_valid(sprite):
		sprite = TextureRect.new()
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sprite)


func _layout_presentation() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_ensure_children()
	sprite.position = Vector2(0, -_bounce_height)
	sprite.size = size
	if _texture == null or _texture.get_width() <= 0 or _texture.get_height() <= 0:
		shadow.visible = false
		return

	shadow.visible = true
	var texture_size := Vector2(_texture.get_width(), _texture.get_height())
	var display_scale := minf(size.x / texture_size.x, size.y / texture_size.y)
	var displayed_size := texture_size * display_scale
	var display_origin := (size - displayed_size) * 0.5
	var visible_bounds := _visible_texture_bounds(_texture)
	var feet_y := display_origin.y + float(visible_bounds.end.y) * display_scale
	var shadow_width := size.x * SHADOW_WIDTH_RATIO
	var shadow_height := shadow_width * SHADOW_HEIGHT_RATIO
	shadow.position = Vector2(
		(size.x - shadow_width) * 0.5,
		feet_y - shadow_height * 0.5 + SHADOW_VERTICAL_OFFSET
	)
	shadow.size = Vector2(shadow_width, shadow_height)


static func _visible_texture_bounds(texture: Texture2D) -> Rect2i:
	var cache_key := texture.resource_path
	if cache_key.is_empty():
		cache_key = str(texture.get_instance_id())
	if _visible_bounds_cache.has(cache_key):
		return _visible_bounds_cache[cache_key]
	var image := texture.get_image()
	var bounds := image.get_used_rect() if image != null and not image.is_empty() else Rect2i()
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		bounds = Rect2i(0, 0, texture.get_width(), texture.get_height())
	_visible_bounds_cache[cache_key] = bounds
	return bounds
