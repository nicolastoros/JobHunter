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
	await create_timer(0.1).timeout
	var r := InputEventAction.new(); r.action = a; r.pressed = false; Input.parse_input_event(r)
	await create_timer(0.4).timeout
func _levels() -> String:
	var by := {}
	for m in get_nodes_in_group("monsters"):
		var n: String = m.monster_name
		if not by.has(n): by[n] = [999, 0]
		by[n][0] = mini(by[n][0], m.monster_level); by[n][1] = maxi(by[n][1], m.monster_level)
	return str(by)
func _run() -> void:
	var game = root.get_node("Game")
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 5
	game.recalc_stats()
	for map in ["field", "forest", "desert"]:
		game.pending_spawn = "start"
		change_scene_to_file("res://scenes/world/%s.tscn" % map)
		await create_timer(1.3).timeout
		print(map, " levels ", _levels(), " zone ", game.zone_levels())
		if map == "desert":
			await create_timer(1.0).timeout
			await _shot("l00_desert_warning")
	# rarity distribution
	var counts := [0, 0, 0, 0, 0, 0, 0]
	var sample := ""
	for i in 4000:
		var piece: String = game.make_piece(20)
		counts[game.eq_rarity(piece)] += 1
		if game.eq_rarity(piece) == 3 and sample == "": sample = piece
	print("rarity normal ", counts)
	counts = [0, 0, 0, 0, 0, 0, 0]
	for i in 4000:
		counts[game.eq_rarity(game.make_piece(20, 1.0))] += 1
	print("rarity boss ", counts)
	print("legendary sample ", sample, " -> ", game.eq(sample))
	# forge keeps rarity and bonuses
	var up: String = game.eq_with_plus(sample, 3)
	print("forged ", up, " base ", game.eq_base(up), " plus ", game.eq_plus(up), " rarity ", game.eq_rarity(up), " affixes ", game.eq_affixes(up))
	# xp gap
	print("xp gap: lvl1 mob vs 20 -> ", game.xp_gap_mult(1, 20), "  same -> ", game.xp_gap_mult(20, 20), "  +5 -> ", game.xp_gap_mult(25, 20))
	# field: close to monsters, levels shown; kill with legendary forced to see the beam
	game.level = 12
	game.recalc_stats()
	game.pending_spawn = "south"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.5).timeout
	var sl: Node2D = null
	for m in get_nodes_in_group("monsters"):
		if not m.boss and (sl == null or m.global_position.distance_to(_p().global_position) < sl.global_position.distance_to(_p().global_position)): sl = m
	_p().global_position = sl.global_position + Vector2(-50, 10); _p().reset_physics_interpolation(); _p().get_node("Camera2D").reset_smoothing()
	_p()._invulnerable = 999.0
	await create_timer(0.8).timeout
	await _shot("l01_levels")
	var pieces := []
	for r in [1, 2, 3]:
		var pc: String = ""
		while game.eq_rarity(pc) != r:
			pc = game.make_piece(14, 3.0)
		pieces.append(pc)
		game.bag.append(pc)
	game.announce_piece(pieces[2], sl.global_position + Vector2(0, -20))
	await create_timer(0.7).timeout
	await _shot("l02_beam")
	# menu & forge
	game.equip(game.bag.find(pieces[1])) if game.equip_block_reason(pieces[1]) == "" else null
	await _key("character")
	await create_timer(0.3).timeout
	var gm = current_scene.get_node("HUD/GameMenu") if current_scene.has_node("HUD/GameMenu") else null
	await _shot("l03_character")
	await _key("character")
	# save / load keeps the pieces
	game.save_game()
	var bag_before: Array = game.bag.duplicate()
	game.bag.clear()
	game.load_game()
	await create_timer(1.5).timeout
	print("save keeps bag ", Array(game.bag) == bag_before)
	print("sell legendary ", game.sell_value(pieces[2], true), " vs common ", game.sell_value(game.eq_base(pieces[2]), true))
	for p in [game.save_path, game.backup_path]:
		if String(p).contains("test"): DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	quit()
