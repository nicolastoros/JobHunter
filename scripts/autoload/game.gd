extends Node
## Global game state: scene transitions, settings, the hero's progression (level, items,
## equipment, skills, talents), saving / autosave and the UI event bus.
## Static data (items, equipment, skills...) lives in GameData (scripts/data/game_data.gd).

signal dialogue_requested(speaker: String, lines: PackedStringArray)
signal dialogue_finished
signal toast_requested(text: String)
signal location_entered(location_name: String)
signal quest_board_requested
signal quests_changed
signal stats_changed
signal forge_requested
signal look_changed
signal boss_engaged(monster: Node)
signal monster_killed(monster: Node)

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const FIRST_LEVEL := "res://scenes/world/world.tscn"
const SETTINGS_PATH := "user://settings.cfg"
const SAVE_PATH := "user://partida.json"
const SAVE_VERSION := 2
## Seconds between automatic saves while playing.
const AUTOSAVE_INTERVAL := 180.0

## True while a dialogue or menu should block player input.
var input_locked := false

## Developer map editor ------------------------------------------------------
const DEV_PASSWORD_SHA256 := "c384eb6226bf1f9ebc7ce8897ce70bcbfa9834327b2cf02e3414b0d1b84cd63a"
const EDITOR_SCENE := "res://scenes/editor/map_editor.tscn"
## True while the map editor is open: NPCs and animals freeze.
var editing := false

## Spawn marker the next loaded scene should place the player at.
var pending_spawn := ""
## Exact position for the player in the next scene (used when loading a save).
var pending_position := Vector2.INF
## Exterior door to return to when leaving an interior.
var return_spawn := ""

# --- Hero ------------------------------------------------------------------------
var gold := 120
var level := 1
var xp := 0
## Skill experience: earned by hunting, spent to learn and improve skills.
var skill_xp := 0
var talent_points := 0
var max_hp := 10
var player_hp := 10
var max_stamina := 100.0
var stamina := 100.0
var max_mana := 50.0
var mana := 50.0
var inventory := {}
## Equipment pieces carried but not worn (ids, may repeat).
var bag: Array[String] = []
var equipped := {}
## Chests already opened (chest id -> true).
var opened_chests := {}
## Hunters' Guild: renown, ranks already rewarded, renown other hunters earned in front of you,
## and the three repeatable contracts.
var renown := 0
var ranks_rewarded := 0
var npc_renown := {}
var contracts: Array = []
var _streak := 0
var _streak_until := 0.0
var skill_ranks := {}
## Talent tree ranks (node id -> rank) and points in the three main attributes.
var talents := {}
var attributes := {"vida": 0, "energia": 0, "magia": 0}
var kills := {}
var play_time := 0.0
## True while the inventory / character menu is open.
var menu_open := false
## Game time in seconds; stops while the game is paused (cooldowns and buffs use it).
var clock := 0.0
var _skill_ready := {}
var _buff_until := 0.0
var _buff_bonus := 0
var _autosave_left := AUTOSAVE_INTERVAL
var _lifesteal_acc := 0.0
var potions: int:
	get:
		return item_count("pocion")

var quests: Array[Dictionary] = [
	{"id": "slimes", "rank": "E", "title": "Limos en el camino", "giver": "Guardia de la puerta norte", "zone": "Llanura de Valdoria",
	 "desc": "Varios limos bloquean el camino al norte de la ciudad. Elimina 5 para que los viajeros puedan pasar.", "reward": 40, "xp": 30, "target": ["Limo", 5], "state": "open"},
	{"id": "hares", "rank": "E", "title": "Liebres en los cultivos", "giver": "Tomás el frutero", "zone": "Granjas del Este",
	 "desc": "Las liebres se están comiendo los repollos de las granjas. Ahuyéntalas antes de que arruinen la cosecha.", "reward": 50, "state": "soon"},
	{"id": "goblins", "rank": "D", "title": "El campamento goblin", "giver": "Capitana Brenna", "zone": "Llanura de Valdoria",
	 "desc": "Un grupo de goblins acampa al oeste de la llanura y asalta a los viajeros. Derrota a 6 para dispersarlos.", "reward": 120, "xp": 80, "target": ["Goblin", 6], "state": "open"},
	{"id": "gnolls", "rank": "D", "title": "Gnolls en las colinas", "giver": "Gremio de Cazadores", "zone": "Llanura de Valdoria",
	 "desc": "Se han visto gnolls cerca de las colinas del este. Son rápidos y atacan en grupo. Abate a 5.", "reward": 150, "xp": 110, "target": ["Gnoll", 5], "state": "open"},
	{"id": "pier", "rank": "C", "title": "Algo bajo el muelle", "giver": "Pescador Ulrik", "zone": "Puerto de Valdoria",
	 "desc": "Las redes aparecen rotas cada mañana y nadie sabe por qué. Investiga qué ocurre bajo el muelle.", "reward": 300, "state": "soon"},
	{"id": "golem", "rank": "B", "title": "El guardián de las ruinas", "giver": "Maestra del Gremio Ysolde", "zone": "Llanura de Valdoria",
	 "desc": "Un gólem de piedra despertó en las ruinas del centro de la llanura. Nadie que se haya acercado ha vuelto ileso.", "reward": 600, "xp": 300, "target": ["Gólem de las Ruinas", 1], "state": "open"},
	{"id": "ent", "rank": "B", "title": "El árbol que camina", "giver": "Morga la vidente", "zone": "Llanura de Valdoria",
	 "desc": "En el bosque del noroeste hay un árbol antiguo que se mueve de noche. Las cartas dicen que protege algo.", "reward": 800, "xp": 350, "target": ["Ent Ancestral", 1], "state": "open"},
	{"id": "slimeking", "rank": "B", "title": "El rey del pantano", "giver": "Alquimista Odile", "zone": "Llanura de Valdoria",
	 "desc": "En el pantano del norte hay un limo enorme que se traga a los demás. Necesito lo que quede de él.", "reward": 700, "xp": 320, "target": ["Rey Limo", 1], "state": "open"},
]

