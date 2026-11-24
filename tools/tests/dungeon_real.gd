extends SceneTree
## A dungeon fought for real: the hero walks to the nearest monster and swings the sword (no instant
## kills). Measures the time per wave, damage taken and whether the boss falls.


func _initialize() -> void:
	_run.call_deferred()


func _p() -> Node2D:
	return current_scene.get_node("Entities/Player")


func _tap(a: String) -> void:
	var e := InputEventAction.new(); e.action = a; e.pressed = true; Input.parse_input_event(e)
	await physics_frame
	var r := InputEventAction.new(); r.action = a; r.pressed = false; Input.parse_input_event(r)


func _run() -> void:
	var game = root.get_node("Game")
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 15
	for slot in ["weapon", "helmet", "chest", "boots"]:
		pass
	game.bag.append("espada_acero+4"); game.equip(game.bag.find("espada_acero+4"))
	game.bag.append("casco_hierro+2"); game.equip(game.bag.find("casco_hierro+2"))
	game.bag.append("coraza_hierro+2"); game.equip(game.bag.find("coraza_hierro+2"))
	game.recalc_stats()
	game.daily = game._fresh_daily(); game.daily["day"] = game.today_key()
	game.pending_spawn = "south"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.3).timeout
	game.enter_dungeon("ruinas", false)
	await create_timer(2.0).timeout
	var ctrl = current_scene.get_node("Dungeon")
	var dmg_taken := 0
	var hp_prev: int = game.player_hp
	var t0 := Time.get_ticks_msec()
	var last_wave := 0
	while not ctrl._done and Time.get_ticks_msec() - t0 < 240000:
		await physics_frame
		if ctrl._wave != last_wave:
			print("wave ", ctrl._wave, " starts at ", int(ctrl._time), "s")
			last_wave = ctrl._wave
		if game.player_hp < hp_prev:
			dmg_taken += hp_prev - game.player_hp
		if game.player_hp < game.max_hp * 0.4:
			game.player_hp = game.max_hp   # a potion's worth, to keep the run going
		hp_prev = game.player_hp
		var best: Node2D = null
		for m in get_nodes_in_group("monsters"):
			if int(m.hp) > 0 and (best == null or m.global_position.distance_to(_p().global_position) < best.global_position.distance_to(_p().global_position)):
				best = m
		if best == null:
			continue
		var to := best.global_position - _p().global_position
		if to.length() > 20.0:
			_p().global_position += to.normalized() * 2.4   # walking
		else:
			_p().facing = "right" if to.x > 0 else "left"
			if absf(to.y) > absf(to.x): _p().facing = "down" if to.y > 0 else "up"
			if Engine.get_physics_frames() % 14 == 0:
				await _tap("attack")
	print("done ", ctrl._done, " in ", int(ctrl._time), "s, damage taken ", dmg_taken, " hits ", ctrl._hits, " rank ", game.dungeon_rank(ctrl._time, ctrl._hits))
	quit()
