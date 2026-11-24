extends SceneTree
## Seals, sets and forge effects.
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
	game.reset_progress()
	game.tutorial_step = 4
	game.level = 60
	game.recalc_stats()
	game.daily = game._fresh_daily(); game.daily["day"] = game.today_key()
	# rarity odds over many rolls, with high luck
	var counts := [0, 0, 0, 0, 0, 0, 0]
	for i in 20000:
		counts[game._roll_rarity(3.0)] += 1
	print("rarity with luck 3 over 20000: ", counts)
	# forced seals of each tier
	var seals := []
	for tier in [4, 5, 6]:
		var pc: String = ["espada_alba", "yelmo_astado", "espada_alba"][tier - 4] + "@%d:atk=6,crit=0.04,hp=20,gold=0.1,xp=0.05" % tier
		seals.append(pc)
		print("seal ", tier, ": ", game.eq(pc)["name"], " | ", game.eq(pc).get("atk", game.eq(pc).get("def", 0)), " | affixes ", game.eq_affixes(pc).size())
	# a full set
	var set_pieces := []
	for sl in ["helmet", "chest", "gloves", "boots"]:
		var piece := "set_invierno_%s@2:hp=10" % sl
		game.bag.append(piece)
		game.equip(game.bag.find(piece))
	var hp0: int = game.max_hp
	print("set counts ", game.set_counts(), " guard ", game.tsum("guard"), " lifesteal ", game.tsum("lifesteal"), " hp_pct ", game.tsum("hp_pct"))
	# a +10 sword (Filo ardiente) and a hammer +8
	game.bag.append("espada_alba+10")
	game.equip(game.bag.find("espada_alba+10"))
	print("weapon fx: ", game.gear_extra_text("espada_alba+10"))
	print("hammer +4: ", game.gear_extra_text("martillo_runico+4"))
	print("armor +5 helmet crit: ", game.eq("yelmo_astado+5").get("crit", 0.0))
	# hit a monster until the effect shows
	game.pending_spawn = "south"
	change_scene_to_file("res://scenes/world/field.tscn")
	await create_timer(1.5).timeout
	var m: Node2D = null
	for mo in get_nodes_in_group("monsters"):
		if mo.monster_name == "Gnoll" and (m == null or mo.global_position.distance_to(_p().global_position) < m.global_position.distance_to(_p().global_position)):
			m = mo
	m.max_hp = 99999; m.hp = 99999
	_p().global_position = m.global_position + Vector2(-24, 0); _p().reset_physics_interpolation(); _p().get_node("Camera2D").reset_smoothing()
	_p().set("_invulnerable", 9999.0)
	# wear the sun seal too
	game.bag.append(seals[2]); game.equip(game.bag.find(seals[2]))
	print("sun seals worn ", game.seal_count(6))
	await create_timer(0.5).timeout
	for i in 25:
		game.hit_monster(m, 10, false, _p())
		await create_timer(0.08).timeout
	await create_timer(0.3).timeout
	print("dots on the gnoll ", m._dots.size(), " hp lost ", 99999 - m.hp)
	await _shot("g01_procs")
	# star seal falling star
	game._star_fall(m.global_position, 50)
	await create_timer(0.4).timeout
	await _shot("g02_star")
	# menus: character with a seal selected
	game.bag.append(seals[0])
	await create_timer(0.8).timeout
	var e := InputEventAction.new(); e.action = "character"; e.pressed = true; Input.parse_input_event(e)
	await create_timer(0.4, true, false, true).timeout
	var gm = null
	for c in current_scene.get_node("HUD").get_children():
		if c.get("_bag_sel") != null: gm = c
	gm._bag_sel = game.bag.find(seals[0]); gm._refresh_character()
	await create_timer(0.3, true, false, true).timeout
	await _shot("g03_seal_tooltip")
	gm._bag_sel = game.bag.find("set_invierno_helmet@2:hp=10") if game.bag.has("set_invierno_helmet@2:hp=10") else 0
	gm._refresh_character()
	await create_timer(0.2, true, false, true).timeout
	await _shot("g04_menu")
	quit()
