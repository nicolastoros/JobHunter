extends SceneTree
var out := ""
func _initialize() -> void:
	out = OS.get_environment("CAPTURE_DIR")
	_run.call_deferred()
func _f(n: int) -> void:
	for i in n: await process_frame
func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(n + ".png"))
func _p() -> Node2D:
	return current_scene.get_node("Entities/Player")
func _run() -> void:
	var game = root.get_node("Game")
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 12
	game.pending_spawn = "south"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.5).timeout
	var by := {}
	for m in get_nodes_in_group("monsters"):
		by[m.monster_name] = int(by.get(m.monster_name, 0)) + 1
	print("monsters ", get_nodes_in_group("monsters").size(), " ", by)
	print("animals ", current_scene.find_children("Hare*", "", true, false).size() + current_scene.find_children("Deer*", "", true, false).size())
	# fps while walking the meadow
	_p()._invulnerable = 9999.0
	var t0 := Time.get_ticks_msec()
	var frames := 0
	Input.action_press("move_up")
	while Time.get_ticks_msec() - t0 < 3000:
		await process_frame
		frames += 1
	Input.action_release("move_up")
	print("fps ~", frames / 3.0)
	# the north-west forest
	_p().global_position = Vector2(26 * 16, 20 * 16); _p().reset_physics_interpolation(); _p().get_node("Camera2D").reset_smoothing()
	await create_timer(1.0).timeout
	await _shot("m01_forest")
	# fight a sapling
	var sap: Node2D = null
	for m in get_nodes_in_group("monsters"):
		if m.monster_name == "Retoño del bosque" and (sap == null or m.global_position.distance_to(_p().global_position) < sap.global_position.distance_to(_p().global_position)): sap = m
	print("sapling lvl ", sap.monster_level, " hp ", sap.max_hp, " dmg ", sap.damage, " xp ", sap.xp_reward, " offset ", sap.sprite_offset_y)
	sap.take_hit(3, _p())
	await create_timer(0.3).timeout
	await _shot("m02_sapling_hit")
	var bag0: Dictionary = game.inventory.duplicate()
	for m in get_nodes_in_group("monsters"):
		if m.monster_name in ["Retoño del bosque", "Limo musgoso", "Ent frondoso"] and m.global_position.distance_to(_p().global_position) < 400:
			m.take_hit(9999, _p())
	await create_timer(0.5).timeout
	print("loot ", bag0, " -> ", game.inventory)
	# crystal golems at the ruins, mist slimes in the marsh
	_p().global_position = Vector2(70 * 16, 52 * 16); _p().reset_physics_interpolation(); _p().get_node("Camera2D").reset_smoothing()
	await create_timer(1.0).timeout
	await _shot("m03_ruins")
	_p().global_position = Vector2(128 * 16, 24 * 16); _p().reset_physics_interpolation(); _p().get_node("Camera2D").reset_smoothing()
	await create_timer(1.0).timeout
	await _shot("m04_marsh")
	# ranking
	await _act("ranking")
	await create_timer(0.6).timeout
	await _shot("m05_ranking")
	print("ranking size ", game.ranking().size(), " place ", game.player_place())
	# the farms
	change_scene_to_file("res://scenes/world/world.tscn")
	await create_timer(1.5).timeout
	_p().global_position = Vector2(150 * 16, 62 * 16); _p().reset_physics_interpolation(); _p().get_node("Camera2D").reset_smoothing()
	await create_timer(1.5).timeout
	await _shot("m06_farm")
	for p in [game.save_path, game.backup_path]:
		if String(p).contains("test"): DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	quit()
func _act(a: String) -> void:
	var e := InputEventAction.new(); e.action = a; e.pressed = true; Input.parse_input_event(e)
	await _f(2)
	var r := InputEventAction.new(); r.action = a; r.pressed = false; Input.parse_input_event(r)
	await _f(2)
