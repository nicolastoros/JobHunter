extends SceneTree
var out := ""
func _initialize() -> void:
	out = OS.get_environment("CAPTURE_DIR")
	_run.call_deferred()
func _f(n: int) -> void:
	for i in n: await process_frame
func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(n + ".png"))
func _act(a: String) -> void:
	var e := InputEventAction.new(); e.action = a; e.pressed = true; Input.parse_input_event(e)
	await _f(2)
	var r := InputEventAction.new(); r.action = a; r.pressed = false; Input.parse_input_event(r)
	await _f(2)
func _p() -> Node2D:
	return current_scene.get_node("Entities/Player")
func _run() -> void:
	var game = root.get_node("Game")
	change_scene_to_file("res://scenes/ui/main_menu.tscn")
	await create_timer(0.6).timeout
	game.start_new_game()
	await create_timer(1.6).timeout
	print("1 start: ", current_scene.name, " pos ", _p().global_position.round(), " step ", game.tutorial_step)
	await _shot("j01_home")
	for n in current_scene.get_node("Entities").get_children():
		if n.has_method("interact") and n.get_script() and String(n.get_script().resource_path).ends_with("rest_spot.gd"):
			game.player_hp = 3
			n.interact(_p())
	await create_timer(0.4).timeout
	print("2 rest: hp ", game.player_hp, "/", game.max_hp, " save ", game.has_save())
	await _act("interact")
	# walk out of the door
	for n in current_scene.get_children():
		if n is Area2D and String(n.get("target_scene")).ends_with("world.tscn"):
			n._go()
	await create_timer(1.5).timeout
	print("3 outside: ", current_scene.name, " pos ", _p().global_position.round())
	await create_timer(1.6).timeout
	await _shot("j02_welcome")
	await create_timer(2.2).timeout
	await _shot("j03_messenger")
	print("   step ", game.tutorial_step, " objective '", game.objective_text(), "'")
	await _act("interact"); await _act("interact"); await _act("interact")
	# guild master
	change_scene_to_file("res://scenes/interiors/guild_1f.tscn")
	await create_timer(1.2).timeout
	for a in current_scene.get_node("Entities").find_children("*", "", true, false):
		if a.get("npc_name") != null and String(a.get("npc_name")).contains("Ysolde"):
			a.interact(_p())
	await create_timer(0.5).timeout
	print("4 license: step ", game.tutorial_step, " objective '", game.objective_text(), "'")
	await _shot("j04_ysolde")
	for i in 4: await _act("interact")
	game.accept_quest("slimes")
	print("5 quest: step ", game.tutorial_step)
	# field
	game.pending_spawn = "south"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.5).timeout
	game.input_locked = false
	print("6 field: step ", game.tutorial_step, " director ", current_scene.get_node_or_null("EventDirector") != null)
	var sl: Node2D = null
	for m in get_nodes_in_group("monsters"):
		if not m.boss and (sl == null or m.global_position.distance_to(_p().global_position) < sl.global_position.distance_to(_p().global_position)): sl = m
	_p().global_position = sl.global_position + Vector2(-60, 0); _p().reset_physics_interpolation()
	_p()._invulnerable = 999.0
	await create_timer(0.3).timeout
	await _act("target")
	var t1 = game.target
	await _act("target_next")
	print("7 target: ", t1 != null, " -> next ", game.target != null, " changed ", t1 != game.target)
	await _shot("j05_target")
	await _act("target")
	print("   tab again clears: ", game.target == null)
	# attack while walking
	Input.action_press("move_right")
	await create_timer(0.3).timeout
	var x0: float = _p().global_position.x
	await _act("attack")
	await _f(4)
	print("8 walk attack anim ", _p().sprite.animation, " still moving ", _p().global_position.x - x0 > 2.0)
	Input.action_release("move_right")
	await create_timer(0.6).timeout
	# world event
	var dir = current_scene.get_node("EventDirector")
	var boss: Node2D = dir.spawn_event()
	await create_timer(0.5).timeout
	print("9 event: ", boss.monster_name, " hp ", boss.hp, " lvl ", boss.monster_level, " scale ", boss.scale.x)
	await _shot("j06_event")
	await create_timer(6.0).timeout
	var chasing := 0
	for h in get_nodes_in_group("hunters"):
		if h._target == boss: chasing += 1
	print("   hunters on the colossus ", chasing, " boss hp ", boss.hp)
	_p().global_position = boss.global_position + Vector2(-40, 10); _p().reset_physics_interpolation()
	await create_timer(0.3).timeout
	var bag0: int = game.bag.size()
	var gold0: int = game.gold
	game.hit_monster(boss, 5, false, _p())
	boss.hp = 1
	game.hit_monster(boss, 5, false, _p())
	await create_timer(0.5).timeout
	print("   loot: bag ", bag0, " -> ", game.bag.size(), " gold +", game.gold - gold0, " renown ", game.renown)
	await _shot("j07_loot")
	# stable
	game.gold = 20000
	game.renown = 600
	game.ranks_rewarded = 2
	change_scene_to_file("res://scenes/world/world.tscn")
	await create_timer(1.5).timeout
	var keeper: Node2D = null
	for a in current_scene.get_node("Entities/Actors").get_children():
		if a.get("opens") == "stable": keeper = a
	_p().global_position = keeper.global_position + Vector2(0, 16); _p().reset_physics_interpolation()
	await create_timer(0.4).timeout
	keeper.interact(_p())
	await create_timer(0.4).timeout
	await _shot("j08_stable")
	print("10 buy mount ", game.buy_mount(), " fox ", game.buy_pet("zorro"), " boar ", game.buy_pet("jabali"), " active ", game.active_pet)
	current_scene.get_node("HUD/Stable").close_stable()
	await create_timer(0.5).timeout
	await _act("mount")
	Input.action_press("move_left")
	await create_timer(1.0).timeout
	print("   mounted ", game.mounted, " speed ", int(_p().velocity.length()), " pets ", get_nodes_in_group("pets").size())
	Input.action_release("move_left")
	await _shot("j09_mounted")
	await _act("ranking")
	await create_timer(0.4).timeout
	print("11 ranking anywhere: ", current_scene.get_node("HUD/QuestBoard")._root.visible)
	await _shot("j10_ranking")
	if String(game.save_path).contains("test"): DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	quit()
