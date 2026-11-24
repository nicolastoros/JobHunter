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
func _nearest(name: String) -> Node2D:
	var best: Node2D = null
	for m in get_nodes_in_group("monsters"):
		if String(m.monster_name) == name and m.hp > 0 and (best == null or m.global_position.distance_to(_p().global_position) < best.global_position.distance_to(_p().global_position)):
			best = m
	return best
func _run() -> void:
	var game = root.get_node("Game")
	if FileAccess.file_exists(game.save_path):
		if String(game.save_path).contains("test"): DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	game.reset_progress()
	game.pending_spawn = "south"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.2).timeout
	var sl := _nearest("Limo")
	print("lvl1 slime: lvl ", sl.monster_level, " hp ", sl.max_hp, " dmg ", sl.damage, " xp ", sl.xp_reward)
	print("start: atk ", game.attack(), " def ", game.defense(), " hp ", game.max_hp, " look ", game.look_tier(), " frames ", _p().sprite.sprite_frames.resource_path.get_file())
	# --- levels & looks
	var total := 0
	for l in range(1, 10): total += GameData.xp_to_next(l)
	game.add_xp(total)
	await _f(3)
	print("lvl ", game.level, " look ", game.look_tier(), " ", game.look_title(), " frames ", _p().sprite.sprite_frames.resource_path.get_file(), " tp ", game.talent_points)
	await create_timer(0.5).timeout
	await _shot("q01_look10")
	# --- skills
	game.skill_xp = 5000
	for l in range(10, 20): game.add_xp(GameData.xp_to_next(game.level))
	for s in GameData.SKILLS:
		game.improve_skill(s["id"])
	game.improve_skill("giro"); game.improve_skill("giro")
	print("lvl ", game.level, " ranks ", game.skill_ranks, " skill_xp left ", game.skill_xp, " look ", game.look_tier())
	sl = _nearest("Limo")
	sl._apply_level()
	print("lvl20 slime: lvl ", sl.monster_level, " hp ", sl.max_hp, " dmg ", sl.damage)
	for id in ["giro", "onda", "tajo"]:
		sl = _nearest("Limo")
		_p().global_position = sl.global_position + Vector2(-24, 6); _p().get_node("Camera2D").reset_smoothing()
		_p().facing = "right"; _p().state = 0
		await _f(3)
		game.mana = game.max_mana
		var hp0: int = sl.hp
		_p().cast_skill(id)
		await _f(3)
		print(id, ": slime hp ", hp0, " -> ", sl.hp, "  values ", game.skill_values(id))
		if id == "tajo": await _shot("q02_tajo")
		await create_timer(0.7).timeout
	game.mana = game.max_mana
	game.player_hp = 10
	_p().state = 0
	_p().cast_skill("respiro")
	print("respiro hp -> ", game.player_hp, "/", game.max_hp)
	await create_timer(0.3).timeout
	game.mana = game.max_mana
	_p().cast_skill("grito")
	print("grito buff ", game.buff_active(), " atk ", game.attack())
	# --- equipment
	var atk0: int = game.attack()
	game.bag.append("espada_ignea"); game.bag.append("espada_acero"); game.bag.append("coraza_hierro")
	print("equip ignea (lvl24 req): ", game.equip(0), " reason ", game.equip_block_reason("espada_ignea"))
	print("equip acero: ", game.equip(1), " atk ", atk0, " -> ", game.attack(), " bag ", game.bag)
	game.equip(game.bag.find("coraza_hierro"))
	print("def ", game.defense(), " mitigate(10) ", game.mitigate(10), " max_hp ", game.max_hp)
	# --- menus
	await create_timer(0.3).timeout
	await _key("character")
	await create_timer(0.3).timeout
	await _shot("q03_character")
	await _key("skills")
	await create_timer(0.2).timeout
	await _shot("q04_skills")
	await _key("skills")
	await create_timer(0.3).timeout
	# --- save / load
	var pos: Vector2 = _p().global_position
	print("save ", game.save_game())
	var gold_saved: int = game.gold
	game.gold = 1; game.level = 2
	game.load_game()
	await create_timer(1.6).timeout
	print("loaded: scene ", current_scene.scene_file_path.get_file(), " lvl ", game.level, " gold ", game.gold, "==", gold_saved, " pos ", _p().global_position.distance_to(pos) < 2.0, " ranks ", game.skill_ranks.size(), " eq ", game.equipped)
	# --- autosave
	var t0 := FileAccess.get_modified_time(game.save_path)
	await create_timer(1.1).timeout
	game._autosave_left = 0.05
	await create_timer(0.4).timeout
	print("autosave wrote file: ", FileAccess.get_modified_time(game.save_path) > t0)
	await _shot("q05_hud")
	# --- main menu continue
	change_scene_to_file("res://scenes/ui/main_menu.tscn")
	await create_timer(1.0).timeout
	print("continue enabled: ", not current_scene.get_node("Menu/Buttons/Continue").disabled)
	quit()
