extends SceneTree
## A wave dungeon from the portal to the chest, the story step it completes, and dying inside.
var out := ""


func _initialize() -> void:
	out = OS.get_environment("CAPTURE_DIR")
	_run.call_deferred()


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(n + ".png"))


func _p() -> Node2D:
	return current_scene.get_node("Entities/Player")


func _run() -> void:
	var game = root.get_node("Game")
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 16
	game.recalc_stats()
	game.daily = game._fresh_daily(); game.daily["day"] = game.today_key()
	game.story_step = 3   # "Supera la Cripta de las Ruinas"
	print("objective: ", game.objective_text())
	game.pending_spawn = "south"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.5).timeout
	var portal: Node2D = get_nodes_in_group("dungeon_portals")[0]
	_p().global_position = portal.global_position + Vector2(0, 20); _p().reset_physics_interpolation(); _p().get_node("Camera2D").reset_smoothing()
	await create_timer(0.6).timeout
	await _shot("d00_portal")
	portal.interact(_p())
	await create_timer(0.5, true, false, true).timeout
	await _shot("d01_menu")
	for c in game.get_children():
		if c.get_script() and String(c.get_script().resource_path).ends_with("dungeon_menu.gd"): c.close()
	game.enter_dungeon("ruinas", false)
	await create_timer(2.0).timeout
	print("in: ", current_scene.scene_file_path.get_file(), " dungeon ", game.current_dungeon, " can save ", game.can_save())
	_p().set("_invulnerable", 99999.0)
	var ctrl = current_scene.get_node("Dungeon")
	await create_timer(4.5).timeout
	await _shot("d02_wave1")
	var guard := 0
	while not ctrl._done and guard < 400:
		guard += 1
		await create_timer(0.3).timeout
		for m in get_nodes_in_group("monsters"):
			if int(m.hp) > 0 and randf() < 0.5:
				game.hit_monster(m, 9999, false, _p())
		if ctrl._wave == 5 and guard % 20 == 0:
			pass
		if guard == 60:
			await _shot("d03_fight")
	print("waves done ", ctrl._done, " wave ", ctrl._wave, " time ", int(ctrl._time), " hits ", ctrl._hits)
	await create_timer(1.0).timeout
	var chest: Node2D = null
	for c in get_nodes_in_group("chests"):
		chest = c
	print("chest ", chest != null)
	_p().global_position = chest.global_position + Vector2(0, 22); _p().reset_physics_interpolation()
	var bag0: int = game.bag.size()
	chest.interact(_p())
	await create_timer(1.2, true, false, true).timeout
	await _shot("d04_victory")
	print("bag +", game.bag.size() - bag0, " records ", game.dungeon_records, " story step ", game.story_step, " -> ", game.objective_text())
	for b in game.bag.slice(bag0):
		print("   got ", game.eq(b)["name"], " rarity ", game.eq_rarity(b))
	for c in game.get_children():
		if c.get_script() and String(c.get_script().resource_path).ends_with("dungeon_menu.gd"): c.close()
	game.leave_dungeon()
	await create_timer(1.8).timeout
	print("out: ", current_scene.scene_file_path.get_file(), " near portal ", _p().global_position.distance_to(portal.global_position if is_instance_valid(portal) else Vector2.ZERO) < 60 if is_instance_valid(portal) else (get_nodes_in_group("dungeon_portals")[0].global_position.distance_to(_p().global_position) < 60))
	# heroic now allowed; die inside
	print("heroic reason: '", game.dungeon_block_reason("ruinas", true), "'  eclipse reason: ", game.dungeon_block_reason("eclipse", false))
	game.enter_dungeon("ruinas", true)
	await create_timer(3.0).timeout
	print("heroic level ", game.dungeon_level())
	_p().set("_invulnerable", 0.0)
	game.player_hp = 1
	_p().take_damage(999, _p().global_position + Vector2(5, 0))
	await create_timer(4.0).timeout
	print("after dying: ", current_scene.scene_file_path.get_file(), " dungeon '", game.current_dungeon, "' hp ", game.player_hp)
	quit()
