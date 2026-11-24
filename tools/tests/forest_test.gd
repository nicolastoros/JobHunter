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
func _run() -> void:
	var game = root.get_node("Game")
	# loading screen
	var t0 := Time.get_ticks_msec()
	change_scene_to_file("res://scenes/ui/loading.tscn")
	await create_timer(0.4).timeout
	await _shot("f00_loading")
	while current_scene == null or current_scene.name != "MainMenu" and Time.get_ticks_msec() - t0 < 60000:
		await process_frame
	print("loading -> ", current_scene.name, " in ", Time.get_ticks_msec() - t0, " ms, preloaded ", game.preloaded.size())
	await create_timer(0.8).timeout
	# hunters of the day
	var names := {}
	for m in ["field.tscn", "forest.tscn", "world.tscn"]:
		var r: Array = game.hunters_today(m)
		var ns := []
		for h in r: ns.append(h["name"])
		print("today ", m, " ", ns)
		for n in ns: names[n] = int(names.get(n, 0)) + 1
	print("no duplicates: ", names.values().max() == 1)
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 20
	# town
	var t1 := Time.get_ticks_msec()
	change_scene_to_file("res://scenes/world/world.tscn")
	await process_frame
	print("world instanced in ", Time.get_ticks_msec() - t1, " ms")
	await create_timer(2.0).timeout
	print("town hunters ", get_nodes_in_group("hunters").size(), " director ", current_scene.get_node_or_null("EventDirector") != null)
	var h0: Node2D = get_nodes_in_group("hunters")[0]
	print("  ", h0.hunter_name, " role ", h0.role, " line '", h0.line, "'")
	# field -> forest through the north trail
	game.pending_spawn = "north"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.5).timeout
	print("field north spawn ", _p().global_position)
	await _shot("f01_field_north")
	_p()._invulnerable = 9999.0
	Input.action_press("move_up")
	await create_timer(1.6).timeout
	Input.action_release("move_up")
	await create_timer(1.5).timeout
	print("after walking north: ", current_scene.scene_file_path.get_file(), " pos ", _p().global_position)
	await create_timer(1.0).timeout
	await _shot("f02_forest_entry")
	var by := {}
	for m in get_nodes_in_group("monsters"):
		by[m.monster_name] = int(by.get(m.monster_name, 0)) + 1
	print("forest monsters ", by, " hunters ", get_nodes_in_group("hunters").size(), " chests ", get_nodes_in_group("chests").size())
	game.inventory["pocion"] = 0
	await create_timer(1.2).timeout
	print("outpost safe ", game.is_safe_here(), " potions ", game.item_count("pocion"))
	_p().global_position = Vector2(80 * 16, 42 * 16); _p().reset_physics_interpolation(); _p().get_node("Camera2D").reset_smoothing()
	await create_timer(1.2).timeout
	await _shot("f03_heart")
	_p().global_position = Vector2(30 * 16, 30 * 16); _p().reset_physics_interpolation(); _p().get_node("Camera2D").reset_smoothing()
	await create_timer(1.2).timeout
	await _shot("f04_crystal")
	_p().global_position = Vector2(118 * 16, 30 * 16); _p().reset_physics_interpolation(); _p().get_node("Camera2D").reset_smoothing()
	await create_timer(1.2).timeout
	await _shot("f05_marsh")
	var e := InputEventAction.new(); e.action = "map"; e.pressed = true; Input.parse_input_event(e)
	await create_timer(0.1).timeout
	var r := InputEventAction.new(); r.action = "map"; r.pressed = false; Input.parse_input_event(r)
	await create_timer(0.5).timeout
	await _shot("f06_map")
	for p in [game.save_path, game.backup_path]:
		if String(p).contains("test"): DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	quit()