var settings := {
	"master_volume": 0.8,
	"fullscreen": false,
}

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fade()
	load_settings()
	reset_progress()


func _process(delta: float) -> void:
	if get_tree().paused or editing:
		return
	clock += delta
	if _in_gameplay():
		play_time += delta
		_autosave_left -= delta
		if _autosave_left <= 0.0:
			_autosave_left = AUTOSAVE_INTERVAL
			if can_save():
				save_game(true)
	if mana < max_mana:
		mana = minf(mana + mana_regen() * delta, max_mana)
		stats_changed.emit()


func _build_fade() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.05, 0.03, 0.04, 1.0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a = 0.0
	_fade_layer.add_child(_fade_rect)


func change_scene(path: String, duration := 0.35) -> void:
	if _busy:
		return
	_busy = true
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, duration)
	await tween.finished
	get_tree().paused = false
	input_locked = false
	menu_open = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, duration)
	await tween.finished
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func start_new_game() -> void:
	reset_progress()
	pending_spawn = ""
	return_spawn = ""
	pending_position = Vector2.INF
	change_scene(FIRST_LEVEL)


## Moves to another scene and places the player at the named spawn marker.
func travel(scene_path: String, spawn: String, remember_return := "") -> void:
	if remember_return != "":
		return_spawn = remember_return
	pending_spawn = spawn
	change_scene(scene_path, 0.25)


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


func _in_gameplay() -> bool:
	return _player() != null and not editing


# =============================================================================
# Progression
# =============================================================================

func reset_progress() -> void:
	gold = 120
	level = 1
	xp = 0
	skill_xp = 0
	talent_points = 0
	inventory = {"pocion": 3, "manzana": 2}
	bag.clear()
	equipped = GameData.START_EQUIPMENT.duplicate()
	opened_chests = {}
	renown = 0
	ranks_rewarded = 0
	npc_renown = {}
	_streak = 0
	contracts = []
	for i in 3:
		contracts.append(_new_contract())
	skill_ranks = {}
	talents = {}
	attributes = {"vida": 0, "energia": 0, "magia": 0}
	talent_points = GameData.TALENT_POINTS_PER_LEVEL
	kills = {}
	play_time = 0.0
	_skill_ready = {}
	_buff_until = 0.0
	for q in quests:
		q["state"] = "soon" if not q.has("target") else "open"
		q["progress"] = 0
	recalc_stats()
	player_hp = max_hp
	stamina = max_stamina
	mana = max_mana


func xp_to_next() -> int:
	return GameData.xp_to_next(level)


## Sprite tier (1-7) of the hero's current look.
func look_tier() -> int:
	return int(GameData.look_for(level)[1])


func look_title() -> String:
	return String(GameData.look_for(level)[2])


func add_xp(n: int) -> void:
	if level >= GameData.MAX_LEVEL:
		return
	var tier_before := look_tier()
	xp += n
	var gained := 0
	while xp >= xp_to_next() and level < GameData.MAX_LEVEL:
		xp -= xp_to_next()
		level += 1
		talent_points += GameData.TALENT_POINTS_PER_LEVEL
		gained += 1
	if gained > 0:
		recalc_stats()
		player_hp = max_hp
		mana = max_mana
		var p := _player()
		if p:
			spawn_popup(p.global_position + Vector2(0, -44), "¡Nivel %d!" % level, Color(1, 0.9, 0.45))
		if look_tier() != tier_before:
			toast("Nivel %d. Tu porte ha cambiado: ahora eres %s." % [level, look_title()])
			look_changed.emit()
		else:
			toast("Subes al nivel %d. Ganas %d puntos de talento." % [level, gained * GameData.TALENT_POINTS_PER_LEVEL])
	stats_changed.emit()


