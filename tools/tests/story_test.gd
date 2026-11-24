extends SceneTree
## The whole «Crónica del Quinto Viento», start to end: every step, the NPCs that exist in the maps,
## and the final dungeon with the Eclipse Devourer.
var out := ""


func _initialize() -> void:
	out = OS.get_environment("CAPTURE_DIR")
	_run.call_deferred()


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(n + ".png"))


func _p() -> Node2D:
	return current_scene.get_node_or_null("Entities/Player")


func _npc_exists(map: String, part: String, step: int) -> bool:
	for id in GameData.STORY_CAST:
		var c: Dictionary = GameData.STORY_CAST[id]
		if String(c["name"]).contains(part) and load("res://scripts/world/story_cast.gd").spot_of(id, map, step) != Vector2.INF:
			return true
	var path := ("res://scenes/interiors/" if map.begins_with("guild") else "res://scenes/world/") + map
	return FileAccess.get_file_as_string(path).contains(part)


func _run() -> void:
	var game = root.get_node("Game")
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 72
	game.recalc_stats()
	game.daily = game._fresh_daily(); game.daily["day"] = game.today_key()
	var guard := 0
	while game.story_current().size() > 0 and guard < 40:
		guard += 1
		var st: Dictionary = game.story_current()
		var before: int = game.story_step
		match String(st["kind"]):
			"talk":
				var ok := _npc_exists(String(st["map"]), String(st["target"]), before)
				var said: PackedStringArray = game.npc_override("Alguien " + String(st["target"]))
				print("step %d [talk %s] npc in map: %s, lines %d" % [before, st["target"], ok, said.size()])
			"kill":
				for k in int(st.get("n", 1)):
					game.story_event("kill", String(st["target"]))
				print("step %d [kill %s x%d]" % [before, st["target"], int(st.get("n", 1))])
			"visit":
				game.story_event("visit", String(st["target"]))
				print("step %d [visit %s]" % [before, st["target"]])
			"dungeon":
				print("step %d [dungeon %s] block: '%s'" % [before, st["target"], game.dungeon_block_reason(String(st["target"]), false)])
				if st["target"] == "eclipse":
					game.pending_spawn = "start"
					change_scene_to_file("res://scenes/world/aurelia.tscn")
					await create_timer(1.6).timeout
					game.enter_dungeon("eclipse", false)
					await create_timer(2.0).timeout
					_p().set("_invulnerable", 99999.0)
					var ctrl = current_scene.get_node("Dungeon")
					var g := 0
					var boss_seen := false
					while not ctrl._done and g < 500:
						g += 1
						await create_timer(0.3).timeout
						for m in get_nodes_in_group("monsters"):
							if m.monster_name == "Devorador de Eclipses" and not boss_seen and int(m.hp) > 0:
								boss_seen = true
								await create_timer(1.0).timeout
								await _shot("s01_devourer")
							if int(m.hp) > 0:
								game.hit_monster(m, 99999, false, _p())
					print("   eclipse cleared ", ctrl._done, " devourer seen ", boss_seen)
					for c in get_nodes_in_group("chests"):
						c.interact(_p())
					await create_timer(1.5, true, false, true).timeout
					await _shot("s02_eclipse_victory")
					for c in game.get_children():
						if c.get_script() and String(c.get_script().resource_path).ends_with("dungeon_menu.gd"): c.close()
				else:
					game.current_dungeon = String(st["target"])
					game.dungeon_rewards("A", 200.0)
					game.current_dungeon = ""
		if game.story_step == before:
			print("   !! the step did not advance")
			break
	print("story done ", game.stats.get("story_done", false), " title '", game.active_title, "' step ", game.story_step, "/", GameData.STORY.size(),
		" fragments ", game.item_count("frag_estrella"), game.item_count("frag_sol"), game.item_count("frag_luna"), " seal luck ", game.seal_luck())
	quit()
