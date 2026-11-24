extends SceneTree
## Playtest fuzz: in every region the hero runs around at random for a while, attacking, casting,
## drinking, riding, opening every menu and the world map. Anything that breaks shows as SCRIPT ERROR.

const MAPS := ["world.tscn", "field.tscn", "forest.tscn", "desert.tscn", "aurelia.tscn", "snowforest.tscn", "snowvillage.tscn", "ocaso.tscn"]
const ACTIONS := ["move_up", "move_down", "move_left", "move_right"]


func _initialize() -> void:
	_run.call_deferred()


func _tap(a: String) -> void:
	var e := InputEventAction.new(); e.action = a; e.pressed = true; Input.parse_input_event(e)
	await create_timer(0.06, true, false, true).timeout
	var r := InputEventAction.new(); r.action = a; r.pressed = false; Input.parse_input_event(r)
	await create_timer(0.06, true, false, true).timeout


func _run() -> void:
	var game = root.get_node("Game")
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 40
	game.skill_xp = 9999
	for s in GameData.SKILLS:
		game.improve_skill(s["id"])
	game.has_mount = true
	game.pets.append("zorro"); game.active_pet = "zorro"
	game.recalc_stats()
	game.daily = game._fresh_daily(); game.daily["day"] = game.today_key()
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	for m in MAPS:
		game.pending_spawn = "start" if m != "world.tscn" else ""
		change_scene_to_file("res://scenes/world/" + m)
		await create_timer(1.6).timeout
		var p: Node2D = current_scene.get_node("Entities/Player")
		p.set("_invulnerable", 9999.0)
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 9000:
			var a: String = ACTIONS[rng.randi() % 4]
			Input.action_press(a)
			if rng.randf() < 0.5: Input.action_press("run")
			for i in rng.randi_range(4, 14):
				await physics_frame
			match rng.randi() % 9:
				0: await _tap("attack")
				1: await _tap("skill_%d" % rng.randi_range(1, 6))
				2: await _tap("use_potion")
				3: await _tap("target")
				4: await _tap("mount")
				5: await _tap("interact")
			Input.action_release(a)
			Input.action_release("run")
			game.player_hp = game.max_hp
			if game.menu_open:
				await _tap("ui_cancel")
		for menu in ["character", "inventory", "skills", "talents", "map", "world_map", "daily", "codex", "ranking"]:
			await _tap(menu)
			await create_timer(0.25, true, false, true).timeout
			await _tap(menu)
			await create_timer(0.15, true, false, true).timeout
			if game.menu_open or paused:
				await _tap("ui_cancel")
				await create_timer(0.15, true, false, true).timeout
		print("== ", m, " ok  hp ", game.player_hp, "/", game.max_hp, " paused ", paused, " menu ", game.menu_open, " kills ", game.kills.values().reduce(func(a, b): return a + b, 0) if game.kills.size() > 0 else 0)
	quit()