## Gold, experience and loot when a monster falls.
func on_monster_killed(m: Node2D) -> void:
	var name_: String = m.get("monster_name")
	var top: Vector2 = m.global_position + Vector2(0, float(m.get("sprite_offset_y")) * 2.0)
	var g := int(round(int(m.get("gold")) * gold_mult()))
	var loot_mult := 1.0 + tsum("loot")
	add_gold(g)
	spawn_popup(top, "+%d oro" % g, Color(1, 0.85, 0.3))
	kills[name_] = int(kills.get(name_, 0)) + 1
	var drops: Array = GameData.LOOT.get(name_, []).duplicate()
	var boss: bool = m.get("boss")
	if not boss:
		drops.append(["pocion", 0.06, 1])
	var dy := -10.0
	for d in drops:
		if randf() < float(d[1]) * (loot_mult if float(d[1]) < 1.0 else 1.0):
			add_item(d[0], int(d[2]))
			spawn_popup(top + Vector2(0, dy), GameData.ITEMS[d[0]]["name"], Color(0.6, 0.9, 1))
			dy -= 10.0
	if boss or randf() < GameData.EQUIP_DROP_CHANCE * loot_mult:
		var piece := _roll_equipment(int(m.get("monster_level")) + (3 if boss else 0))
		if piece != "":
			bag.append(piece)
			spawn_popup(top + Vector2(0, dy), eq(piece)["name"], Color(0.85, 0.7, 1))
			toast("Encontraste: %s" % eq(piece)["name"])
	var gain := int(round(int(m.get("xp_reward")) * (1.0 + tsum("xp"))))
	skill_xp += maxi(1, int(round(gain / 2.0 * (1.0 + tsum("sxp")))))
	if tsum("kill_mana") > 0.0:
		mana = minf(mana + tsum("kill_mana"), max_mana)
	_quest_progress(name_)
	_contract_progress(name_)
	_bump_streak(top + Vector2(0, dy - 10.0))
	add_renown(2 + int(m.get("monster_level")) / 4 + (25 if boss else 0))
	add_xp(gain)
	monster_killed.emit(m)


## Another hunter finished off a monster: it counts for their place in the ranking.
func on_hunter_kill(hunter_name: String, m: Node2D) -> void:
	npc_renown[hunter_name] = int(npc_renown.get(hunter_name, 0)) + 2 + (20 if m.get("boss") else 0)


# --- Hunters' Guild -------------------------------------------------------------------

func guild_rank() -> Array:
	return GameData.GUILD_RANKS[GameData.guild_rank_index(renown)]


func next_guild_rank() -> Array:
	var i := GameData.guild_rank_index(renown)
	return GameData.GUILD_RANKS[i + 1] if i + 1 < GameData.GUILD_RANKS.size() else []


func npc_score(h: Dictionary) -> int:
	return int(float(h["base"]) + float(h["rate"]) * play_time / 60.0) + int(npc_renown.get(h["name"], 0))


## Everyone in the ranking, best first. Each entry: name, renown, level, tier, rank, player.
func ranking() -> Array:
	var out: Array = []
	for h in GameData.HUNTERS:
		var sc := npc_score(h)
		out.append({"name": h["name"], "renown": sc, "level": h["level"], "tier": h["tier"],
			"rank": GameData.GUILD_RANKS[GameData.guild_rank_index(sc)][1], "player": false})
	out.append({"name": "Tú", "renown": renown, "level": level, "tier": look_tier(), "rank": guild_rank()[1], "player": true})
	out.sort_custom(func(a, b): return int(a["renown"]) > int(b["renown"]))
	return out


## 1-based place of the hero in the ranking.
func player_place() -> int:
	var r := ranking()
	for i in r.size():
		if r[i]["player"]:
			return i + 1
	return r.size()


func streak() -> int:
	return _streak if clock < _streak_until else 0


func streak_mult() -> float:
	return 1.0 + 0.1 * (mini(streak(), 10) - 1) if streak() >= 2 else 1.0


func _bump_streak(pos: Vector2) -> void:
	_streak = _streak + 1 if clock < _streak_until else 1
	_streak_until = clock + 6.0
	if _streak >= 2:
		spawn_popup(pos, "Racha x%d" % _streak, Color(1, 0.55, 0.25))


func add_renown(n: int) -> void:
	if n <= 0:
		return
	var before := player_place()
	renown += int(round(n * streak_mult()))
	var after := player_place()
	if after < before:
		var r := ranking()
		toast("Superaste a %s. Ahora eres el número %d del ranking de cazadores." % [r[after]["name"], after])
	_check_rank_up()
	stats_changed.emit()


func _check_rank_up() -> void:
	var idx := GameData.guild_rank_index(renown)
	while ranks_rewarded < idx:
		ranks_rewarded += 1
		var rk: Array = GameData.GUILD_RANKS[ranks_rewarded]
		var g := 150 * ranks_rewarded
		add_gold(g)
		add_item("pocion", 2)
		var piece := _roll_equipment(level + 3)
		var extra := ""
		if piece != "":
			bag.append(piece)
			extra = ", " + eq(piece)["name"]
		toast("¡Ascenso en el Gremio! Ahora eres rango %s (%s). Recompensa: %d de oro, 2 pociones%s." % [rk[1], rk[2], g, extra])
		var p := _player()
		if p:
			spawn_popup(p.global_position + Vector2(0, -52), "Rango %s" % rk[1], Color(1, 0.85, 0.35))


func _new_contract() -> Dictionary:
	var pool: Array = []
	var taken: Array = []
	for c in contracts:
		if int(c.get("progress", 0)) < int(c.get("count", 1)):
			taken.append(c["monster"])
	for t in GameData.CONTRACT_POOL:
		var boss: bool = int(t[1]) == 1
		if boss and level < 8:
			continue
		if t[0] in taken:
			continue
		pool.append(t)
	if pool.is_empty():
		pool = [GameData.CONTRACT_POOL[0]]
	var t: Array = pool.pick_random()
	var count := int(t[1]) + (0 if int(t[1]) == 1 else level / 6)
	var weight := float(count) * (8.0 if int(t[1]) == 1 else 1.0)
	return {"monster": t[0], "count": count, "progress": 0,
		"gold": int((12 + 3 * level) * weight / 2.0), "renown": int(3 * weight + level), "sxp": int(2 * weight + level / 2)}


