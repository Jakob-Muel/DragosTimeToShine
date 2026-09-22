extends GameScreen

func build() -> void:
	var dragon_id := String(context.get("selected_dragon_id", "luma"))
	var top := safe_top_y(32)
	var back := WidgetFactory.small_button("‹", Rect2(28, top, 80, 72), UiTokens.CREAM)
	back.pressed.connect(navigate.bind("habitat", {"selected_dragon_id": dragon_id}))
	add_child(back)
	var title := WidgetFactory.label(tr_text("ATTRIBUTES_TITLE"), 34, UiTokens.INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(115, top)
	title.size = Vector2(575, 72)
	add_child(title)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(28, top + 100)
	scroll.size = Vector2(664, safe_bottom_y() - top - 100)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var content := VBoxContainer.new()
	content.custom_minimum_size.x = 640
	content.add_theme_constant_override("separation", 18)
	scroll.add_child(content)
	var hint := WidgetFactory.label(tr_text("ATTRIBUTES_HINT"), 23, UiTokens.INK)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(640, 100)
	content.add_child(hint)
	var stats := GameState.dragon_attributes(dragon_id)
	for id: String in GameState.ATTRIBUTES.IDS:
		var stat: Dictionary = stats.get(id, {})
		if stat.is_empty():
			continue
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		content.add_child(row)
		row.add_child(WidgetFactory.label(tr_text("ATTR_" + id.to_upper()), 29, UiTokens.INK))
		row.add_child(WidgetFactory.label(tr_text("ATTRIBUTE_VALUE", {"value": stat.value, "potential": stat.potential}), 25, UiTokens.INK_SOFT))
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(620, 32)
		bar.max_value = stat.potential
		bar.value = stat.value
		bar.show_percentage = false
		row.add_child(bar)
		var train := WidgetFactory.button(tr_text("ATTRIBUTE_MAX") if stat.value >= stat.potential else tr_text("ATTRIBUTE_TRAIN"), Rect2(0, 0, 620, 80), UiTokens.PINK, UiTokens.PINK_DARK)
		train.custom_minimum_size = Vector2(620, 80)
		train.disabled = stat.value >= stat.potential
		train.pressed.connect(navigate.bind("training_session", {
			"dragon_id": dragon_id, "attribute_id": id, "return_route": "attributes",
			"talent_id": "flight" if id == "movement_speed" else "element_power",
		}))
		row.add_child(train)
