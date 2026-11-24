extends SceneTree
## The story's cast: for each place they show up in, sets the story there, walks in and takes a picture;
## checks every cast member is in the scene, on a walkable spot, and that talking to them works.
var out := ""


func _initialize() -> void:
	out = OS.get_environment("CAPTURE_DIR")
	_run.call_deferred()


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
	var cases := [[0, "guild_1f.tscn", "dario"], [2, "field.tscn", "brann"], [4, "field.tscn", "tova"], [5, "guild_2f.tscn", "seren"],
		[7, "field.tscn", "corvin"], [11, "guild_1f.tscn", "brann"], [13, "desert.tscn", "varian"], [23, "aurelia.tscn", "brann"],
		[27, "guild_1f.tscn", "dario"]]
	var cast_script = load("res://scripts/world/story_cast.gd")
	var errors := 0
	for c in cases:
		game.story_step = int(c[0])
		var map: String = c[1]
		var at: Vector2 = cast_script.spot_of(String(c[2]), map, int(c[0]))
		var dir := "res://scenes/interiors/" if map.begins_with("guild") else "res://scenes/world/"
		game.pending_spawn = "door" if map.begins_with("guild") else "start"
		change_scene_to_file(dir + map)
		await create_timer(1.4).timeout
		var p: Node2D = current_scene.get_node("Entities/Player")
		p.global_position = at + Vector2(0, 26)
		p.reset_physics_interpolation()
		await create_timer(0.9).timeout
		var here: Array = []
		for n in current_scene.get_node("Entities").get_children():
			if String(n.name).begins_with("Cast_"):
				here.append(String(n.name).substr(5))
				if current_scene.has_method("is_walkable") and not current_scene.is_walkable(n.global_position):
					print("   !! ", n.name, " on a blocked spot ", n.global_position / 16.0)
					errors += 1
		if not String(c[2]) in here:
			print("   !! missing ", c[2])
			errors += 1
		var who: Node = current_scene.get_node_or_null("Entities/Cast_" + String(c[2]))
		if who:
			who.interact(p)
		await create_timer(0.5).timeout
		await _shot("cast_%02d_%s_%s" % [int(c[0]), map.get_basename(), c[2]])
		print("step %d %s: cast here %s  objective: %s" % [c[0], map, here, game.objective_text()])
		for ui in game.get_children():
			if ui.has_method("close_dialogue"):
				ui.close_dialogue()
		var e := InputEventAction.new(); e.action = "ui_cancel"; e.pressed = true; Input.parse_input_event(e)
		await create_timer(0.2).timeout
	print("cast errors ", errors, " story step now ", game.story_step)
	quit()
