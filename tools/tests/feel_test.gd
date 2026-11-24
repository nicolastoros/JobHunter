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
	print("SFX bus ", AudioServer.get_bus_index("SFX"), " players ", game._sfx_players.size())
	var missing := []
	for f in ["swing","hit","crit","hurt","monster_die","coin","loot_rare","loot_epic","loot_legendary","level_up","potion","chest","door","ui_click","ui_open","horn","skill","player_die","quest"]:
		if load("res://assets/audio/sfx/%s.wav" % f) == null: missing.append(f)
	print("missing sounds ", missing)
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 6
	game.recalc_stats()
	game.pending_spawn = "south"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.5).timeout
	var sl: Node2D = null
	for m in get_nodes_in_group("monsters"):
		if not m.boss and (sl == null or m.global_position.distance_to(_p().global_position) < sl.global_position.distance_to(_p().global_position)): sl = m
	_p().global_position = sl.global_position + Vector2(-22, 0); _p().reset_physics_interpolation(); _p().get_node("Camera2D").reset_smoothing()
	_p()._invulnerable = 999.0
	await create_timer(0.5).timeout
	# a normal hit and a critical: hit-stop slows time, crit shakes the camera
	var t0 := Time.get_ticks_msec()
	game.hit_monster(sl, 1, false, _p())
	await process_frame
	print("hit-stop time_scale ", Engine.time_scale)
	await create_timer(0.2, true, false, true).timeout
	print("after ", Engine.time_scale)
	var old_cc = game.crit_chance
	game.talents["golpe_certero"] = 99
	game.hit_monster(sl, 1, false, _p())
	await process_frame
	await process_frame
	print("crit shake offset ", _p().get_node("Camera2D").offset, " playing ", game._sfx_players.filter(func(q): return q.playing).size())
	await create_timer(0.05, true, false, true).timeout
	await _shot("s01_crit")
	game.talents.erase("golpe_certero")
	sl.take_hit(9999, _p())
	await create_timer(0.12).timeout
	await _shot("s02_death_burst")
	await create_timer(1.0).timeout
	print("offset back to zero ", _p().get_node("Camera2D").offset == Vector2.ZERO, " time_scale ", Engine.time_scale)
	# options menu with the effects slider
	change_scene_to_file("res://scenes/ui/main_menu.tscn")
	await create_timer(1.0).timeout
	var om = current_scene.find_children("OptionsMenu", "", true, false)
	if om.size() > 0:
		om[0].open()
		await create_timer(0.3).timeout
		await _shot("s03_options")
	game.set_setting("sfx_volume", 0.5)
	print("sfx bus db ", AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	game.set_setting("sfx_volume", 0.8)
	quit()
