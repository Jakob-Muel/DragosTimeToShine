class_name WidgetFactory
extends RefCounted

const PIXEL_ART := preload("res://scripts/ui/pixel_art.gd")


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
	result.text = text_value
	result.position = rect.position
	result.size = rect.size
	result.focus_mode = Control.FOCUS_NONE
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.add_theme_font_override("font", UiTokens.FONT_BOLD)
	result.add_theme_font_size_override("font_size", 31)
	result.add_theme_color_override("font_color", UiTokens.WHITE)
	result.add_theme_color_override("font_hover_color", UiTokens.WHITE)
	result.add_theme_color_override("font_pressed_color", UiTokens.WHITE)
	result.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.72))
	result.clip_text = true
	result.add_theme_stylebox_override(
		"normal",
		panel_style(color, color.darkened(0.28), 16, 7, Color(shadow_color, 0.34))
	)
	result.add_theme_stylebox_override(
		"hover",
		panel_style(
			color.lightened(0.06),
			color.darkened(0.22),
			16,
			8,
			Color(shadow_color, 0.34)
		)
	)
	result.add_theme_stylebox_override(
		"pressed",
		panel_style(
			color.darkened(0.06),
			color.darkened(0.30),
			16,
			2,
			Color(shadow_color, 0.28)
		)
	)
	result.add_theme_stylebox_override(
		"disabled",
		panel_style(
			color.lerp(UiTokens.INK_SOFT, 0.42).darkened(0.06),
			color.lerp(UiTokens.INK_SOFT, 0.58).darkened(0.20),
			16,
			4,
			Color(shadow_color, 0.22)
		)
	)
	return result


static func small_button(text_value: String, rect: Rect2, color: Color) -> Button:
	var result := Button.new()
	result.text = text_value
	result.position = rect.position
	result.size = rect.size
	result.focus_mode = Control.FOCUS_NONE
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.add_theme_font_override("font", UiTokens.FONT_BOLD)
	result.add_theme_font_size_override("font_size", 38)
	result.add_theme_color_override("font_color", UiTokens.INK)
	result.add_theme_stylebox_override(
		"normal",
		panel_style(color, UiTokens.CREAM_DEEP.darkened(0.34), 14, 5)
	)
	result.add_theme_stylebox_override(
		"hover",
		panel_style(color.lightened(0.06), UiTokens.PINK_DARK, 14, 6)
	)
	result.add_theme_stylebox_override(
		"pressed",
		panel_style(color.darkened(0.05), UiTokens.INK_SOFT, 14, 2)
	)
	return result


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


static func add_button_caption(target: Button, caption: String) -> void:
	var title_text := target.text
	target.text = ""

	var title := label(
		title_text,
		30,
		UiTokens.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	var content_height := 68.0
	var content_top := floorf(maxf(8.0, (target.size.y - content_height) * 0.5))
	title.position = Vector2(14, content_top)
	title.size = Vector2(maxf(0.0, target.size.x - 28.0), 42)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	target.add_child(title)

	var caption_label := label(
		caption,
		18,
		Color(1.0, 0.98, 0.94, 0.98),
		HORIZONTAL_ALIGNMENT_CENTER,
		UiTokens.FONT_BOLD
	)
	caption_label.position = Vector2(14, content_top + 40.0)
	caption_label.size = Vector2(maxf(0.0, target.size.x - 28.0), 28)
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
