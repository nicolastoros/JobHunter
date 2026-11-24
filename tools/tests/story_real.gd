extends SceneTree
## Brann's training played for real: from the Ruins the hero walks to the gnolls and fights them with the
## sword (no instant kills) until the counter reaches 10; then talks to Tova, who must be there.
var out := ""


func _initialize() -> void:
	out = OS.get_environment("CAPTURE_DIR")
	_run.call_deferred()


func _p() -> Node2D:
	return current_scene.get_node("Entities/Player")


func _tap(a: String) -> void:
	var e := InputEventAction.new(); e.action = a; e.pressed = true; Input.parse_input_event(e)
	await physics_frame
	var r := InputEventAction.new(); r.action = a; r.pressed = false; Input.parse_input_event(r)


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(n + ".png"))


func _run() -> void:
	var game = root.get_node("Game")
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 16
	game.bag.append("espada_acero+4"); game.equip(game.bag.find("espada_acero+4"))
	game.bag.append("coraza_hierro+2"); game.equip(game.bag.find("coraza_hierro+2"))
	game.recalc_stats()
	game.daily = game._fresh_daily(); game.daily["day"] = game.today_key()
	game.story_step = 3
	game.pending_spawn = "start"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.5).timeout
	var w = current_scene
	var target: Vector2 = game.story_current()["pos"] * 16.0
	# travel along the walk grid to the gnolls' meadow
	var path: PackedVector2Array = w.find_path(_p().global_position, target)
	print("path to the gnolls: ", path.size(), " turns, from ", Vector2i(_p().global_position / 16), " to ", Vector2i(target / 16))
	for pt in path:
		while _p().global_position.distance_to(pt) > 6.0:
			_p().global_position = _p().global_position.move_toward(pt, 4.0)
			await physics_frame
	await _shot("real_01_gnolls")
	var t0 := Time.get_ticks_msec()
	var last := -1
	while game.story_step == 3 and Time.get_ticks_msec() - t0 < 300000:
		await physics_frame
		if game.story_prog != last:
			last = game.story_prog
			print("  objective: ", game.objective_text(), "  at ", (Time.get_ticks_msec() - t0) / 1000, "s")
		if game.player_hp < game.max_hp * 0.4:
			game.player_hp = game.max_hp
		var best: Node2D = null
		for m in get_nodes_in_group("monsters"):
			if String(m.base_name) == "Gnoll" and int(m.hp) > 0 and (best == null or m.global_position.distance_to(_p().global_position) < best.global_position.distance_to(_p().global_position)):
				best = m
		if best == null:
			continue
		var to := best.global_position - _p().global_position
		if to.length() > 20.0:
			var step := to.normalized() * 2.6
			if w.is_walkable(_p().global_position + step * 4.0):
				_p().global_position += step
			else:
				var pp: PackedVector2Array = w.find_path(_p().global_position, best.global_position)
				if pp.size() > 1:
					_p().global_position += (pp[1] - _p().global_position).normalized() * 2.6
		else:
			_p().facing = "right" if to.x > 0 else "left"
			if absf(to.y) > absf(to.x): _p().facing = "down" if to.y > 0 else "up"
			if Engine.get_physics_frames() % 14 == 0:
				await _tap("attack")
	print("training done: step ", game.story_step, " in ", (Time.get_ticks_msec() - t0) / 1000, "s")
	await create_timer(1.0).timeout
	var tova: Node2D = w.get_node_or_null("Entities/Cast_tova")
	print("Tova in the field: ", tova != null, "  objective: ", game.objective_text())
	if tova:
		_p().global_position = tova.global_position + Vector2(0, 20)
		await create_timer(0.6).timeout
		tova.interact(_p())
		await create_timer(0.6).timeout
		await _shot("real_02_tova")
		print("after Tova: step ", game.story_step, "  objective: ", game.objective_text())
	quit()
