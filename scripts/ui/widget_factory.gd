class_name WidgetFactory
extends RefCounted

const PIXEL_ART := preload("res://scripts/ui/pixel_art.gd")
const DRAGON_PRESENTATION := preload("res://scripts/ui/dragon_presentation.gd")
const BUTTON_TEXTURE_MARGIN := 30.0
const BUTTON_TEXTURES := {
	"pink": {
		"idle": preload("res://assets/art/ui_redesign/buttons/pink_idle.png"),
		"pressed": preload("res://assets/art/ui_redesign/buttons/pink_pressed.png"),
	},
	"green": {
		"idle": preload("res://assets/art/ui_redesign/buttons/green_idle.png"),
		"pressed": preload("res://assets/art/ui_redesign/buttons/green_pressed.png"),
	},
	"gold": {
		"idle": preload("res://assets/art/ui_redesign/buttons/gold_idle.png"),
		"pressed": preload("res://assets/art/ui_redesign/buttons/gold_pressed.png"),
	},
	"cream": {
		"idle": preload("res://assets/art/ui_redesign/buttons/cream_idle.png"),
		"pressed": preload("res://assets/art/ui_redesign/buttons/cream_pressed.png"),
	},
	"lilac": {
		"idle": preload("res://assets/art/ui_redesign/buttons/lilac_idle.png"),
		"pressed": preload("res://assets/art/ui_redesign/buttons/lilac_pressed.png"),
	},
	"sky": {
		"idle": preload("res://assets/art/ui_redesign/buttons/sky_idle.png"),
		"pressed": preload("res://assets/art/ui_redesign/buttons/sky_pressed.png"),
	},
}
const BUTTON_VARIANT_COLORS := {
	"pink": Color("#e75d91"),
	"green": Color("#4f956c"),
	"gold": Color("#e9aa46"),
	"cream": Color("#f3d9ae"),
	"lilac": Color("#9a78b3"),
	"sky": Color("#78d6ed"),
}


static func texture_rect(
	texture: Texture2D,
	rect: Rect2,
	stretch: TextureRect.StretchMode
) -> TextureRect:
	var result := TextureRect.new()
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = stretch
	result.texture = texture
	result.position = rect.position
	result.size = rect.size
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


static func pixel_icon(texture: Texture2D, rect: Rect2) -> TextureRect:
	var result := texture_rect(texture, rect, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.pivot_offset = rect.size / 2.0
	return result


static func dragon_presentation(
	texture: Texture2D,
	rect: Rect2,
	filter := CanvasItem.TEXTURE_FILTER_LINEAR
) -> Control:
	var result := DRAGON_PRESENTATION.new()
	result.position = rect.position
	result.size = rect.size
	result.configure(texture, filter)
	return result


static func label(
	text_value: String,
	font_size: int,
	color: Color,
	alignment := HORIZONTAL_ALIGNMENT_LEFT,
	font: Font = UiTokens.FONT_REGULAR
) -> Label:
	var result := Label.new()
	result.text = text_value
	result.horizontal_alignment = alignment
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.add_theme_font_override("font", font)
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


static func panel_style(
	color: Color,
	border: Color,
	radius: int,
	shadow_size: int = 0,
	shadow_color := Color(0.16, 0.10, 0.20, 0.35)
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	style.corner_detail = 3
	style.shadow_color = shadow_color
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, shadow_size)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


static func button(text_value: String, rect: Rect2, color: Color, shadow_color: Color) -> Button:
	var result := Button.new()
	var variant := _closest_button_variant(color)
	var text_color := _button_text_color(variant)
	result.text = text_value
	result.position = rect.position
	result.size = rect.size
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.focus_mode = Control.FOCUS_NONE
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.add_theme_font_override("font", UiTokens.FONT_BOLD)
	result.add_theme_font_size_override("font_size", 31)
	result.add_theme_color_override("font_color", text_color)
	result.add_theme_color_override("font_hover_color", text_color)
	result.add_theme_color_override("font_pressed_color", text_color)
	result.add_theme_color_override("font_disabled_color", Color(text_color, 0.62))
	result.clip_text = true
	result.add_theme_stylebox_override("normal", _button_texture_style(variant, false))
	result.add_theme_stylebox_override("hover", _button_texture_style(variant, false))
	result.add_theme_stylebox_override("pressed", _button_texture_style(variant, true))
	result.add_theme_stylebox_override("disabled", _button_texture_style(variant, true))
	result.set_meta("ui_button_text_color", text_color)
	result.set_meta("ui_button_shadow_color", shadow_color)
	return result


static func small_button(text_value: String, rect: Rect2, color: Color) -> Button:
	var result := Button.new()
	var variant := _closest_button_variant(color)
	var is_back_button := text_value == "‹"
	var is_settings_button := text_value == "⚙"
	result.text = "" if is_back_button or is_settings_button else text_value
	result.position = rect.position
	result.size = rect.size
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.focus_mode = Control.FOCUS_NONE
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.add_theme_font_override("font", UiTokens.FONT_BOLD)
	result.add_theme_font_size_override("font_size", 38)
	result.add_theme_color_override("font_color", UiTokens.INK)
	result.add_theme_color_override("font_hover_color", UiTokens.INK)
	result.add_theme_color_override("font_pressed_color", UiTokens.INK)
	result.add_theme_stylebox_override("normal", _button_texture_style(variant, false))
	result.add_theme_stylebox_override("hover", _button_texture_style(variant, false))
	result.add_theme_stylebox_override("pressed", _button_texture_style(variant, true))
	if is_back_button:
		var chevron := PIXEL_ART.PixelChevron.new()
		chevron.name = "PixelChevron"
		chevron.size = rect.size
		result.add_child(chevron)
		result.set_meta("ui_small_button_kind", "back")
	elif is_settings_button:
		var gear := PIXEL_ART.PixelGear.new()
		gear.name = "PixelGear"
		gear.size = rect.size
		result.add_child(gear)
		result.set_meta("ui_small_button_kind", "settings")
	return result


static func _button_texture_style(variant: String, pressed: bool) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = BUTTON_TEXTURES[variant]["pressed" if pressed else "idle"]
	style.texture_margin_left = BUTTON_TEXTURE_MARGIN
	style.texture_margin_top = BUTTON_TEXTURE_MARGIN
	style.texture_margin_right = BUTTON_TEXTURE_MARGIN
	style.texture_margin_bottom = BUTTON_TEXTURE_MARGIN
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0 if pressed else 9.0
	style.content_margin_bottom = 9.0 if pressed else 12.0
	return style


static func _closest_button_variant(color: Color) -> String:
	var closest_variant := "pink"
	var closest_distance := INF
	for variant in BUTTON_VARIANT_COLORS:
		var candidate: Color = BUTTON_VARIANT_COLORS[variant]
		var red_delta := color.r - candidate.r
		var green_delta := color.g - candidate.g
		var blue_delta := color.b - candidate.b
		var distance := (
			red_delta * red_delta * 0.2126
			+ green_delta * green_delta * 0.7152
			+ blue_delta * blue_delta * 0.0722
		)
		if distance < closest_distance:
			closest_distance = distance
			closest_variant = variant
	return closest_variant


static func _button_text_color(variant: String) -> Color:
	return UiTokens.INK if variant in ["cream", "gold", "sky"] else UiTokens.WHITE


static func badge(text_value: String, rect: Rect2, color: Color, text_color: Color) -> Panel:
	var result := Panel.new()
	result.position = rect.position
	result.size = rect.size
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_stylebox_override("panel", panel_style(color, UiTokens.INK, 9, 2))
	var text_label := label(text_value, 19, text_color, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD)
	text_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 5)
	result.add_child(text_label)
	return result


