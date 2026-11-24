extends SceneTree
## A visual tour of the new interface pieces: region card, objective star, hero aura, world map.
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
	game.level = 30
	game.recalc_stats()
	game.daily = game._fresh_daily(); game.daily["day"] = game.today_key()
	game.story_step = 1    # kill the Ruins Golem (in the field)
	game.bag.append("espada_alba+10"); game.equip(game.bag.find("espada_alba+10"))
	for e in ["yelmo_astado@4:hp=5", "coraza_templada@5:hp=5", "botas_igneas@6:hp=5"]:
		game.bag.append(e); game.equip(game.bag.find(e))
	change_scene_to_file("res://scenes/world/world.tscn")
	await create_timer(1.5).timeout
	# travel to the field through the game's own scene change (shows the region card)
	game.pending_spawn = "south"
	game.change_scene("res://scenes/world/field.tscn")
	await create_timer(0.75).timeout
	await _shot("u01_region_card")
	await create_timer(2.5).timeout
	await _shot("u02_objective_star")
	var e := InputEventAction.new(); e.action = "world_map"; e.pressed = true; Input.parse_input_event(e)
	await create_timer(0.5, true, false, true).timeout
	await _shot("u03_worldmap_objective")
	quit()