func _contract_progress(monster_name_: String) -> void:
	for c in contracts:
		if int(c["progress"]) >= int(c["count"]):
			continue
		if monster_name_ == c["monster"] or (c["monster"] == "Limo" and monster_name_ == "Limo extraño"):
			c["progress"] = int(c["progress"]) + 1
			if int(c["progress"]) >= int(c["count"]):
				toast("Contrato cumplido: %d × %s. Cóbralo en el Gremio." % [c["count"], c["monster"]])


func claim_contract(i: int) -> bool:
	if i < 0 or i >= contracts.size():
		return false
	var c: Dictionary = contracts[i]
	if int(c["progress"]) < int(c["count"]):
		return false
	add_gold(int(c["gold"]))
	skill_xp += int(c["sxp"])
	toast("Contrato cobrado: %d de oro, %d de renombre, %d de exp. de habilidad." % [c["gold"], c["renown"], c["sxp"]])
	add_renown(int(c["renown"]))
	contracts[i] = _new_contract()
	quests_changed.emit()
	return true


func reroll_cost() -> int:
	return 10 * level


## Pays to replace the contracts that are not finished.
func reroll_contracts() -> bool:
	if gold < reroll_cost():
		toast("Necesitas %d de oro para pedir otros contratos." % reroll_cost())
		return false
	gold -= reroll_cost()
	for i in contracts.size():
		if int(contracts[i]["progress"]) < int(contracts[i]["count"]):
			contracts[i] = _new_contract()
	quests_changed.emit()
	stats_changed.emit()
	return true


func _quest_progress(monster_name_: String) -> void:
	for q in quests:
		if q["state"] != "accepted" or not q.has("target"):
			continue
		var t: Array = q["target"]
		if monster_name_ == t[0] or (t[0] == "Limo" and monster_name_ == "Limo extraño"):
			q["progress"] = mini(int(q.get("progress", 0)) + 1, int(t[1]))
			if int(q["progress"]) >= int(t[1]):
				q["state"] = "done"
				toast("Pedido completado: %s. Vuelve al Gremio a cobrar." % q["title"])
			quests_changed.emit()


## A random piece suited to a monster of this level.
func roll_equipment(mlevel: int) -> String:
	return _roll_equipment(mlevel)


func _roll_equipment(mlevel: int) -> String:
	var pool: Array[String] = []
	for id in GameData.EQUIPMENT:
		var req := int(GameData.EQUIPMENT[id]["level"])
		if req <= mlevel + 2 and req >= mlevel - 12:
			pool.append(id)
	return pool.pick_random() if pool.size() > 0 else ""


func _equip_sum(key: String) -> float:
	var t := 0.0
	for slot in equipped:
		t += float(eq(equipped[slot]).get(key, 0))
	return t


## Sum of a bonus over the talent tree (rank x bonus per rank).
func tsum(key: String) -> float:
	var t := 0.0
	for id in talents:
		var n := GameData.talent_node(id)
		if not n.is_empty() and n["fx"].has(key):
			t += float(n["fx"][key]) * int(talents[id])
	return t


func attr(id: String) -> int:
	return int(attributes.get(id, 0))


func recalc_stats() -> void:
	var before := max_hp
	var base_hp := 10 + 2 * (level - 1) + 4 * attr("vida") + tsum("hp") + _equip_sum("hp")
	max_hp = int(round(base_hp * (1.0 + tsum("hp_pct"))))
	player_hp = clampi(player_hp + maxi(max_hp - before, 0), 0, max_hp)
	max_stamina = 100.0 + 10.0 * attr("energia") + tsum("stamina")
	max_mana = 50.0 + 2.0 * (level - 1) + 6.0 * attr("magia") + tsum("mana") + _equip_sum("mana")
	stamina = minf(stamina, max_stamina)
	mana = minf(mana, max_mana)
	stats_changed.emit()


## Sword damage per hit (before critical hits).
func attack() -> int:
	var base := 1 + int((level - 1) / 4) + tsum("atk") + _equip_sum("atk") + (_buff_bonus if buff_active() else 0)
	return maxi(1, int(round(base * (1.0 + tsum("atk_pct")))))


func defense() -> int:
	return int(_equip_sum("def") + tsum("def"))


func crit_chance() -> float:
	return 0.03 + tsum("crit")


func crit_mult() -> float:
	return 1.5 + tsum("crit_dmg")


func skill_power() -> float:
	return 1.0 + tsum("skill_dmg") + 0.02 * attr("magia")


## Damage the hero actually takes from a hit, after armour.
func mitigate(raw: int) -> int:
	var d := raw * 12.0 / (12.0 + defense()) * (1.0 - minf(tsum("guard"), 0.6))
	return maxi(1, int(round(d)))


## Hits a monster (or its hurtbox) with crits, skill power and life steal applied.
func hit_monster(target: Object, base: int, is_skill: bool, source: Node2D) -> void:
	var dmg := float(base) * (skill_power() if is_skill else 1.0)
	var crit := randf() < crit_chance()
	if crit:
		dmg *= crit_mult()
	var final := maxi(1, int(round(dmg)))
	target.call("take_hit", final, source, crit)
	var ls := tsum("lifesteal")
	if ls > 0.0 and player_hp < max_hp:
		_lifesteal_acc += final * ls
		if _lifesteal_acc >= 1.0:
			heal_player(int(_lifesteal_acc))
			_lifesteal_acc -= int(_lifesteal_acc)


