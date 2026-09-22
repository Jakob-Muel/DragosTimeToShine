class_name FlightPillar
extends Control

## An inked, softly shaded ruin. The curved gap-facing cap stays within the
## original obstacle bounds, so the fair inner hitbox is unchanged.
const NATURAL_PEAK_HEIGHT := 86.0
var flip_vertical := false
var variant := 0
var _art: ImageTexture
var _art_size := Vector2.ZERO

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	if size.x < 1 or size.y < 1:
		return
	if _art == null or _art_size != size:
		_rebuild()
	if flip_vertical:
		draw_set_transform(Vector2(0, size.y), 0, Vector2(1, -1))
	draw_texture_rect(_art, Rect2(Vector2.ZERO, size), false)
	draw_set_transform(Vector2.ZERO)

func _rebuild() -> void:
	_art_size = size
	var h := size.y
	var light: String = ["#c1aaa5", "#b5acc2", "#cfb998"][variant % 3]
	var shade: String = ["#796b80", "#736982", "#897776"][variant % 3]
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="118" height="%s" viewBox="0 0 118 %s"><defs><linearGradient id="stone"><stop stop-color="%s"/><stop offset=".35" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient></defs>' % [h, h, light, light, shade]
	svg += '<path d="M 15 -5 L 103 -5 L 105 %s Q 117 %s 112 %s Q 99 %s 82 %s Q 59 %s 43 %s Q 16 %s 6 %s Q 1 %s 13 %s Z" fill="url(#stone)" stroke="#382b3d" stroke-width="4" stroke-linejoin="round"/>' % [h-74, h-67, h-24, h-7, h-14, h-4, h-12, h-4, h-24, h-64, h-74]
	for row in range(ceili(h / 72.0)):
		var y := row * 72.0 + 22.0
		if y > h - 65:
			break
		var split := 43.0 + float((row + variant) % 3) * 13.0
		svg += '<path d="M 16 %s Q 61 %s 101 %s M %s %s L %s %s L %s %s" fill="none" stroke="#67586f" stroke-width="2.5" stroke-linecap="round"/>' % [y, y+7, y-1, split, y+4, split-6, y+26, split+1, y+39]
		svg += '<path d="M 24 %s Q 43 %s 59 %s" fill="none" stroke="#eee0c9" stroke-width="3" opacity=".55" stroke-linecap="round"/>' % [y+13, y+17, y+13]
		if row % 3 == 1:
			svg += '<path d="M 79 %s L 72 %s L 79 %s L 89 %s L 86 %s Z" fill="#d69ab9" stroke="#67586f" stroke-width="2"/><path d="M 79 %s L 81 %s" stroke="#ffe4ed" stroke-width="2"/>' % [y+48,y+31,y+17,y+32,y+46,y+23,y+41]
	svg += '<path d="M 12 %s Q 48 %s 105 %s" fill="none" stroke="#ead9bd" stroke-width="5" stroke-linecap="round"/>' % [h-43,h-29,h-43]
	svg += '</svg>'
	var image := Image.new()
	assert(image.load_svg_from_string(svg, 2.0) == OK)
	_art = ImageTexture.create_from_image(image)
