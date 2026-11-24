extends SceneTree
## The post-game content: the Twilight Wastes (reached from Aurelia's east gate, its camp, waystone and
## safe haven, its monsters and bosses), the three new dungeons cleared end to end, and every monster
## that a dungeon summons exists in MonsterDefs.
var out := ""


func _initialize() -> void:
	out = OS.get_environment("CAPTURE_DIR")
	_run.call_deferred()


func _p() -> Node2D:
	return current_scene.get_node_or_null("Entities/Player")


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(n + ".png"))


func _run() -> void:
	var game = root.get_node("Game")
	var errors := 0
	for id in GameData.DUNGEONS:
		var d: Dictionary = GameData.DUNGEONS[id]
		for m in Array(d["pool"]) + [d["boss"]]:
			if not MonsterDefs.DEFS.has(m):
				print("  !! dungeon ", id, " summons unknown monster ", m)
				errors += 1
	for b in GameData.BESTIARY:
		if load(String(b["frames"])) == null:
			print("  !! bestiary frames missing for ", b["name"])
			errors += 1
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 80
	game.story_step = GameData.STORY_MAIN_STEPS
	game.recalc_stats()
	game.daily = game._fresh_daily(); game.daily["day"] = game.today_key()
	print("objective after the story: ", game.objective_text())
	# Aurelia's east gate leads to the Wastes
	game.pending_spawn = "east"
	change_scene_to_file("res://scenes/world/aurelia.tscn")
	await create_timer(1.6).timeout
	var gate: Node2D = null
	for n in current_scene.get_children():
		if n is Area2D and str(n.get("target_scene")).ends_with("ocaso.tscn"):
			gate = n
	print("east gate in Aurelia: ", gate != null)
	if gate == null:
		errors += 1
	else:
		_p().global_position = gate.global_position + Vector2(-30, 0)
		_p().reset_physics_interpolation()
		for i in 60:
			_p().velocity = Vector2(160, 0)
			_p().move_and_slide()
			await physics_frame
			if current_scene == null or current_scene.scene_file_path.get_file() != "aurelia.tscn":
				break
		await create_timer(2.5).timeout
	print("now in: ", game.map_file())
	if game.map_file() != "ocaso.tscn":
		errors += 1
		game.pending_spawn = "west"
		change_scene_to_file("res://scenes/world/ocaso.tscn")
		await create_timer(1.6).timeout
	await create_timer(1.0).timeout
	await _shot("oc_01_arrival")
	var counts := {}
	for m in get_nodes_in_group("monsters"):
		counts[m.monster_name] = int(counts.get(m.monster_name, 0)) + 1
	print("monsters: ", counts)
	var lv_ok := true
	for m in get_nodes_in_group("monsters"):
		if int(m.monster_level) < 72:
			lv_ok = false
	print("all monsters level 72+: ", lv_ok)
	var maren := false
	for n in current_scene.get_node("Entities").find_children("*", "", true, false):
		if str(n.get("npc_name")).contains("Maren"):
			maren = true
	print("Vigía Maren in the camp: ", maren, "  waystones: ", get_nodes_in_group("waystones").size(), "  safe spots: ", get_nodes_in_group("safe_spots").size())
	if not maren or get_nodes_in_group("safe_spots").is_empty():
		errors += 1
	# a walk around for pictures
	for spot in [Vector2(60, 58), Vector2(60, 20), Vector2(124, 44), Vector2(30, 92), Vector2(110, 80)]:
		var free: Vector2 = current_scene.call("_walkable_in", Rect2(spot * 16 - Vector2(64, 64), Vector2(128, 128)))
		if free == Vector2.INF:
			continue
		_p().global_position = free
		_p().reset_physics_interpolation()
		_p().set("_invulnerable", 99999.0)
		await create_timer(0.8).timeout
		await _shot("oc_spot_%d_%d" % [int(spot.x), int(spot.y)])
	# the three new dungeons
	for id in ["cloacas", "oasis_hundido", "fosa"]:
		var d: Dictionary = GameData.DUNGEONS[id]
		game.level = int(d["level"]) + 4
		game.recalc_stats()
		game.pending_spawn = "start"
		change_scene_to_file("res://scenes/world/" + String(d["map"]))
		await create_timer(1.5).timeout
		var portal: Node2D = null
		for n in get_nodes_in_group("dungeon_portals"):
			if n.dungeon_id == id:
				portal = n
		if portal == null:
			print("  !! no portal for ", id)
			errors += 1
			continue
		_p().global_position = portal.global_position + Vector2(0, 26)
		_p().reset_physics_interpolation()
		await create_timer(0.6).timeout
		await _shot("dg_%s_portal" % id)
		game.enter_dungeon(id, false)
		await create_timer(2.2).timeout
		_p().set("_invulnerable", 99999.0)
		var ctrl = current_scene.get_node("Dungeon")
		var boss_seen := false
		var g := 0
		while not ctrl._done and g < 500:
			g += 1
			await create_timer(0.25).timeout
			for m in get_nodes_in_group("monsters"):
				if m.monster_name == d["boss"] and int(m.hp) > 0 and not boss_seen:
					boss_seen = true
					await create_timer(0.8).timeout
					await _shot("dg_%s_boss" % id)
				if int(m.hp) > 0:
					game.hit_monster(m, 999999, false, _p())
		for c in get_nodes_in_group("chests"):
			c.interact(_p())
		await create_timer(1.0, true, false, true).timeout
		for c in game.get_children():
			if c.get_script() and String(c.get_script().resource_path).ends_with("dungeon_menu.gd"):
				c.close()
		print("%s (%s, level %d): cleared %s, boss %s seen %s, record %s" % [d["name"], d["theme"], game.dungeon_level(), ctrl._done, d["boss"], boss_seen, game.dungeon_records.get(id, {}).get("best", "-")])
		if not ctrl._done or not boss_seen:
			errors += 1
		game.leave_dungeon()
		await create_timer(1.6).timeout
	print("new content errors ", errors)
	quit()
