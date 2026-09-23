extends SceneTree
const VIEWS := preload("res://scripts/ui/dragon_views.gd")
func _init() -> void:
	call_deferred("_capture")
func _capture() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1480,1060)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var paper := ColorRect.new()
	paper.color = Color("#edf0e6")
	paper.size = viewport.size
	viewport.add_child(paper)
	var seeds := [34,37,2,77]
	for index in 4:
		var card := Panel.new()
		card.position = Vector2(16+index*368,16)
		card.size = Vector2(352,1028)
		card.add_theme_stylebox_override("panel",WidgetFactory.panel_style(UiTokens.CREAM,UiTokens.INK,20,4))
		paper.add_child(card)
		var title := WidgetFactory.label("SEED %d" % seeds[index],24,UiTokens.INK)
		title.position = Vector2(0,10)
		title.size = Vector2(352,40)
		card.add_child(title)
		var positions := [Vector2(16,55),Vector2(16,450),Vector2(75,690)]
		var sizes := [Vector2(320,360),Vector2(320,220),Vector2(200,225)]
		for pose_index in 3:
			var dragon := VIEWS.new()
			dragon.animate = false
			dragon.dragon_seed = seeds[index]
			dragon.view_pose = ["portrait","flight","overhead"][pose_index]
			dragon.position = positions[pose_index]
			dragon.size = sizes[pose_index]
			card.add_child(dragon)
		var tiny := VIEWS.new()
		tiny.animate = false
		tiny.dragon_seed = seeds[index]
		tiny.view_pose = "flight"
		tiny.position = Vector2(102,930)
		tiny.size = Vector2(148,88)
		card.add_child(tiny)
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	assert(viewport.get_texture().get_image().save_png("res://docs/screenshots/unified/dragon_views.png") == OK)
	print("Captured unified views")
	quit()
