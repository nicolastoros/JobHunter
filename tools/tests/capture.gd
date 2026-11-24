extends SceneTree
## Loads scenes, simulates a bit of input and saves screenshots for review.

var out_dir := ""


func _initialize() -> void:
	out_dir = OS.get_environment("CAPTURE_DIR")
	_run.call_deferred()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _hold(action: String, frames: int) -> void:
	Input.action_press(action)
	await _frames(frames)
	Input.action_release(action)


func _tap(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	await _frames(2)
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)
	await _frames(1)


func _run() -> void:
	await _frames(5)
	var menu: Node = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	await _frames(80)
	await _shot("01_main_menu")
	menu.queue_free()
	await _frames(2)

	var market: Node = load("res://scenes/world/market.tscn").instantiate()
	root.add_child(market)
	current_scene = market
	await _frames(40)
	await _shot("02_market_spawn")
	var player: Node2D = market.get_node("Entities/Player")
	print("spawn ", player.global_position)
	# Walk north into the plaza.
	await _hold("move_up", 150)
	await _frames(30)
	print("after north ", player.global_position)
	await _shot("03_plaza")
	# Walk into the well from below: must be blocked.
	player.global_position = Vector2(384, 340)
	await _hold("move_up", 60)
	print("well test (should stop ~y=331+) ", player.global_position)
	# Run west along lane into stalls.
	player.global_position = Vector2(300, 300)
	await _hold("move_left", 200)
	print("west run ", player.global_position)
	await _frames(20)
	await _shot("04_west")
	# Go to the armoury trader and talk.
	player.global_position = Vector2(504, 236)
	await _hold("move_up", 10)
	await _frames(30)
	await _tap("interact")
	await _frames(90)
	await _shot("05_dialogue")
	await _tap("interact")
	await _frames(5)
	await _tap("interact")
	await _frames(10)
	print("dialogue closed, locked=", root.get_node("Game").input_locked)
	# Attack animation.
	await _tap("attack")
	await _frames(10)
	await _shot("06_attack")
	# North wall test.
	player.global_position = Vector2(150, 140)
	await _hold("move_up", 90)
	print("north wall (should stop ~y>=98) ", player.global_position)
	# East wall test.
	player.global_position = Vector2(700, 300)
	await _hold("move_right", 90)
	print("east wall (should stop ~x<=724) ", player.global_position)
	# South wall test.
	player.global_position = Vector2(200, 500)
	await _hold("move_down", 90)
	print("south wall (should stop ~y<=536) ", player.global_position)
	await _frames(20)
	await _shot("07_south")
	# South gate: blocked beyond map edge.
	player.global_position = Vector2(384, 540)
	await _hold("move_down", 120)
	print("south gate (should stop ~y<=576) ", player.global_position)
	await _frames(10)
	await _shot("08_gate_toast")
	await _tap("pause")
	await _frames(10)
	await _shot("09_pause")
	quit()