func speed_mult() -> float:
	return maxf(0.6, 1.0 + tsum("speed") + _equip_sum("speed"))


func gold_mult() -> float:
	return 1.0 + tsum("gold")


func dodge_chance() -> float:
	return minf(tsum("dodge"), 0.5)


func mana_regen() -> float:
	return 2.5 * (1.0 + tsum("mana_regen"))


func stamina_regen_mult() -> float:
	return 1.0 + 0.02 * attr("energia") + tsum("stamina_regen")


func run_cost_mult() -> float:
	return maxf(0.3, 1.0 - tsum("run_cost"))


func skill_mana_cost(id: String) -> float:
	return float(GameData.skill_def(id)["mana"]) * maxf(0.5, 1.0 - tsum("mana_cost"))


func buff_active() -> bool:
	return clock < _buff_until


func buff_left() -> float:
	return maxf(_buff_until - clock, 0.0)


# --- Items ----------------------------------------------------------------------

func item_count(id: String) -> int:
	return int(inventory.get(id, 0))


func add_item(id: String, n := 1) -> void:
	inventory[id] = item_count(id) + n
	stats_changed.emit()


func remove_item(id: String, n := 1) -> void:
	var left := item_count(id) - n
	if left <= 0:
		inventory.erase(id)
	else:
		inventory[id] = left
	stats_changed.emit()


## Uses a consumable. Returns false (with a message) if it can't be used now.
func use_item(id: String) -> bool:
	var it: Dictionary = GameData.ITEMS.get(id, {})
	if item_count(id) <= 0 or not it.has("use"):
		return false
	if it["use"] == "hp":
		if player_hp >= max_hp:
			toast("Ya tienes la vida completa.")
			return false
		var h := maxi(1, int(round(max_hp * float(it["amount"]) * (1.0 + tsum("potion")))))
		heal_player(h)
		toast("Usaste: %s (+%d de vida)" % [it["name"], h])
	elif it["use"] == "mana":
		if mana >= max_mana:
			toast("Ya tienes el maná completo.")
			return false
		var m := max_mana * float(it["amount"]) * (1.0 + tsum("potion"))
		mana = minf(mana + m, max_mana)
		toast("Usaste: %s (+%d de maná)" % [it["name"], int(m)])
	remove_item(id)
	return true


func use_potion() -> void:
	if item_count("pocion") <= 0:
		toast("No te quedan pociones.")
		return
	use_item("pocion")


# --- Equipment --------------------------------------------------------------------

## "" if the piece can be worn now, otherwise the reason.
func equip_block_reason(id: String) -> String:
	var e := eq(id)
	if level < int(e["level"]):
		return "Necesitas nivel %d." % e["level"]
	return ""


## Wears a piece from the bag; whatever was in that slot goes back to the bag.
func equip(bag_index: int) -> bool:
	if bag_index < 0 or bag_index >= bag.size():
		return false
	var id := bag[bag_index]
	if equip_block_reason(id) != "":
		toast(equip_block_reason(id))
		return false
	var slot: String = eq(id)["slot"]
	bag.remove_at(bag_index)
	if equipped.has(slot):
		bag.append(equipped[slot])
	equipped[slot] = id
	recalc_stats()
	return true


func unequip(slot: String) -> void:
	if not equipped.has(slot):
		return
	bag.append(equipped[slot])
	equipped.erase(slot)
	recalc_stats()


## Base id of an equipment entry ("espada_acero+3" -> "espada_acero").
func eq_base(entry: String) -> String:
	return entry.get_slice("+", 0)


func eq_plus(entry: String) -> int:
	return int(entry.get_slice("+", 1)) if entry.contains("+") else 0


func eq_icon(entry: String) -> String:
	return GameData.EQ + eq_base(entry) + ".png"


## Stats of an equipment entry, including forge improvements.
func eq(entry: String) -> Dictionary:
	var e: Dictionary = GameData.EQUIPMENT.get(eq_base(entry), {}).duplicate()
	if e.is_empty():
		return e
	var plus := eq_plus(entry)
	e["plus"] = plus
	if plus > 0:
		e["name"] = "%s +%d" % [e["name"], plus]
		for k in ["atk", "def"]:
			if e.has(k) and int(e[k]) > 0:
				e[k] = int(e[k]) + plus * maxi(1, int(round(int(e[k]) * 0.2)))
		if e.has("hp"):
			e["hp"] = int(e["hp"]) + plus * 2
		if e.has("mana"):
			e["mana"] = int(e["mana"]) + plus * 4
		if not e.has("atk") and not e.has("def"):
			e["hp"] = int(e.get("hp", 0)) + plus * 2
	return e


# --- Forge --------------------------------------------------------------------------

func forge_cost(entry: String) -> Dictionary:
	var p := eq_plus(entry)
	return GameData.FORGE_COSTS[p] if p < GameData.MAX_PLUS else {}


