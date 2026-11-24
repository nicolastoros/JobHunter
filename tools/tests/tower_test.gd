extends SceneTree
## The Abyss Tower: locked before the end of the story, then climbed floor by floor (monsters killed
## outright, the chest opened, the portal up taken) up to floor 5, which has a boss. Checks the arena
## changes every floor, the level goes up, the record and the checkpoints, and legend levels past 99.
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
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 40
	game.recalc_stats()
	game.daily = game._fresh_daily(); game.daily["day"] = game.today_key()
	var errors := 0
	print("locked at level 40 mid-story: '", game.dungeon_block_reason("abismo", false), "'")
	if game.dungeon_block_reason("abismo", false) == "":
		errors += 1
	game.story_step = GameData.STORY.size()
	game.level = 80
	game.recalc_stats()
	print("open after the story: '", game.dungeon_block_reason("abismo", false), "'  checkpoint ", game.tower_checkpoint())
	game.pending_spawn = "start"
	change_scene_to_file("res://scenes/world/world.tscn")
	await create_timer(1.5).timeout
	var portal: Node2D = null
	for n in get_nodes_in_group("dungeon_portals"):
		if n.dungeon_id == "abismo":
			portal = n
	print("tower portal in the city: ", portal != null, " at ", Vector2i(portal.global_position / 16) if portal else Vector2i.ZERO)
	if portal == null:
		errors += 1
	else:
		_p().global_position = portal.global_position + Vector2(0, 30)
		_p().reset_physics_interpolation()
		await create_timer(0.5).timeout
		await _shot("tower_00_portal")
	game.enter_dungeon("abismo", false)
	var themes := []
	for f in 5:
		await create_timer(2.2).timeout
		var ctrl = current_scene.get_node_or_null("Dungeon")
		if ctrl == null:
			print("  !! no dungeon controller on floor ", game.tower_floor)
			errors += 1
			break
		_p().set("_invulnerable", 99999.0)
		themes.append(current_scene.scene_file_path.get_file().get_basename())
		var boss_seen := false
		var g := 0
		while not ctrl._done and g < 400:
			g += 1
			await create_timer(0.25).timeout
			for m in get_nodes_in_group("monsters"):
				if m.boss:
					boss_seen = true
				if int(m.hp) > 0:
					game.hit_monster(m, 999999, false, _p())
		var gold0: int = game.gold
		for c in get_nodes_in_group("chests"):
			c.interact(_p())
		await create_timer(1.2, true, false, true).timeout
		if f == 4:
			await _shot("tower_05_victory")
		for c in game.get_children():
			if c.get_script() and String(c.get_script().resource_path).ends_with("dungeon_menu.gd"):
				c.close()
		print("floor %d (%s): level %d, waves %d, boss %s, gold +%d, best %d" % [game.tower_floor, themes[-1], game.dungeon_level(), game.dungeon_waves(), boss_seen, game.gold - gold0, game.tower_best()])
		if (game.tower_floor % 5 == 0) != boss_seen:
			print("  !! boss expected only every 5 floors")
			errors += 1
		var up: Node2D = null
		for n in current_scene.get_node("Entities").get_children():
			if n.get("mode") == "next":
				up = n
		if f < 4:
			if up == null:
				print("  !! no portal up")
				errors += 1
				break
			up.interact(_p())
	print("themes climbed: ", themes)
	game.leave_dungeon()
	await create_timer(1.5).timeout
	print("back in ", game.map_file(), ", best floor ", game.tower_best(), ", checkpoint ", game.tower_checkpoint())
	game.stats["tower_best"] = 12
	print("with best 12 the climb starts at floor ", game.tower_checkpoint())
	if game.tower_checkpoint() != 11:
		errors += 1
	# legend levels
	game.level = 99
	var tp: int = game.talent_points
	game.add_xp(6000)
	print("legend level ", game.stats.get("legend_level", 0), ", talent points +", game.talent_points - tp)
	if int(game.stats.get("legend_level", 0)) < 2:
		errors += 1
	print("tower test errors ", errors)
	quit()
