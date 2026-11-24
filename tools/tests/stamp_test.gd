extends SceneTree
var out := ""
func _initialize() -> void:
	out = OS.get_environment("CAPTURE_DIR")
	_run.call_deferred()
func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(n + ".png"))
func _run() -> void:
	var game = root.get_node("Game")
	change_scene_to_file("res://scenes/ui/main_menu.tscn")
	await create_timer(0.5).timeout
	game.start_editor()
	await create_timer(2.5).timeout
	var ed = root.get_node_or_null("MapEditor")
	ed._set_tool("paint")
	# pick the "fence horizontal" stamp
	var idx := -1
	for i in ed._stamp_opt.item_count:
		if ed._stamp_opt.get_item_text(i).begins_with("Valla de madera · horizontal"):
			idx = i
	ed._stamp_opt.select(idx)
	ed._on_stamp_selected(idx)
	print("stamp layer ", ed.paint_layer.name, " src ", ed.paint_source, " coords ", ed.paint_coords, " size ", ed.paint_size)
	ed.cam.global_position = Vector2(1432, 1000)
	ed.cam.zoom = Vector2(4, 4)
	await create_timer(0.3).timeout
	ed.mouse_over_world = true
	# a drag from cell (86,62) to (93,62) repeats the 2-tile pattern
	ed._stamp_anchor = Vector2i(86, 62)
	for x in range(86, 94):
		ed._paint_at(Vector2(x * 16 + 8, 62 * 16 + 8), false)
	ed._end_stroke()
	var row := []
	for x in range(86, 94):
		row.append(ed.paint_layer.get_cell_atlas_coords(Vector2i(x, 62)).x)
	print("fence row atlas x: ", row)
	# dock stamp, single click
	for i in ed._stamp_opt.item_count:
		if ed._stamp_opt.get_item_text(i).begins_with("Muelle · tablones"):
			idx = i
	ed._on_stamp_selected(idx)
	ed._stamp_anchor = Vector2i(86, 64)
	ed._paint_at(Vector2(86 * 16 + 8, 64 * 16 + 8), false)
	ed._end_stroke()
	print("dock cell (92,67): ", ed.paint_layer.get_cell_atlas_coords(Vector2i(92, 67)), " layer ", ed.paint_layer.name)
	# palette drag selection
	ed._set_atlas_rect(Vector2i(3, 2), Vector2i(1, 4))
	print("palette rect ", ed.paint_coords, " size ", ed.paint_size)
	ed._on_stamp_selected(idx)
	await create_timer(0.3).timeout
	await _shot("s01_stamps")
	print("undo entries ", ed._undo.size())
	ed._undo_last(); ed._undo_last()
	print("after undo fence (87,62) src ", ed._layer_named("Fence").get_cell_source_id(Vector2i(87, 62)))
	quit()
