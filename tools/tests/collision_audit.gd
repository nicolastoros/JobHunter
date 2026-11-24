extends SceneTree
## Collision audit of every outdoor region:
##  1. the walk mask (used by monsters, hunters and walkers) against the live collision shapes:
##     cells the mask calls free but a wall is there (things would walk into it and get stuck);
##  2. spawns, exits, waystones, chests and actors standing inside a wall;
##  3. the map's edges: the hero pushed against each border for a while must not leave the map;
##  4. props drawn tall (trees, houses, rocks...) that have no collision at all.
const MAPS := ["world.tscn", "field.tscn", "forest.tscn", "desert.tscn", "aurelia.tscn", "snowforest.tscn", "snowvillage.tscn", "ocaso.tscn"]
var out := ""


func _initialize() -> void:
	out = OS.get_environment("CAPTURE_DIR")
	_run.call_deferred()


## Only what the map itself is made of counts as a wall when `map_only` (not chests, rune stones,
## portals... spawned at runtime on top of it).
func _blocked(space: PhysicsDirectSpaceState2D, p: Vector2, size := 6.0, map_only := false) -> bool:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(size, size)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.collision_mask = 1
	q.collide_with_areas = false
	q.transform = Transform2D(0, p)
	for hit in space.intersect_shape(q, 4):
		var c: Object = hit["collider"]
		if c is CharacterBody2D:
			continue   # the hero, monsters, walkers: they move
		if map_only and (c as Node).owner != current_scene:
			continue
		return true
	return false


func _run() -> void:
	var game = root.get_node("Game")
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 40
	game.recalc_stats()
	game.daily = game._fresh_daily(); game.daily["day"] = game.today_key()
	var total := 0
	for map in MAPS:
		game.pending_spawn = "start"
		change_scene_to_file("res://scenes/world/" + map)
		await create_timer(1.6).timeout
		var w: Node2D = current_scene
		var space := w.get_world_2d().direct_space_state
		var nav: AStarGrid2D = w.nav
		var bad_free := 0
		var samples: Array = []
		var reg := nav.region
		for y in range(1, reg.size.y - 1):
			for x in range(1, reg.size.x - 1):
				if nav.is_point_solid(Vector2i(x, y)):
					continue
				var p := Vector2(x * 8 + 4, y * 8 + 4)
				if _blocked(space, p, 4.0, true):
					bad_free += 1
					if samples.size() < 6:
						samples.append(Vector2i(p / 16.0))
		# 2. things standing inside walls
		var stuck: Array = []
		var used_spawns := {"start": true, "respawn": true}
		for f in DirAccess.get_files_at("res://scenes/interiors"):
			if f.ends_with(".tscn"):
				for m in RegEx.create_from_string('target_spawn = "([^"]+)"').search_all(FileAccess.get_file_as_string("res://scenes/interiors/" + f)):
					used_spawns[m.get_string(1)] = true
		for f in MAPS:
			for m in RegEx.create_from_string('target_spawn = "([^"]+)"').search_all(FileAccess.get_file_as_string("res://scenes/world/" + f)):
				used_spawns[m.get_string(1)] = true
		for n in w.get_node("Spawns").get_children():
			if not used_spawns.has(String(n.name)):
				continue   # nothing leads here
			if _blocked(space, n.global_position, 4.0):
				stuck.append("spawn %s" % n.name)
		for n in w.get_node("Entities").get_children():
			var kind := ""
			if n.is_in_group("waystones"): kind = "piedra"
			elif n.is_in_group("chests"): kind = "cofre"
			elif str(n.get("npc_name")) not in ["", "<null>"] and n.get("collide") == false: kind = "npc"
			var reachable := false
			for d in [Vector2.ZERO, Vector2(0, 16), Vector2(0, -16), Vector2(16, 0), Vector2(-16, 0)]:
				if w.is_walkable(n.global_position + d):
					reachable = true
			if kind != "" and not reachable:
				stuck.append("%s %s @%s" % [kind, n.get("npc_name") if kind == "npc" else n.name, Vector2i(n.global_position / 16.0)])
		for n in w.get_children():
			if n is Area2D and str(n.get("target_scene")) not in ["", "<null>"]:
				var ok := false
				for d in [Vector2.ZERO, Vector2(0, 16), Vector2(0, -16), Vector2(16, 0), Vector2(-16, 0)]:
					if w.is_walkable(n.global_position + d):
						ok = true
				if not ok:
					stuck.append("salida %s @%s" % [n.name, Vector2i(n.global_position / 16.0)])
		# 3. the edges
		var p: CharacterBody2D = w.get_node("Entities/Player")
		p.set("_invulnerable", 99999.0)
		var size := Vector2(w.map_size) * 16.0
		var leaks: Array = []
		for side in [[Vector2(0.5, 0.0), Vector2.UP], [Vector2(0.5, 1.0), Vector2.DOWN], [Vector2(0.0, 0.5), Vector2.LEFT], [Vector2(1.0, 0.5), Vector2.RIGHT]]:
			for along in [0.2, 0.5, 0.8]:
				var anchor: Vector2 = side[0]
				var start := Vector2(size.x * (along if anchor.x == 0.5 else anchor.x), size.y * (along if anchor.y == 0.5 else anchor.y))
				start -= (side[1] as Vector2) * 40.0
				var free: Vector2 = w._walkable_in(Rect2(start - Vector2(40, 40), Vector2(80, 80)))
				if free == Vector2.INF:
					continue
				p.global_position = free
				p.velocity = Vector2.ZERO
				for f in 50:
					p.velocity = (side[1] as Vector2) * 300.0
					p.move_and_slide()
				var q := p.global_position
				if q.x < -2 or q.y < -2 or q.x > size.x + 2 or q.y > size.y + 2:
					var by_exit := false
					for e in w.get_children():
						if e is Area2D and str(e.get("target_scene")) not in ["", "<null>"] and (e as Node2D).global_position.distance_to(q.clamp(Vector2.ZERO, size)) < 96.0:
							by_exit = true
					if not by_exit:
						leaks.append(Vector2i(q / 16.0))
		# 4. tall props with no collision
		var ghost := 0
		var ghost_s: Array = []
		for n in w.get_node("Entities").get_children():
			if n.get_class() != "StaticBody2D" and not (n is Node2D and n.get_child_count() > 0):
				continue
			var spr := n.get_node_or_null("Sprite2D") as Sprite2D
			if spr == null or not spr.region_enabled or spr.region_rect.size.y < 40 or spr.region_rect.size.x < 24:
				continue
			var has_shape := false
			for c in n.get_children():
				if c is CollisionShape2D or c is CollisionPolygon2D:
					has_shape = true
			if not has_shape and n.get_node_or_null("Shape") == null:
				ghost += 1
				if ghost_s.size() < 5:
					ghost_s.append("%s @%s" % [n.name, Vector2i(n.global_position / 16.0)])
		var errs: int = (1 if bad_free > 10 else 0) + stuck.size() + leaks.size()
		total += errs
		print("%s: celdas libres con pared %d %s | atascados %s | fugas por el borde %s | props altos sin colisión %d %s" % [map, bad_free, samples, stuck, leaks, ghost, ghost_s])
	print("collision audit problems ", total)
	quit()
