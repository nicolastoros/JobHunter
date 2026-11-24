extends SceneTree
var out := ""
func _initialize() -> void:
	out = OS.get_environment("CAPTURE_DIR")
	_run.call_deferred()
func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(n + ".png"))
func _run() -> void:
	change_scene_to_file("res://scenes/ui/main_menu.tscn")
	await create_timer(1.5).timeout
	await _shot("u01_menu")
	change_scene_to_file("res://scenes/interiors/guild_1f.tscn")
	await create_timer(1.0).timeout
	root.get_node("Game").quest_board_requested.emit()
	await create_timer(0.5).timeout
	await _shot("u02_board")
	var qb = current_scene.get_node("HUD/QuestBoard")
	qb.visible = false
	root.get_node("Game").input_locked = false
	var e := InputEventAction.new(); e.action = "pause"; e.pressed = true; Input.parse_input_event(e)
	await create_timer(0.5).timeout
	await _shot("u03_pause")
	quit()
