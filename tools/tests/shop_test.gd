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
	print("save path ", game.save_path)
	game.reset_progress()
	game.tutorial_step = 4
	# --- potions: capped at 3
	game.add_item("pocion", 5)
	print("cap: ", game.item_count("pocion"))
	# field: not safe at the gate, safe at the camp
	game.pending_spawn = "south"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.5).timeout
	game.inventory["pocion"] = 0
	await create_timer(1.2).timeout
	print("field gate safe ", game.is_safe_here(), " potions ", game.item_count("pocion"))
	_p().global_position = Vector2(1520, 440); _p().reset_physics_interpolation()
	await create_timer(1.2).timeout
	print("camp safe ", game.is_safe_here(), " potions ", game.item_count("pocion"))
	await _shot("s01_camp")
	# --- town refills
	game.inventory["pocion"] = 1
	change_scene_to_file("res://scenes/world/world.tscn")
	await create_timer(1.8).timeout
	print("town potions ", game.item_count("pocion"))
	# --- selling at Kara
	game.gold = 100
	game.add_item("gel", 10); game.add_item("piel", 3); game.add_item("nucleo", 1)
	game.bag.append("espada_acero"); game.bag.append("casco_hierro+2")
	var kara: Node2D = null
	for a in current_scene.get_node("Entities/Actors").get_children():
		if a.get("opens") == "forge": kara = a
	_p().global_position = kara.global_position + Vector2(0, 16); _p().reset_physics_interpolation()
	await create_timer(0.4).timeout
	game.forge_requested.emit()
	await create_timer(0.3).timeout
	var fg = current_scene.get_node("HUD/Forge")
	fg._selling = true
	fg._refresh()
	await _f(3)
	await _shot("s02_sell")
	print("sellables ", fg._sellables())
	fg._sell_key = "bag:1"
	fg._sell(false)
	print("sold helmet: gold ", game.gold, " bag ", game.bag)
	fg._sell_key = "inv:gel"
	fg._refresh()
	fg._sell(true)
	print("sold gel: gold ", game.gold, " gel ", game.item_count("gel"), " sel now ", fg._sell_key)
	await _f(3)
	await _shot("s03_sell2")
	print("pocion sellable? ", "inv:pocion" in fg._sellables())
	fg.close_forge()
	await create_timer(0.3).timeout
	# --- stable with new pets
	game.gold = 99999; game.renown = 99999
	game.ranks_rewarded = 99
	var atk0: int = game.attack()
	var hp0: int = game.max_hp
	for id in GameData.PETS:
		game.buy_pet(id)
	print("pets ", game.pets.size(), " active ", game.active_pet, " skill_power ", game.skill_power())
	game.set_active_pet("lobo")
	print("lobo atk ", atk0, " -> ", game.attack())
	game.set_active_pet("jabali_ebano")
	print("ebano hp ", hp0, " -> ", game.max_hp)
	game.stable_requested.emit()
	await create_timer(0.3).timeout
	var st = current_scene.get_node("HUD/Stable")
	st._sel = "lobo"; st._refresh()
	await _f(3)
	await _shot("s04_stable")
	st.close_stable()
	await create_timer(0.3).timeout
	for id in ["liebre", "urogallo", "lobo", "zorro_igneo"]:
		game.set_active_pet(id)
		await create_timer(0.3).timeout
		Input.action_press("move_left")
		await create_timer(0.8).timeout
		Input.action_release("move_left")
		await create_timer(0.4).timeout
	await _shot("s05_pet")
	for p in [game.save_path, game.backup_path]:
		if String(p).contains("test"): DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	quit()
