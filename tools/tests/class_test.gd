extends SceneTree
## The three classes: for each one, its looks load (nine tiers), the basic attack hurts a monster
## (sword / arrow / fireball) and each of its six skills can be cast and does what it should near a pack
## of monsters. Takes pictures of the ranged attacks and the flashiest skills.
var out := ""


func _initialize() -> void:
	out = OS.get_environment("CAPTURE_DIR")
	_run.call_deferred()


func _p() -> Node2D:
	return current_scene.get_node("Entities/Player")


func _tap(a: String) -> void:
	var e := InputEventAction.new(); e.action = a; e.pressed = true; Input.parse_input_event(e)
	await physics_frame
	var r := InputEventAction.new(); r.action = a; r.pressed = false; Input.parse_input_event(r)


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(n + ".png"))


var _snap := {}


## Snapshot of the monsters around; then `_dealt()` = damage done to them since (deaths included).
func _pack_hp() -> int:
	_snap.clear()
	for m in get_nodes_in_group("monsters"):
		if (m as Node2D).global_position.distance_to(_p().global_position) < 300.0:
			_snap[m] = maxi(0, int(m.hp))
	return 0


func _dealt() -> int:
	var t := 0
	for m in _snap:
		t += int(_snap[m]) - (maxi(0, int(m.hp)) if is_instance_valid(m) else 0)
	return t


func _run() -> void:
	var game = root.get_node("Game")
	var errors := 0
	for cls in GameData.CLASS_ORDER:
		for tier in range(1, 10):
			if load(String(GameData.CLASSES[cls]["frames"]) % tier) == null:
				print("  !! missing look ", cls, " ", tier)
				errors += 1
	for cls in GameData.CLASS_ORDER:
		game.start_new_game(cls)
		await create_timer(0.5).timeout
		game.tutorial_step = 4
		game.level = 30
		game.recalc_stats()
		game.player_hp = game.max_hp
		game.daily = game._fresh_daily(); game.daily["day"] = game.today_key()
		for s in game.class_skills():
			game.skill_ranks[s["id"]] = 3
		game.pending_spawn = "start"
		change_scene_to_file("res://scenes/world/field.tscn")
		await create_timer(1.5).timeout
		_p().set("_invulnerable", 99999.0)
		# go next to a pack of gnolls
		var gn: Node2D = null
		for m in get_nodes_in_group("monsters"):
			if m.base_name == "Gnoll":
				gn = m
				break
		_p().global_position = gn.global_position + Vector2(-70, 0)
		_p().reset_physics_interpolation()
		_p().facing = "right"
		await create_timer(0.4).timeout
		var anim: String = _p().get_node("AnimatedSprite2D").sprite_frames.resource_path.get_file()
		var hp0 := _pack_hp()
		for i in 4:
			await _tap("attack")
			await create_timer(0.55).timeout
		await create_timer(0.6).timeout
		var basic := _dealt()
		print("%s: looks %s, basic attack took %d hp from the pack" % [cls, anim, basic])
		if basic <= 0:
			errors += 1
			print("  !! the basic attack did nothing")
		var k := 0
		for s in game.class_skills():
			k += 1
			var ok := false
			var note := ""
			for attempt in 3:
				game._skill_ready.clear()
				var tgt: Node2D = null
				for m in get_nodes_in_group("monsters"):
					if int(m.hp) > 0 and (tgt == null or m.global_position.distance_to(_p().global_position) < tgt.global_position.distance_to(_p().global_position)):
						tgt = m
				if tgt:
					_p().global_position = tgt.global_position + Vector2(-22 if cls == "guerrero" else -60, 0)
					_p().reset_physics_interpolation()
					_p().facing = "right"
					game.target = tgt
				await physics_frame
				game.mana = game.max_mana
				_pack_hp()
				var pos0: Vector2 = _p().global_position
				var hp_hero: int = game.player_hp
				game.player_hp = maxi(1, game.max_hp / 2)
				_p().cast_skill(String(s["id"]))
				await create_timer(0.35).timeout
				if attempt == 0 and s["id"] in ["lluvia", "meteoro", "rayo", "bola_fuego", "nova", "abanico"]:
					await _shot("cls_%s_%s" % [cls, s["id"]])
				await create_timer(1.0).timeout
				var dealt := _dealt()
				var moved: float = _p().global_position.distance_to(pos0)
				note = "dealt %d" % dealt
				if s["id"] in ["salto", "embestida", "parpadeo"]:
					note = "moved %d px" % int(moved)
				elif s["id"] in ["grito", "ojo_halcon"]:
					note = "buff %s" % game.buff_active()
				elif s["id"] in ["respiro", "barrera"]:
					note = "healed to %d/%d" % [game.player_hp, game.max_hp]
				ok = dealt > 0 or (s["id"] in ["salto", "embestida", "parpadeo"] and (moved > 20 or dealt > 0)) or (s["id"] in ["grito", "ojo_halcon"] and game.buff_active()) or (s["id"] in ["respiro", "barrera"] and game.player_hp > game.max_hp / 2)
				game.player_hp = hp_hero
				if ok:
					break
			print("   %d %s: %s" % [k, s["name"], note])
			if not ok:
				errors += 1
				print("     !! did nothing (3 tries)")
	print("class test errors ", errors)
	quit()
