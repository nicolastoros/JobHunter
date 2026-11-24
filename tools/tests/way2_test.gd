extends SceneTree
var out := ""
func _initialize() -> void:
	out = OS.get_environment("CAPTURE_DIR")
	_run.call_deferred()
func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(n + ".png"))
func _p() -> Node2D:
	return current_scene.get_node("Entities/Player")
func _key(a: String) -> void:
	var e := InputEventAction.new(); e.action = a; e.pressed = true; Input.parse_input_event(e)
	await create_timer(0.1, true, false, true).timeout
	var r := InputEventAction.new(); r.action = a; r.pressed = false; Input.parse_input_event(r)
	await create_timer(0.3, true, false, true).timeout
func _click(pos: Vector2) -> void:
	# pos in canvas units -> window pixels
	var s := Vector2(root.size) / root.get_visible_rect().size
	for pressed in [true, false]:
		var m := InputEventMouseButton.new()
		m.button_index = MOUSE_BUTTON_LEFT
		m.pressed = pressed
		m.position = pos * s
		m.global_position = pos * s
		Input.parse_input_event(m)
		await create_timer(0.08, true, false, true).timeout
func _run() -> void:
	var game = root.get_node("Game")
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 30
	game.recalc_stats()
	game.daily = game._fresh_daily(); game.daily["day"] = game.today_key()
	game.pending_spawn = "start"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.5).timeout
	var camp: Node2D = null
	for s in get_nodes_in_group("waystones"):
		if s.stone_id == "camp": camp = s
	# walk up to the stone like a player: stand below it, press E for real
	_p().global_position = camp.global_position + Vector2(0, 22); _p().reset_physics_interpolation(); _p().get_node("Camera2D").reset_smoothing()
	_p()._invulnerable = 999.0
	await create_timer(0.5).timeout
	print("focused ", _p()._focused == camp)
	await _key("interact")
	await create_timer(0.8).timeout
	print("E woke the stone: ", game.is_waystone_unlocked("camp"))
	game.waystones_unlocked["oasis"] = true; game.waystones_unlocked["aurelia"] = true
	for m in ["desert.tscn", "aurelia.tscn"]: game.visited_maps[m] = true
	await _key("interact")
	await create_timer(0.4, true, false, true).timeout
	print("E opened the travel menu: ", game.menu_open)
	await _key("ui_cancel")
	await create_timer(0.3).timeout
	# world map: click the oasis stone
	await _key("world_map")
	await create_timer(0.4, true, false, true).timeout
	var wm = null
	for c in game.get_children():
		if c.get_script() and String(c.get_script().resource_path).ends_with("world_map.gd"): wm = c
	var btn: Button = null
	for b in wm._stone_buttons.get_children():
		if b.tooltip_text.contains("Oasis"): btn = b
	print("stone buttons on the map ", wm._stone_buttons.get_child_count())
	wm._hover = "oasis"
	await create_timer(0.2, true, false, true).timeout
	await _shot("w2_worldmap_hover")
	await _click(btn.get_global_rect().get_center())
	await create_timer(2.2).timeout
	print("after click: ", current_scene.scene_file_path.get_file(), " near oasis stone ", _p().global_position.distance_to(get_nodes_in_group("waystones").filter(func(s): return s.stone_id == "oasis")[0].global_position) < 40, " paused ", paused)
	await _shot("w2_arrived")
	quit()