static func add_button_caption(
	target: Button,
	caption: String,
	icon_texture: Texture2D = null
) -> void:
	var title_text := target.text
	var text_color: Color = target.get_meta("ui_button_text_color", UiTokens.WHITE)
	target.text = ""
	var text_left := 14.0
	if icon_texture != null:
		var icon_size := minf(72.0, target.size.y - 24.0)
		var icon := pixel_icon(
			icon_texture,
			Rect2(15, (target.size.y - icon_size) * 0.5, icon_size, icon_size)
		)
		target.add_child(icon)
		text_left = 78.0

	var title := label(
		title_text,
		28 if icon_texture != null else 30,
		text_color,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	var content_height := 68.0
	var content_top := floorf(maxf(8.0, (target.size.y - content_height) * 0.5))
	title.position = Vector2(text_left, content_top)
	title.size = Vector2(maxf(0.0, target.size.x - text_left - 12.0), 42)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	target.add_child(title)

	var caption_label := label(
		caption,
		18,
		Color(text_color, 0.88),
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	caption_label.position = Vector2(text_left, content_top + 40.0)
	caption_label.size = Vector2(maxf(0.0, target.size.x - text_left - 12.0), 28)
	caption_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	target.add_child(caption_label)


static func add_resource_pill(
	parent: Control,
	position_value: Vector2,
	amount: int,
	icon_kind: String,
	accent: Color
) -> Panel:
	var pill := Panel.new()
	pill.position = position_value
	pill.size = Vector2(178, 68)
	pill.add_theme_stylebox_override(
		"panel",
		panel_style(Color(1, 0.98, 0.91, 0.96), UiTokens.CREAM_DEEP.darkened(0.35), 22, 4)
	)
	parent.add_child(pill)
	var icon := PIXEL_ART.ResourceIcon.new()
	icon.icon_kind = icon_kind
	icon.position = Vector2(18, 14)
	icon.size = Vector2(38, 40)
	pill.add_child(icon)
	var pill_text := label(str(amount), 28, accent, HORIZONTAL_ALIGNMENT_CENTER, UiTokens.FONT_BOLD)
	pill_text.position = Vector2(57, 0)
	pill_text.size = Vector2(102, 68)
	pill.add_child(pill_text)
	return pill