## "" if the piece worn in `slot` can be improved now, otherwise the reason.
func forge_block_reason(slot: String) -> String:
	if not equipped.has(slot):
		return "No llevas nada en esa ranura."
	var entry: String = equipped[slot]
	if eq_plus(entry) >= GameData.MAX_PLUS:
		return "Ya está mejorada al máximo."
	var cost := forge_cost(entry)
	if gold < int(cost["gold"]):
		return "Te falta oro."
	for id in cost["items"]:
		if item_count(id) < int(cost["items"][id]):
			return "Te faltan materiales."
	return ""


func forge_upgrade(slot: String) -> bool:
	if forge_block_reason(slot) != "":
		return false
	var entry: String = equipped[slot]
	var cost := forge_cost(entry)
	gold -= int(cost["gold"])
	for id in cost["items"]:
		remove_item(id, int(cost["items"][id]))
	equipped[slot] = "%s+%d" % [eq_base(entry), eq_plus(entry) + 1]
	recalc_stats()
	toast("Kara mejora tu %s." % eq(equipped[slot])["name"])
	return true


# --- Chests -------------------------------------------------------------------------

func is_chest_opened(id: String) -> bool:
	return opened_chests.has(id)


## Loot of a chest: equipment around the hero's level (better chests, better pieces), gold and potions.
func open_chest(id: String, tier: int, pos: Vector2) -> void:
	if is_chest_opened(id):
		return
	opened_chests[id] = true
	var found: Array[String] = []
	for i in (2 if tier >= 3 else 1):
		var piece := _roll_equipment(level + tier * 2)
		if piece != "":
			if tier >= 2 and randf() < 0.5:
				piece = "%s+%d" % [piece, randi_range(1, tier)]
			bag.append(piece)
			found.append(eq(piece)["name"])
	var g := int(round((10 + 6 * level) * (1.0 + tier * 0.6) * randf_range(0.8, 1.2)))
	add_gold(g)
	found.append("%d de oro" % g)
	if randf() < 0.5 + tier * 0.1:
		add_item("pocion", 1 + int(tier / 2))
		found.append("pociones")
	spawn_popup(pos, "¡Cofre!", Color(1, 0.88, 0.4))
	add_renown(5 + tier * 5)
	toast("En el cofre: %s." % ", ".join(found))
	stats_changed.emit()


# --- Skills -----------------------------------------------------------------------

func skill_rank(id: String) -> int:
	return int(skill_ranks.get(id, 0))


func has_skill(id: String) -> bool:
	return skill_rank(id) > 0


func skill_values(id: String) -> Dictionary:
	return GameData.skill_values(id, skill_rank(id), attack())


## "" if the skill can be learned / improved now, otherwise the reason.
func skill_block_reason(id: String) -> String:
	var s := GameData.skill_def(id)
	var r := skill_rank(id)
	if r >= GameData.MAX_SKILL_RANK:
		return "Rango máximo."
	if level < int(s["level"]):
		return "Requiere nivel %d." % s["level"]
	if skill_xp < GameData.skill_cost(r):
		return "Te falta experiencia de habilidad."
	return ""


func improve_skill(id: String) -> bool:
	if skill_block_reason(id) != "":
		return false
	skill_xp -= GameData.skill_cost(skill_rank(id))
	skill_ranks[id] = skill_rank(id) + 1
	var s := GameData.skill_def(id)
	toast(("Aprendiste: %s" % s["name"]) if skill_rank(id) == 1 else ("%s sube al rango %d." % [s["name"], skill_rank(id)]))
	stats_changed.emit()
	return true


func skill_cooldown(id: String) -> float:
	return float(skill_values(id).get("cd", 1.0)) * maxf(0.5, 1.0 - tsum("cdr"))


func skill_cooldown_left(id: String) -> float:
	return maxf(float(_skill_ready.get(id, 0.0)) - clock, 0.0)


## Spends mana and starts the cooldown. Returns "" on success or the reason it failed.
func try_cast(id: String) -> String:
	var s := GameData.skill_def(id)
	if not has_skill(id):
		return "Todavía no conoces esa habilidad."
	if skill_cooldown_left(id) > 0.0:
		return "%s aún no está lista." % s["name"]
	if mana < skill_mana_cost(id):
		return "No tienes suficiente maná."
	mana -= skill_mana_cost(id)
	_skill_ready[id] = clock + skill_cooldown(id)
	stats_changed.emit()
	return ""


func start_buff(seconds: float, bonus: int) -> void:
	_buff_until = clock + seconds
	_buff_bonus = bonus
	stats_changed.emit()


# --- Talents ----------------------------------------------------------------------

func talent_rank(id: String) -> int:
	return int(talents.get(id, 0))


func branch_points(branch: int) -> int:
	var t := 0
	for id in talents:
		var n := GameData.talent_node(id)
		if not n.is_empty() and int(n["branch"]) == branch:
			t += int(talents[id])
	return t


## "" if the node can take another rank now, otherwise the reason.
func talent_block_reason(id: String) -> String:
	var n := GameData.talent_node(id)
	if talent_rank(id) >= int(n["max"]):
		return "Rango máximo."
	var need: int = GameData.TIER_POINTS[int(n["tier"])]
	if branch_points(int(n["branch"])) < need:
		return "Necesitas %d puntos en esta senda." % need
	var reqs: Array = n["req"]
	if reqs.size() > 0:
		var ok := false
		for r in reqs:
			if talent_rank(r) > 0:
				ok = true
		if not ok:
			var names: Array[String] = []
			for r in reqs:
				names.append(GameData.talent_node(r)["name"])
			return "Requiere: %s." % " o ".join(names)
	if talent_points <= 0:
		return "No tienes puntos de talento."
	return ""


