extends SceneTree
var out := ""
func _initialize() -> void:
	out = OS.get_environment("CAPTURE_DIR")
	_run.call_deferred()
func _run() -> void:
	var game = root.get_node("Game")
	game.tutorial_step = 4
	game.pets.append("zorro")
	game.active_pet = "zorro"
	game.pending_spawn = "south"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.5).timeout
	var pet: Node2D = get_nodes_in_group("pets")[0]
	var sp: AnimatedSprite2D = pet.get_child(0)
	for step in [["move_up", 2.0, false], ["move_right", 1.5, false], ["move_down", 1.5, false], ["move_left", 2.0, true], ["", 1.0, false]]:
		var turns := 0
		var backwards := 0
		var anim_changes := 0
		var last_f: String = pet._facing
		var last_a := sp.animation
		if step[0] != "": Input.action_press(step[0])
		if step[2]: Input.action_press("run")
		var t := 0.0
		while t < step[1]:
			await physics_frame
			t += 1.0 / 60.0
			if pet._facing != last_f: turns += 1; last_f = pet._facing
			var fv: Vector2 = {"down": Vector2.DOWN, "up": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT}[pet._facing]
			if pet._vel.length() > 15.0 and pet._vel.normalized().dot(fv) < -0.3: backwards += 1
			if step[0] == "move_down" and int(t * 60) % 15 == 0:
				var pl: Node2D = current_scene.get_node("Entities/Player")
				print("   t ", snappedf(t, 0.01), " vel ", pet._vel.round(), " moving ", pet._moving, " player facing ", pl.facing, " pl vel ", pl.velocity.round())
			if sp.animation != last_a: anim_changes += 1; last_a = sp.animation
		if step[0] != "": Input.action_release(step[0])
		Input.action_release("run")
		var p: Node2D = current_scene.get_node("Entities/Player")
		print(step[0] if step[0] != "" else "stop", ": turns ", turns, " backwards frames ", backwards, " anim changes ", anim_changes, " facing ", pet._facing, " dist ", int(pet.global_position.distance_to(p.global_position)))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("pet.png"))
	quit()
