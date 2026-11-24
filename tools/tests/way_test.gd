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
func _stone(id: String) -> Node2D:
	for s in get_nodes_in_group("waystones"):
		if s.stone_id == id: return s
	return null
func _run() -> void:
	var game = root.get_node("Game")
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 30
	game.recalc_stats()
	game.daily = game._fresh_daily(); game.daily["day"] = game.today_key()   # no diary popup in this test
	for map in ["world.tscn", "field.tscn", "forest.tscn", "desert.tscn", "aurelia.tscn"]:
		game.pending_spawn = "start" if map != "world.tscn" else ""
		change_scene_to_file("res://scenes/world/" + map)
		await create_timer(1.4).timeout
		for s in get_nodes_in_group("waystones"):
			var w = game.waystone_def(s.stone_id)
			print(map, " stone ", s.stone_id, " at ", (s.global_position / 16).round(), " (wanted ", w["pos"], ") walkable ", current_scene.is_walkable(s.global_position + Vector2(0, 16)))
			_p().global_position = s.global_position + Vector2(0, 18); _p().reset_physics_interpolation(); _p().get_node("Camera2D").reset_smoothing()
			_p().facing = "up"
			await create_timer(0.5).timeout
			s.interact(_p())
			await create_timer(0.7).timeout
			await _shot("w_" + s.stone_id)
	print("unlocked ", game.waystones_unlocked.size())
	# menu from the Aurelia stone, then travel to the camp (another region)
	_stone("aurelia").interact(_p())
	await create_timer(0.4, true, false, true).timeout
	await _shot("w_menu")
	for c in game.get_children():
		if c.get_script() and String(c.get_script().resource_path).ends_with("waystone_menu.gd"): c.close_menu()
	game.teleport_to("camp")
	await create_timer(2.0).timeout
	print("after teleport: ", current_scene.scene_file_path.get_file(), " near camp stone ", _p().global_position.distance_to(_stone("camp").global_position) < 40)
	game.teleport_to("ruins")
	await create_timer(1.2).timeout
	print("same-map teleport: near ruins stone ", _p().global_position.distance_to(_stone("ruins").global_position) < 40, " scene ", current_scene.scene_file_path.get_file())
	game.check_achievements()
	print("rune title ", game.titles_unlocked.has("runes"))
	game.save_game()
	game.waystones_unlocked = {}
	game.load_game()
	await create_timer(1.5).timeout
	print("loaded stones ", game.waystones_unlocked.size())
	var e := InputEventAction.new(); e.action = "world_map"; e.pressed = true; Input.parse_input_event(e)
	await create_timer(0.5, true, false, true).timeout
	await _shot("w_worldmap")
	for p in [game.save_path, game.backup_path]:
		if String(p).contains("test"): DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	quit()
