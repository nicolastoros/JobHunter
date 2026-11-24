extends SceneTree
var out := ""
var sc := 1.0
func _initialize() -> void:
	out = OS.get_environment("CAPTURE_DIR")
	_run.call_deferred()
func _f(n: int) -> void:
	for i in n: await process_frame
func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(n + ".png"))
func _touch(i: int, p: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new(); e.index = i; e.position = p * sc; e.pressed = pressed
	Input.parse_input_event(e)
func _drag(i: int, p: Vector2) -> void:
	var e := InputEventScreenDrag.new(); e.index = i; e.position = p * sc
	Input.parse_input_event(e)
func _run() -> void:
	var tag := OS.get_environment("TAG")
	load("res://scripts/ui/touch_controls.gd").force = true
	var game = root.get_node("Game")
	game.reset_progress()
	game.pending_spawn = "south"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.5).timeout
	var vp: Vector2 = root.get_visible_rect().size
	var win := Vector2(DisplayServer.window_get_size())
	sc = win.y / vp.y
	print(tag, " window ", win, " base viewport ", vp, " scale ", snappedf(sc, 0.01))
	var p = current_scene.get_node("Entities/Player")
	var p0: Vector2 = p.global_position
	# joystick: press on the left and drag up
	_touch(0, Vector2(60, vp.y - 60), true)
	await _f(2)
	_drag(0, Vector2(60, vp.y - 60 - 20))
	await create_timer(0.8).timeout
	print("joystick moved ", int(p0.distance_to(p.global_position)), "px  running ", Input.is_action_pressed("run"))
	_drag(0, Vector2(60, vp.y - 60 - 40))
	await create_timer(0.5).timeout
	print("full push running ", Input.is_action_pressed("run"))
	await _shot("t_%s_play" % tag)
	_touch(0, Vector2(60, vp.y - 100), false)
	await _f(3)
	# attack button
	_touch(1, Vector2(vp.x - 38, vp.y - 46), true)
	await _f(3)
	print("attack state ", p.state)
	_touch(1, Vector2(vp.x - 38, vp.y - 46), false)
	await create_timer(0.5).timeout
	# potion slot on the action bar
	game.player_hp = 3
	var bar: Control = current_scene.get_node("HUD/PlayerHud").action_bar
	var r := bar.get_global_rect()
	_touch(2, r.position + Vector2(3 + 16 + 8, 10), true)
	await _f(3)
	_touch(2, r.position + Vector2(3 + 16 + 8, 10), false)
	print("potion slot: hp ", game.player_hp, " bar at ", r)
	# menu button
	_touch(3, Vector2(18, 64), true)
	await _f(3)
	_touch(3, Vector2(18, 64), false)
	await create_timer(0.3).timeout
	print("menu open ", game.menu_open)
	await _shot("t_%s_menu" % tag)
	quit()