func add_talent(id: String) -> bool:
	if talent_block_reason(id) != "":
		return false
	talent_points -= 1
	talents[id] = talent_rank(id) + 1
	recalc_stats()
	return true


func add_attribute(id: String, n := 1) -> int:
	var spend := mini(n, talent_points)
	if spend <= 0:
		return 0
	talent_points -= spend
	attributes[id] = attr(id) + spend
	recalc_stats()
	return spend


func respec_cost() -> int:
	return 25 * level


## Returns every talent point (tree and attributes) for a fee in gold.
func reset_talents() -> bool:
	var spent := 0
	for id in talents:
		spent += int(talents[id])
	for id in attributes:
		spent += int(attributes[id])
	if spent == 0:
		toast("No tienes puntos gastados.")
		return false
	if gold < respec_cost():
		toast("Necesitas %d de oro para reiniciar los talentos." % respec_cost())
		return false
	gold -= respec_cost()
	talents = {}
	attributes = {"vida": 0, "energia": 0, "magia": 0}
	talent_points += spent
	recalc_stats()
	toast("Recuperas %d puntos de talento." % spent)
	return true


## Texture for an icon spec: a PNG path or [x, y] of a 16x16 cell in the UI pack.
func icon_texture(spec) -> Texture2D:
	if spec is String:
		return load(spec) as Texture2D
	var a := AtlasTexture.new()
	a.atlas = load(GameData.UI_ICONS)
	a.region = Rect2(spec[0], spec[1], 16, 16)
	return a


# --- Player stats -------------------------------------------------------------------

func damage_player(amount: int) -> void:
	player_hp = maxi(player_hp - amount, 0)
	stats_changed.emit()


func heal_player(amount: int) -> void:
	player_hp = mini(player_hp + amount, max_hp)
	stats_changed.emit()


func set_stamina(v: float) -> void:
	var nv := clampf(v, 0.0, max_stamina)
	if absf(nv - stamina) > 0.01:
		stamina = nv
		stats_changed.emit()


func add_gold(n: int) -> void:
	gold += n
	stats_changed.emit()


## The player fell: fade out and wake up at the map's safe spot with full health.
func player_died() -> void:
	toast("Despiertas en un lugar seguro...")
	player_hp = max_hp
	stamina = max_stamina
	mana = max_mana
	var scene := get_tree().current_scene
	pending_spawn = "respawn"
	change_scene(scene.scene_file_path, 0.6)


## Small floating text in the world (damage numbers, gold...).
func spawn_popup(pos: Vector2, text: String, color: Color) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var p := Node2D.new()
	p.set_script(load("res://scripts/ui/popup_text.gd"))
	p.set("text", text)
	p.set("color", color)
	p.position = pos
	p.z_index = 70
	p.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	scene.add_child(p)


# =============================================================================
# Saving
# =============================================================================

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func can_save() -> bool:
	var p := _player()
	return p != null and not editing and not _busy and not (p.has_method("is_dead") and p.call("is_dead"))


