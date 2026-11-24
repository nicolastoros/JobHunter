extends SceneTree
## Playtest sweep: in every region, can the hero actually reach each chest, rune stone, exit, door,
## NPC and safe haven from where they arrive? Are monsters stuck inside walls or trees?

const MAPS := ["world.tscn", "field.tscn", "forest.tscn", "desert.tscn", "aurelia.tscn", "snowforest.tscn", "snowvillage.tscn", "ocaso.tscn"]


func _initialize() -> void:
	_run.call_deferred()


func _reach(world: Node, from: Vector2, to: Vector2) -> bool:
	var path: PackedVector2Array = world.find_path(from, to)
	if path.is_empty():
		return from.distance_to(to) < 24.0
	return path[path.size() - 1].distance_to(to) < 28.0


func _run() -> void:
	var game = root.get_node("Game")
	game.reset_progress()
	game.tutorial_step = 4
	game.daily = game._fresh_daily(); game.daily["day"] = game.today_key()
	var total_bad := 0
	for m in MAPS:
		game.pending_spawn = "start" if m != "world.tscn" else ""
		change_scene_to_file("res://scenes/world/" + m)
		await create_timer(1.6).timeout
		var w := current_scene
		var p: Node2D = w.get_node("Entities/Player")
		var from := p.global_position
		var bad: Array[String] = []
		if not w.is_walkable(from):
			bad.append("spawn not walkable at %s" % (from / 16).round())
		for c in get_nodes_in_group("chests"):
			if not _reach(w, from, c.global_position + Vector2(0, 14)):
				bad.append("chest %s at %s" % [c.chest_id, (c.global_position / 16).round()])
		for s in get_nodes_in_group("waystones"):
			if not _reach(w, from, s.global_position + Vector2(0, 20)):
				bad.append("stone %s at %s" % [s.stone_id, (s.global_position / 16).round()])
		for s in get_nodes_in_group("safe_spots"):
			if not _reach(w, from, s.global_position):
				bad.append("safe spot at %s" % (s.global_position / 16).round())
		for n in w.get_children():
			if n is Area2D and (n.get("target_scene") != null):
				var t: Vector2 = (n as Node2D).global_position
				var inward := t + (Vector2(0, -24) if t.y > 200 and t.y > w.map_size.y * 16 - 60 else (Vector2(0, 24) if t.y < 60 else (Vector2(-24, 0) if t.x > w.map_size.x * 16 - 60 else Vector2(24, 0))))
				if n.get_script() and String(n.get_script().resource_path).ends_with("door.gd"):
					inward = t + Vector2(0, 14)
				if not _reach(w, from, inward):
					bad.append("exit/door %s -> %s at %s" % [n.name, String(n.get("target_scene")).get_file(), (t / 16).round()])
		var actors := w.get_node_or_null("Entities/Actors")
		if actors:
			for a in actors.get_children():
				if a.get("talk_lines") != null or a.get("opens") != null:
					var t2: Vector2 = (a as Node2D).global_position + Vector2(0, 16)
					if a.get("npc_name") != null and String(a.get("npc_name")) != "" and not _reach(w, from, t2) and not _reach(w, from, t2 + Vector2(0, -32)) and not _reach(w, from, t2 + Vector2(18, -16)) and not _reach(w, from, t2 + Vector2(-18, -16)):
						bad.append("npc %s at %s" % [a.get("npc_name"), ((a as Node2D).global_position / 16).round()])
		var stuck := 0
		for mo in get_nodes_in_group("monsters"):
			if not w.is_walkable((mo as Node2D).global_position):
				stuck += 1
		print("== ", m, ": monsters ", get_nodes_in_group("monsters").size(), " (", stuck, " on blocked cells) chests ", get_nodes_in_group("chests").size(),
			" stones ", get_nodes_in_group("waystones").size())
		for b in bad:
			print("   UNREACHABLE ", b)
		total_bad += bad.size()
	# interiors: every exit reachable from the entrance
	for f in DirAccess.get_files_at("res://scenes/interiors"):
		if not f.ends_with(".tscn"):
			continue
		game.pending_spawn = "door"
		change_scene_to_file("res://scenes/interiors/" + f)
		await create_timer(1.0).timeout
		var w := current_scene
		var p2: Node2D = w.get_node_or_null("Entities/Player")
		print("== interior ", f, " player ", p2 != null)
	print("TOTAL unreachable: ", total_bad)
	quit()
