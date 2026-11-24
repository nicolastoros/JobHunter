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
func _key(action: String) -> void:
	var e := InputEventAction.new(); e.action = action; e.pressed = true; Input.parse_input_event(e)
	await _f(2)
	var r := InputEventAction.new(); r.action = action; r.pressed = false; Input.parse_input_event(r)
	await _f(2)
func _p() -> Node2D:
	return current_scene.get_node("Entities/Player")
func _run() -> void:
	var game = root.get_node("Game")
	game.reset_progress()
	game.pending_spawn = "south"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.2).timeout
	print("start points ", game.talent_points)
	var total := 0
	for l in range(1, 12): total += GameData.xp_to_next(l)
	game.add_xp(total)
	print("lvl ", game.level, " points ", game.talent_points)
	var hp0: int = game.max_hp
	print("vida +5 spent ", game.add_attribute("vida", 5), " max_hp ", hp0, " -> ", game.max_hp)
	game.add_attribute("magia", 2); game.add_attribute("energia", 1)
	print("tier1 blocked: ", game.talent_block_reason("aguante"))
	for i in 2: game.add_talent("vigor")
	print("aguante after 2 vigor: '", game.talent_block_reason("aguante"), "' -> ", game.add_talent("aguante"))
	for i in 3: game.add_talent("filo")
	print("golpe_certero (needs 5 pts in branch): ", game.talent_block_reason("golpe_certero"), " branch pts ", game.branch_points(0))
	print("learn golpe_certero ", game.add_talent("golpe_certero"), " crit ", game.crit_chance())
	game.add_talent("mente"); game.add_talent("poder_arcano")
	print("skill power ", game.skill_power(), " atk ", game.attack(), " points left ", game.talent_points)
	game.skill_xp = 200
	game.improve_skill("giro"); game.improve_skill("embestida")
	# quests
	game.accept_quest("slimes")
	var killed := 0
	for m in get_nodes_in_group("monsters"):
		if String(m.monster_name) == "Limo" and killed < 5 and m.hp > 0:
			m.take_hit(999, _p()); killed += 1
	await create_timer(0.3).timeout
	var q = game.quests[0]
	print("quest ", q["state"], " ", q["progress"])
	var gold0: int = game.gold
	await create_timer(0.3).timeout
	# menus
	for t in ["talents", "character", "skills", "inventory"]:
		await _key(t)
		await create_timer(0.3).timeout
		await _shot("t_" + t)
		await _key(t)
		await create_timer(0.2).timeout
	# respec
	game.gold = 1000
	var before: int = game.talent_points
	print("respec ", game.reset_talents(), " points ", before, " -> ", game.talent_points, " gold ", game.gold)
	game.add_talent("vigor"); game.add_attribute("vida", 3)
	# save/load keeps attributes & tree
	game.save_game()
	game.attributes["vida"] = 0
	game.load_game()
	await create_timer(1.5).timeout
	print("loaded vida ", game.attr("vida"), " vigor ", game.talent_rank("vigor"), " quest ", game.quests[0]["state"])
	# board claim
	change_scene_to_file("res://scenes/interiors/guild_1f.tscn")
	await create_timer(1.0).timeout
	game.quest_board_requested.emit()
	await create_timer(0.4).timeout
	var qb = current_scene.get_node("HUD/QuestBoard")
	qb._select(0)
	await _shot("t_board")
	qb._on_accept()
	print("claimed: ", game.quests[0]["state"], " gold +", game.gold - gold0)
	await create_timer(0.3).timeout
	await _shot("t_board2")
	if String(game.save_path).contains("test"): DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	quit()
