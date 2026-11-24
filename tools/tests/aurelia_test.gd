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
func _go(x: float, y: float) -> void:
	_p().global_position = Vector2(x * 16, y * 16); _p().reset_physics_interpolation(); _p().get_node("Camera2D").reset_smoothing()
	await create_timer(1.2).timeout
func _key(a: String) -> void:
	var e := InputEventAction.new(); e.action = a; e.pressed = true; Input.parse_input_event(e)
	await create_timer(0.1).timeout
	var r := InputEventAction.new(); r.action = a; r.pressed = false; Input.parse_input_event(r)
	await create_timer(0.4).timeout
func _run() -> void:
	var game = root.get_node("Game")
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 40
	game.recalc_stats()
	for m in ["world.tscn", "field.tscn", "desert.tscn"]: game.visited_maps[m] = true
	game.pending_spawn = "east"
	change_scene_to_file("res://scenes/world/desert.tscn")
	await create_timer(1.5).timeout
	print("desert east spawn ", _p().global_position)
	_p()._invulnerable = 9999.0
	Input.action_press("move_right")
	await create_timer(1.6).timeout
	Input.action_release("move_right")
	await create_timer(1.8).timeout
	print("walked east -> ", current_scene.scene_file_path.get_file(), " pos ", _p().global_position, " visited ", game.visited_maps.keys())
	await _shot("a00_gate")
	await create_timer(2.5).timeout
	print("walkers ", get_nodes_in_group("walkers").size() if get_nodes_in_group("walkers").size() > 0 else current_scene.find_children("*", "CharacterBody2D", true, false).size(), " hunters ", get_nodes_in_group("hunters").size(), " safe ", game.is_safe_here())
	await _go(99.5, 92)
	await _shot("a01_plaza")
	await _go(99.5, 50)
	await _shot("a02_palace")
	await _go(100, 118)
	await _shot("a03_market")
	await _go(60, 96)
	await _shot("a04_canal")
	await _go(165, 110)
	await _shot("a05_gardens")
	await _key("world_map")
	await create_timer(0.4, true, false, true).timeout
	await _shot("a06_worldmap")
	await _key("world_map")
	print("closed, paused ", paused)
	quit()
