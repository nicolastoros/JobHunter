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
	game.reset_progress()
	# --- stamina in town: running costs nothing
	change_scene_to_file("res://scenes/world/world.tscn")
	await create_timer(1.2).timeout
	Input.action_press("run"); Input.action_press("move_left")
	await create_timer(1.5).timeout
	Input.action_release("move_left"); Input.action_release("run")
	print("town stamina after run: ", game.stamina)
	# --- field
	game.pending_spawn = "south"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.2).timeout
	game.stamina = 3.0
	Input.action_press("run"); Input.action_press("move_up")
	await create_timer(0.6).timeout
	print("field: exhausted ", _p()._exhausted, " stamina ", snappedf(game.stamina, 0.1), " speed ", snappedf(_p().velocity.length(), 1))
	Input.action_release("move_up"); Input.action_release("run")
	# --- level up and learn
	print("lvl ", game.level, " sp ", game.skill_points, " tp ", game.talent_points)
	game.add_xp(20 + 35 + 50)
	print("after xp: lvl ", game.level, " sp ", game.skill_points, " tp ", game.talent_points, " xp ", game.xp, "/", game.xp_to_next())
	for s in game.SKILLS:
		print("learn ", s["id"], " -> ", game.learn_skill(s["id"]), " ", game.learn_block_reason(s["id"]))
	print("talent filo ", game.add_talent("filo"), " vit ", game.add_talent("vitalidad"), " max_hp ", game.max_hp, " dmg+ ", game.damage_bonus())
	# --- spin attack on a slime
	var sl := _nearest("Limo")
	_p().global_position = sl.global_position + Vector2(-20, 4); _p().get_node("Camera2D").reset_smoothing()
	await _f(3)
	var hp0: int = sl.hp
	var mana0: float = game.mana
	await _key("skill_1")
	await _f(4)
	print("spin: slime hp ", hp0, " -> ", sl.hp, " mana ", int(mana0), " -> ", int(game.mana), " cd ", snappedf(game.skill_cooldown_left("giro"), 0.1))
	await _shot("r01_spin")
	await _key("skill_1")
	await create_timer(1.2).timeout
	# --- dash
	_p().global_position = Vector2(85.5 * 16, 112 * 16); _p().get_node("Camera2D").reset_smoothing()
	await _f(3)
	game.mana = game.max_mana
	var p0 := _p().global_position
	_p().facing = "up"
	await _key("skill_2")
	await create_timer(0.4).timeout
	print("dash moved ", int(_p().global_position.distance_to(p0)), "px state ", _p().state)
	game.mana = game.max_mana
	await _key("skill_3")
	print("buff ", game.buff_active(), " dmg+ ", game.damage_bonus())
	game.player_hp = 5
	game.mana = game.max_mana
	await _key("skill_4")
	print("respiro hp ", game.player_hp)
	# --- kill something: loot & xp
	var inv0: Dictionary = game.inventory.duplicate()
	var xp0: int = game.xp
	var gob := _nearest("Goblin")
	gob.take_hit(99, _p())
	await create_timer(0.3).timeout
	print("goblin kill: xp ", xp0, " -> ", game.xp, " inv ", inv0, " -> ", game.inventory)
	# --- menus
	await create_timer(1.0).timeout
	await _key("inventory")
	await create_timer(0.3).timeout
	print("menu open ", game.menu_open, " paused ", paused)
	await _shot("r02_inventory")
	await _key("skills")
	await create_timer(0.2).timeout
	await _shot("r03_skills")
	await _key("talents")
	await create_timer(0.2).timeout
	await _shot("r04_talents")
	var gm = current_scene.get_node("HUD/GameMenu")
	gm.show_tab("inventory")
	gm._sel_item = "manzana"
	game.player_hp = 3
	gm._refresh_inventory()
	gm._on_use()
	print("apple used: hp ", game.player_hp, " apples ", game.item_count("manzana"))
	await _key("pause")
	await create_timer(0.2).timeout
	print("after esc: menu ", game.menu_open, " paused ", paused)
	await create_timer(0.5).timeout
	await _shot("r05_hud")
	quit()
