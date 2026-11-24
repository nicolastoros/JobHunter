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
func _key(a: String) -> void:
	var e := InputEventAction.new(); e.action = a; e.pressed = true; Input.parse_input_event(e)
	await create_timer(0.1).timeout
	var r := InputEventAction.new(); r.action = a; r.pressed = false; Input.parse_input_event(r)
	await create_timer(0.4).timeout
func _run() -> void:
	var game = root.get_node("Game")
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 30
	game.recalc_stats()
	game.pending_spawn = "east"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.5).timeout
	print("field east spawn ", _p().global_position)
	await _shot("d00_field_east")
	_p()._invulnerable = 9999.0
	Input.action_press("move_right")
	await create_timer(1.5).timeout
	Input.action_release("move_right")
	await create_timer(1.5).timeout
	print("walked east -> ", current_scene.scene_file_path.get_file(), " pos ", _p().global_position)
	_p()._invulnerable = 9999.0
	await create_timer(0.8).timeout
	await _shot("d01_entry")
	var by := {}
	for m in get_nodes_in_group("monsters"):
		by[m.monster_name] = int(by.get(m.monster_name, 0)) + 1
	print("desert monsters ", by, " hunters ", get_nodes_in_group("hunters").size(), " chests ", get_nodes_in_group("chests").size())
	await _go(24, 64)
	game.inventory["pocion"] = 0
	await create_timer(1.0).timeout
	print("oasis safe ", game.is_safe_here(), " potions ", game.item_count("pocion"))
	await _shot("d02_oasis")
	await _go(124, 38)
	await _shot("d03_ruins")
	await _go(128, 100)
	await _shot("d04_canyon")
	await _go(70, 60)
	await _shot("d05_dunes")
	await _go(70, 104)
	await _shot("d06_glass")
	# loot from the desert creatures
	var inv0: Dictionary = game.inventory.duplicate()
	for m in get_nodes_in_group("monsters"):
		if not m.boss and m.global_position.distance_to(_p().global_position) < 500:
			m.take_hit(99999, _p())
	await create_timer(0.6).timeout
	print("loot ", inv0, " -> ", game.inventory)
	await _key("map")
	await _shot("d07_map")
	await _key("map")
	# weapons
	var base: Dictionary = {"crit": game.crit_chance(), "cd": game.crit_mult(), "sp": game.skill_power()}
	game.bag.append_array(["colmillo_dunas", "cimitarra_dorada+2", "hacha_berserker", "tridente_marea", "katana_luna", "lanza_acero"])
	game.level = 46
	game.recalc_stats()
	game.equip(game.bag.find("colmillo_dunas"))
	print("dagger crit ", base["crit"], " -> ", game.crit_chance())
	game.equip(game.bag.find("cimitarra_dorada+2"))
	print("scimitar crit dmg ", base["cd"], " -> ", game.crit_mult(), " atk ", game.attack())
	game.equip(game.bag.find("tridente_marea"))
	print("trident skill power ", base["sp"], " -> ", game.skill_power(), " mana ", game.max_mana)
	var drops := {}
	for i in 400:
		var e: String = game._roll_equipment(30)
		var sl: String = GameData.EQUIPMENT[e]["slot"]
		drops[sl] = int(drops.get(sl, 0)) + 1
	print("drop slots ", drops)
	await _key("character")
	await create_timer(0.3).timeout
	await _shot("d08_character")
	await _key("inventory")
	await create_timer(0.3).timeout
	await _shot("d09_inventory")
	for p in [game.save_path, game.backup_path]:
		if String(p).contains("test"): DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	quit()
