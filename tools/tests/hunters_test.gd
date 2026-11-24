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
	game.daily = game._fresh_daily(); game.daily["day"] = game.today_key()   # no diary popping up (it pauses)
	game.pending_spawn = "south"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.5).timeout
	_p()._invulnerable = 999.0
	var hs := get_nodes_in_group("hunters")
	print("hunters ", hs.size(), " roles ", hs.map(func(h): return h.role))
	var pos0 := {}
	for h in hs: pos0[h] = h.global_position
	await create_timer(12.0).timeout
	var moved := 0
	var fighting := 0
	hs = hs.filter(func(h): return is_instance_valid(h))
	for h in hs:
		if h.global_position.distance_to(pos0[h]) > 20: moved += 1
		if h.state in [2, 3]: fighting += 1
	var npc_sum := 0
	for k in game.npc_renown: npc_sum += game.npc_renown[k]
	print("moved ", moved, " fighting now ", fighting, " npc kills renown ", npc_sum, " player renown ", game.renown, " fps ", Engine.get_frames_per_second())
	# watch a fighter in action
	var fighter: Node2D = null
	for h in hs:
		if h.role == "fighter" and (fighter == null or h.state in [2, 3]): fighter = h
	_p().global_position = fighter.global_position + Vector2(0, 70); _p().get_node("Camera2D").reset_smoothing()
	await create_timer(1.0).timeout
	await _shot("h01_fighter")
	var runner: Node2D = null
	for h in hs:
		if h.role != "fighter": runner = h
	_p().global_position = runner.global_position + Vector2(-40, 40); _p().get_node("Camera2D").reset_smoothing()
	await create_timer(0.6).timeout
	await _shot("h02_traveler")
	# streak & renown
	var r0: int = game.renown
	var n := 0
	for m in get_nodes_in_group("monsters"):
		if String(m.monster_name) == "Limo" and m.hp > 0 and n < 3:
			m.take_hit(999, _p()); n += 1
			await create_timer(0.5).timeout
	print("streak ", game.streak(), " renown ", r0, " -> ", game.renown, " place ", game.player_place())
	await _shot("h03_streak")
	# contracts
	var c = game.contracts[0]
	print("contract: ", c)
	for i in int(c["count"]): game._contract_progress(String(c["monster"]))
	game.renown = 140
	print("claim ", game.claim_contract(0), " renown ", game.renown, " rank ", game.guild_rank(), " rewarded ", game.ranks_rewarded)
	change_scene_to_file("res://scenes/interiors/guild_1f.tscn")
	await create_timer(1.0).timeout
	game.quest_board_requested.emit()
	await create_timer(0.4).timeout
	var qb = current_scene.get_node("HUD/QuestBoard")
	qb.show_tab("contracts")
	await create_timer(0.2).timeout
	await _shot("h04_contracts")
	qb.show_tab("ranking")
	await create_timer(0.2).timeout
	await _shot("h05_ranking")
	qb.show_tab("quests")
	await create_timer(0.2).timeout
	await _shot("h06_quests")
	quit()
