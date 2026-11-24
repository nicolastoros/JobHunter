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
	var chests := get_nodes_in_group("chests")
	print("chests: ", chests.size())
	await _shot("c01_minimap")
	# walk to the nearest chest and open it with E
	var ch: Node2D = chests[0]
	for c in chests:
		if c.global_position.distance_to(_p().global_position) < ch.global_position.distance_to(_p().global_position): ch = c
	_p().global_position = ch.global_position + Vector2(0, 14); _p().get_node("Camera2D").reset_smoothing()
	_p().facing = "up"
	await create_timer(0.4).timeout
	var bag0: int = game.bag.size()
	await _key("interact")
	await create_timer(0.8).timeout
	print("chest opened ", game.is_chest_opened(ch.chest_id), " bag ", bag0, " -> ", game.bag, " gold ", game.gold)
	await _shot("c02_chest")
	await _key("map")
	await create_timer(0.3).timeout
	await _shot("c03_bigmap")
	await _key("map")
	await create_timer(0.3).timeout
	# forge in town
	change_scene_to_file("res://scenes/world/world.tscn")
	await create_timer(1.2).timeout
	var kara: Node2D = null
	for a in current_scene.get_node("Entities/Actors").get_children():
		if a.get("opens") == "forge": kara = a
	print("kara found ", kara != null)
	_p().global_position = kara.global_position + Vector2(0, 16); _p().get_node("Camera2D").reset_smoothing()
	_p().facing = "up"
	await create_timer(0.5).timeout
	game.gold = 2000
	game.add_item("gel", 20); game.add_item("abalorio", 4); game.add_item("piel", 2)
	await _key("interact")
	await create_timer(0.4).timeout
	var atk0: int = game.attack()
	await _shot("c04_forge")
	var fg = current_scene.get_node("HUD/Forge")
	print("forge open ", fg._root.visible, " slot ", fg._slot)
	for i in 4:
		print("upgrade ", game.forge_upgrade("weapon"), " -> ", game.equipped["weapon"])
	print("atk ", atk0, " -> ", game.attack(), " gold ", game.gold, " gel ", game.item_count("gel"))
	fg._refresh()
	await _f(3)
	await _shot("c05_forge2")
	fg.close_forge()
	await create_timer(0.3).timeout
	game.save_game()
	game.equipped["weapon"] = "espada_corta"
	game.opened_chests = {}
	game.load_game()
	await create_timer(1.5).timeout
	print("loaded weapon ", game.equipped["weapon"], " chests opened ", game.opened_chests.size(), " scene ", current_scene.name)
	if String(game.save_path).contains("test"): DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	quit()