func save_game(auto := false) -> bool:
	if not can_save():
		if not auto:
			toast("Ahora no se puede guardar.")
		return false
	var p := _player()
	var quest_states := {}
	for q in quests:
		quest_states[q["id"]] = {"state": q["state"], "progress": int(q.get("progress", 0))}
	var data := {
		"version": SAVE_VERSION, "saved_at": Time.get_datetime_string_from_system(false, true),
		"scene": get_tree().current_scene.scene_file_path, "x": p.global_position.x, "y": p.global_position.y,
		"return_spawn": return_spawn,
		"gold": gold, "level": level, "xp": xp, "skill_xp": skill_xp, "talent_points": talent_points,
		"hp": player_hp, "mana": mana, "stamina": stamina,
		"inventory": inventory, "bag": Array(bag), "equipped": equipped, "chests": opened_chests.keys(),
		"renown": renown, "ranks_rewarded": ranks_rewarded, "npc_renown": npc_renown, "contracts": contracts,
		"skill_ranks": skill_ranks, "talents": talents, "attributes": attributes, "kills": kills, "quests": quest_states,
		"play_time": play_time,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		toast("No se pudo guardar la partida.")
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	_autosave_left = AUTOSAVE_INTERVAL
	toast("Guardado automático." if auto else "Partida guardada.")
	return true


func save_info() -> Dictionary:
	if not has_save():
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	return parsed if parsed is Dictionary else {}


func load_game() -> bool:
	var d := save_info()
	if d.is_empty():
		toast("No hay ninguna partida guardada.")
		return false
	reset_progress()
	gold = int(d.get("gold", gold))
	level = int(d.get("level", 1))
	xp = int(d.get("xp", 0))
	skill_xp = int(d.get("skill_xp", 0))
	talent_points = int(d.get("talent_points", 0))
	play_time = float(d.get("play_time", 0.0))
	inventory = _int_dict(d.get("inventory", {}))
	bag.clear()
	for id in d.get("bag", []):
		if GameData.EQUIPMENT.has(eq_base(String(id))):
			bag.append(String(id))
	opened_chests = {}
	for c in d.get("chests", []):
		opened_chests[String(c)] = true
	renown = int(d.get("renown", 0))
	ranks_rewarded = int(d.get("ranks_rewarded", GameData.guild_rank_index(renown)))
	npc_renown = _int_dict(d.get("npc_renown", {}))
	var cs: Array = d.get("contracts", [])
	if cs.size() == 3:
		contracts = []
		for c in cs:
			var cd: Dictionary = c
			for k in ["count", "progress", "gold", "renown", "sxp"]:
				cd[k] = int(cd.get(k, 0))
			contracts.append(cd)
	equipped = {}
	var eq_: Dictionary = d.get("equipped", {})
	for slot in eq_:
		if GameData.EQUIPMENT.has(eq_base(String(eq_[slot]))):
			equipped[String(slot)] = String(eq_[slot])
	skill_ranks = _int_dict(d.get("skill_ranks", {}))
	kills = _int_dict(d.get("kills", {}))
	if int(d.get("version", 1)) >= 2:
		talents = {}
		var tl := _int_dict(d.get("talents", {}))
		for id in tl:
			if not GameData.talent_node(id).is_empty():
				talents[id] = tl[id]
		var at := _int_dict(d.get("attributes", {}))
		for k in attributes:
			attributes[k] = int(at.get(k, 0))
	else:
		# older saves: the talent system changed, so every point is handed back
		talents = {}
		talent_points = GameData.TALENT_POINTS_PER_LEVEL * level
	var qs: Dictionary = d.get("quests", {})
	for q in quests:
		var st = qs.get(q["id"], null)
		if st is Dictionary:
			q["state"] = String(st.get("state", q["state"]))
			q["progress"] = int(st.get("progress", 0))
		elif st is String and q.has("target"):
			q["state"] = st
		if q["state"] == "accepted" and not q.has("target"):
			q["state"] = "soon"
	recalc_stats()
	player_hp = clampi(int(d.get("hp", max_hp)), 1, max_hp)
	mana = clampf(float(d.get("mana", max_mana)), 0.0, max_mana)
	stamina = clampf(float(d.get("stamina", max_stamina)), 0.0, max_stamina)
	return_spawn = String(d.get("return_spawn", ""))
	pending_spawn = ""
	pending_position = Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0)))
	var scene := String(d.get("scene", FIRST_LEVEL))
	if not ResourceLoader.exists(scene):
		scene = FIRST_LEVEL
		pending_position = Vector2.INF
	_autosave_left = AUTOSAVE_INTERVAL
	change_scene(scene)
	return true


func _int_dict(src) -> Dictionary:
	var out := {}
	if src is Dictionary:
		for k in src:
			out[String(k)] = int(src[k])
	return out


## Called by maps after placing the player at a spawn: a loaded save overrides it.
func take_pending_position(player: Node2D) -> void:
	if pending_position != Vector2.INF:
		player.global_position = pending_position
		pending_position = Vector2.INF


# =============================================================================
# Editor, quests, menus
# =============================================================================

func check_dev_password(text: String) -> bool:
	return text.strip_edges().sha256_text() == DEV_PASSWORD_SHA256


## Opens the overworld in edit mode with the map editor on top.
func start_editor(scene_path := FIRST_LEVEL) -> void:
	if _busy:
		return
	editing = true
	pending_spawn = ""
	pending_position = Vector2.INF
	change_scene(scene_path)
	await get_tree().create_timer(0.8).timeout
	var ed: Node = load(EDITOR_SCENE).instantiate()
	get_tree().root.add_child(ed)


func stop_editing() -> void:
	editing = false
	input_locked = false


func accept_quest(id: String) -> void:
	for q in quests:
		if q["id"] == id and q["state"] == "open":
			q["state"] = "accepted"
			q["progress"] = 0
			quests_changed.emit()
			toast("Pedido aceptado: %s" % q["title"])
			return


## Hands in a completed request: gold and experience.
func claim_quest(id: String) -> void:
	for q in quests:
		if q["id"] == id and q["state"] == "done":
			q["state"] = "claimed"
			add_gold(int(q["reward"]))
			toast("Recompensa: %d de oro y %d de experiencia." % [q["reward"], q.get("xp", 0)])
			add_renown(int(q["reward"]) / 6)
			add_xp(int(q.get("xp", 0)))
			quests_changed.emit()
			return


func go_to_main_menu() -> void:
	change_scene(MAIN_MENU)


func quit_game() -> void:
	get_tree().quit()


# --- UI bus -------------------------------------------------------------------

func show_dialogue(speaker: String, lines: PackedStringArray) -> void:
	dialogue_requested.emit(speaker, lines)


func toast(text: String) -> void:
	toast_requested.emit(text)


# --- Settings -----------------------------------------------------------------

func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	apply_settings()
	save_settings()


func apply_settings() -> void:
	var bus := AudioServer.get_bus_index("Master")
	var vol: float = settings["master_volume"]
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(vol, 0.0001)))
	AudioServer.set_bus_mute(bus, vol <= 0.0)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		for key in settings.keys():
			settings[key] = cfg.get_value("settings", key, settings[key])
	apply_settings()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in settings.keys():
		cfg.set_value("settings", key, settings[key])
	cfg.save(SETTINGS_PATH)
