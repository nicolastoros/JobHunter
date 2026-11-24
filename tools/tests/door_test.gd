extends SceneTree
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
	game.tutorial_step = 4
	for dn in ["Door_door_1", "Door_door_2", "Door_door_0", "Door_door_5"]:
		change_scene_to_file("res://scenes/world/world.tscn")
		await create_timer(1.0).timeout
		var d: Area2D = current_scene.get_node(dn)
		_p().global_position = d.global_position + Vector2(0, 12); _p().reset_physics_interpolation()
		_p().get_node("Camera2D").reset_smoothing()
		game.input_locked = false
		await create_timer(0.4).timeout
		d._go()
		await create_timer(0.3).timeout
		await _shot("d_%s_a" % dn)
		await create_timer(0.15).timeout
		await _shot("d_%s_b" % dn)
		await create_timer(1.2).timeout
		print(dn, " -> ", current_scene.name, " pos ", _p().global_position.round())
		# walk straight out again
		Input.action_press("move_down")
		await create_timer(1.6).timeout
		Input.action_release("move_down")
		await create_timer(1.2).timeout
		print("   walked out -> ", current_scene.name)
	quit()
