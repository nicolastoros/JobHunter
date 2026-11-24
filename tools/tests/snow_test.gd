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
func _go(x: float, y: float) -> void:
	_p().global_position = Vector2(x * 16, y * 16); _p().reset_physics_interpolation(); _p().get_node("Camera2D").reset_smoothing()
	await create_timer(1.2).timeout
func _levels() -> String:
	var by := {}
	for m in get_nodes_in_group("monsters"):
		var n: String = m.monster_name
		if not by.has(n): by[n] = [999, 0, 0]
		by[n][0] = mini(by[n][0], m.monster_level); by[n][1] = maxi(by[n][1], m.monster_level); by[n][2] += 1
	return str(by)
func _run() -> void:
	var game = root.get_node("Game")
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 58
	game.recalc_stats()
	game.daily = game._fresh_daily(); game.daily["day"] = game.today_key()
	for m in ["field.tscn", "forest.tscn", "desert.tscn"]:
		game.pending_spawn = "start"
		change_scene_to_file("res://scenes/world/" + m)
		await create_timer(1.3).timeout
		var by := {}
		for mo in get_nodes_in_group("monsters"):
			if mo.monster_name in ["Jabalí salvaje", "Lobo del bosque", "Árbol marchito"]:
				by[mo.monster_name] = [mo.monster_level, int(by.get(mo.monster_name, [0, 0])[1]) + 1]
		print(m, " new beasts ", by)
	# forest -> north trail -> snow forest
	game.pending_spawn = "north"
	change_scene_to_file("res://scenes/world/forest.tscn")
	await create_timer(1.5).timeout
	print("forest north spawn ", (_p().global_position / 16).round())
	_p()._invulnerable = 99999.0
	Input.action_press("move_up")
	await create_timer(1.4).timeout
	Input.action_release("move_up")
	await create_timer(1.8).timeout
	print("walked north -> ", current_scene.scene_file_path.get_file())
	_p()._invulnerable = 99999.0
	await _shot("s00_edge")
	print("snowforest ", _levels())
	game.inventory["pocion"] = 0
	await _go(80.5, 113)
	await create_timer(0.8).timeout
	print("camp safe ", game.is_safe_here(), " potions ", game.item_count("pocion"), " stones ", get_nodes_in_group("waystones").size())
	await _shot("s01_camp")
	await _go(30, 70)
	await _shot("s02_pinewood")
	await _go(26, 30)
	await _shot("s03_graveyard")
	await _go(110, 74)
	await _shot("s04_lake")
	await _go(80, 38)
	await _shot("s05_entglade")
	await _go(128, 28)
	await _shot("s06_grotto")
	# east to the village
	await _go(154, 61)
	Input.action_press("move_right")
	await create_timer(1.2).timeout
	Input.action_release("move_right")
	await create_timer(1.8).timeout
	print("walked east -> ", current_scene.scene_file_path.get_file(), " safe ", game.is_safe_here(), " walkers ", current_scene.find_children("*", "CharacterBody2D", true, false).size())
	await _shot("s07_village_gate")
	await _go(55, 46)
	await _shot("s08_plaza")
	await _go(75, 54)
	await _shot("s09_forge")
	await _go(30, 26)
	await _shot("s10_houses")
	for w in ["frostedge", "frostvillage", "camp"]: game.waystones_unlocked[w] = true
	for vm in ["snowforest.tscn", "snowvillage.tscn", "forest.tscn", "world.tscn", "field.tscn", "desert.tscn", "aurelia.tscn"]: game.visited_maps[vm] = true
	var e := InputEventAction.new(); e.action = "world_map"; e.pressed = true; Input.parse_input_event(e)
	await create_timer(0.5, true, false, true).timeout
	await _shot("s11_worldmap")
	print("bestiary pages ", GameData.BESTIARY.size())
	quit()
