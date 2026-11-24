extends SceneTree
var out := ""
func _initialize() -> void:
	out = OS.get_environment("CAPTURE_DIR")
	_run.call_deferred()
func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.crop(960, 540)
	var c := img.get_region(Rect2i(300, 120, 360, 260))
	c.resize(720, 520, Image.INTERPOLATE_NEAREST)
	c.save_png(out.path_join(n + ".png"))
func _p() -> Node2D:
	return current_scene.get_node("Entities/Player")
func _run() -> void:
	var game = root.get_node("Game")
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 14
	game.recalc_stats()
	game.pending_spawn = "south"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.5).timeout
	var sl: Node2D = null
	for m in get_nodes_in_group("monsters"):
		if m.monster_name == "Goblin" and (sl == null or m.global_position.distance_to(_p().global_position) < sl.global_position.distance_to(_p().global_position)): sl = m
	_p().global_position = sl.global_position + Vector2(-26, 2); _p().reset_physics_interpolation(); _p().get_node("Camera2D").reset_smoothing()
	_p()._invulnerable = 999.0
	sl.max_hp = 9999; sl.hp = 9999
	await create_timer(0.8).timeout
	_p().facing = "right"
	game.hit_monster(sl, 7, false, _p())
	await create_timer(0.06, true, false, true).timeout
	await _shot("i01_hit")
	await create_timer(0.25).timeout
	game.talents["golpe_certero"] = 99
	game.hit_monster(sl, 7, false, _p())
	await create_timer(0.05, true, false, true).timeout
	await _shot("i02_crit")
	await create_timer(0.12).timeout
	await _shot("i03_crit_later")
	quit()
