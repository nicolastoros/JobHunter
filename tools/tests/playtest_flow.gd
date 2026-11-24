extends SceneTree
## Playtest: dying and waking up, houses in and out, save & load in every region, and a real fight.


func _initialize() -> void:
	_run.call_deferred()


func _p() -> Node2D:
	return current_scene.get_node_or_null("Entities/Player")


func _run() -> void:
	var game = root.get_node("Game")
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 12
	game.recalc_stats()
	game.daily = game._fresh_daily(); game.daily["day"] = game.today_key()
	# --- a real fight in the field: walk into a slime pack and swing
	game.pending_spawn = "south"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.5).timeout
	var target: Node2D = null
	for m in get_nodes_in_group("monsters"):
		if m.monster_name == "Limo" and (target == null or m.global_position.distance_to(_p().global_position) < target.global_position.distance_to(_p().global_position)):
			target = m
	_p().global_position = target.global_position + Vector2(-20, 0); _p().reset_physics_interpolation()
	_p().facing = "right"
	var k0: int = int(game.kills.get("Limo", 0))
	for i in 30:
		var e := InputEventAction.new(); e.action = "attack"; e.pressed = true; Input.parse_input_event(e)
		await create_timer(0.05).timeout
		var r := InputEventAction.new(); r.action = "attack"; r.pressed = false; Input.parse_input_event(r)
		await create_timer(0.35).timeout
		if int(game.kills.get("Limo", 0)) > k0:
			break
		if is_instance_valid(target) and target.hp > 0:
			_p().global_position = target.global_position + Vector2(-20, 0)
			_p().facing = "right"
	print("fight: killed a slime with the sword ", int(game.kills.get("Limo", 0)) > k0)
	# --- dying
	game.player_hp = 1
	_p().set("_invulnerable", 0.0)
	_p().take_damage(999, _p().global_position + Vector2(10, 0))
	await create_timer(4.5).timeout
	print("death: woke up in ", current_scene.scene_file_path.get_file(), " hp ", game.player_hp, "/", game.max_hp, " input locked ", game.input_locked)
	# --- houses: Valdoria -> guild -> back
	change_scene_to_file("res://scenes/world/world.tscn")
	await create_timer(1.5).timeout
	var door: Node = null
	for n in current_scene.get_children():
		if n.get_script() and String(n.get_script().resource_path).ends_with("door.gd") and String(n.get("label")).contains("Gremio"):
			door = n
	door._go()
	await create_timer(2.0).timeout
	print("door: inside ", current_scene.scene_file_path.get_file())
	for n in current_scene.get_children():
		if n is Area2D and String(n.get("target_scene")).ends_with("world.tscn"):
			n._go()
			break
	await create_timer(1.8).timeout
	print("door: back out in ", current_scene.scene_file_path.get_file(), " at ", (_p().global_position / 16).round(), " walkable ", current_scene.is_walkable(_p().global_position))
	# --- save & load in every region
	for m in ["forest.tscn", "desert.tscn", "aurelia.tscn", "snowforest.tscn", "snowvillage.tscn"]:
		game.pending_spawn = "start"
		change_scene_to_file("res://scenes/world/" + m)
		await create_timer(1.3).timeout
		var pos := _p().global_position
		game.save_game()
		game.load_game()
		await create_timer(1.6).timeout
		print("save/load ", m, ": back in ", current_scene.scene_file_path.get_file(), " same spot ", _p().global_position.distance_to(pos) < 4.0)
	for p in [game.save_path, game.backup_path]:
		if String(p).contains("test"): DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	quit()
