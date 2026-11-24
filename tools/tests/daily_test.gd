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
	await create_timer(0.4, true, false, true).timeout
func _run() -> void:
	var game = root.get_node("Game")
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 8
	game.recalc_stats()
	# yesterday's streak of 2 -> today is day 3
	game.daily = game._fresh_daily()
	var y := Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) - 86400)
	game.daily["last"] = y; game.daily["day"] = y; game.daily["streak"] = 2
	game.pending_spawn = "south"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(2.5).timeout
	print("streak ", game.daily["streak"], " prey ", game.daily["prey"], " tasks ", game.daily["tasks"].map(func(t): return t["text"]), " weekly ", game.daily["weekly"]["text"])
	var dl = null
	for c in game.get_children():
		if c.get_script() and String(c.get_script().resource_path).ends_with("daily.gd"): dl = c
	print("diary auto-open ", dl._root.visible)
	await _shot("d01_diary")
	var g0: int = game.gold
	game.claim_streak_reward()
	print("streak reward gold +", game.gold - g0, " pending ", game.daily["reward_pending"])
	dl.close_diary()
	await create_timer(0.3).timeout
	# hunt the prey: x2 gold, star over the head, task progress
	var prey: String = game.daily["prey"]
	var pm: Node2D = null
	for m in get_nodes_in_group("monsters"):
		if m.base_name == prey and (pm == null or m.global_position.distance_to(_p().global_position) < pm.global_position.distance_to(_p().global_position)): pm = m
	_p().global_position = pm.global_position + Vector2(-40, 0); _p().reset_physics_interpolation(); _p().get_node("Camera2D").reset_smoothing()
	_p()._invulnerable = 9999.0
	await create_timer(0.8).timeout
	await _shot("d02_prey_star")
	for i in 12:
		for m in get_nodes_in_group("monsters"):
			if m.base_name == prey and m.hp > 0:
				m.take_hit(99999, _p())
				break
		await process_frame
	await create_timer(0.5).timeout
	print("kills ", game.kills.get(prey, 0), " stars ", game.bestiary_stars(prey), " task0 ", game.daily["tasks"][0]["p"], "/", game.daily["tasks"][0]["n"])
	print("claim task ", game.claim_daily(0), " dailies ", game.stats["dailies"])
	# achievements after the kills
	game.check_achievements()
	await create_timer(0.3).timeout
	print("titles ", game.titles_unlocked.keys(), " active ", game.active_title)
	game.kills["Limo"] = 320; game.kills["Rey Limo"] = 1
	game.check_achievements()
	await create_timer(0.3).timeout
	print("titles ", game.titles_unlocked.keys(), " ranking me ", game.ranking().filter(func(e): return e["player"])[0])
	await _key("codex")
	await create_timer(0.3, true, false, true).timeout
	await _shot("d03_bestiary")
	var cx = null
	for c in game.get_children():
		if c.get_script() and String(c.get_script().resource_path).ends_with("codex.gd"): cx = c
	cx._tab = "achievements"; cx._refresh()
	await create_timer(0.2, true, false, true).timeout
	await _shot("d04_achievements")
	cx.close_codex()
	await _key("daily")
	await create_timer(0.3, true, false, true).timeout
	await _shot("d05_diary2")
	dl.close_diary()
	# save/load keeps it all
	game.save_game()
	var st: int = game.daily["streak"]
	game.daily = {}
	game.titles_unlocked = {}
	game.load_game()
	await create_timer(1.5).timeout
	print("loaded streak ", game.daily.get("streak"), "==", st, " titles ", game.titles_unlocked.size(), " active ", game.active_title)
	for p in [game.save_path, game.backup_path]:
		if String(p).contains("test"): DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	quit()
