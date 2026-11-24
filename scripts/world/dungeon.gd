extends Node
## Runs a wave dungeon (added by the arena's world script): five waves summoned through magic circles
## (elites in the middle ones, the boss in the last), a banner and counter on screen, a timer, and
## at the end a rank (S/A/B/C by time and hits taken), the reward chest and the portal out.

const SUMMON := preload("res://scripts/fx/summon.gd")
const THEME_TINT := {"crypt": Color(0.86, 0.86, 0.92), "forest": Color(0.86, 0.95, 0.86), "sand": Color(1.0, 0.95, 0.85),
	"ice": Color(0.88, 0.94, 1.0), "eclipse": Color(0.78, 0.68, 0.95)}

var def: Dictionary
var _wave := 0
var _alive: Array = []
var _time := 0.0
var _running := false
var _done := false
var _hits := 0
var _hp_seen := 0
var _hud: CanvasLayer
var _title: Label
var _info: Label
var _banner: Label
var _center := Vector2.ZERO


func _ready() -> void:
	def = Game.dungeon_def(Game.current_dungeon)
	var world := get_parent()
	_center = Vector2(world.map_size) * 8.0 + Vector2(0, 16)
	var tint := CanvasModulate.new()
	tint.color = THEME_TINT.get(def.get("theme", "crypt"), Color.WHITE)
	world.add_child(tint)
	_build_hud()
	_exit_portal(Vector2(23 * 16, 31.2 * 16), "Salir")
	_hp_seen = Game.player_hp
	await get_tree().create_timer(1.2).timeout
	_say("%s%s" % [def.get("name", "Mazmorra"), "  ·  Heroico" if Game.dungeon_heroic else ""], 2.4)
	if def.has("tower"):
		_say("%s  ·  nivel %d" % [def["name"], Game.dungeon_level()], 2.4)
	await get_tree().create_timer(2.6).timeout
	_running = true
	_next_wave()


func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 6
	add_child(_hud)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	box.position = Vector2(-90, 6)
	box.custom_minimum_size = Vector2(180, 0)
	box.add_theme_constant_override("separation", 0)
	_hud.add_child(box)
	_title = _label(9, Color(1, 0.86, 0.5))
	box.add_child(_title)
	_info = _label(7, Color(0.95, 0.9, 0.8))
	box.add_child(_info)
	_banner = _label(16, Color(1, 0.9, 0.55))
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.position = Vector2(-200, -60)
	_banner.custom_minimum_size = Vector2(400, 0)
	_banner.modulate.a = 0.0
	_hud.add_child(_banner)


func _label(size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _say(text: String, hold := 1.6) -> void:
	_banner.text = text
	var t := create_tween()
	t.tween_property(_banner, "modulate:a", 1.0, 0.25)
	t.tween_interval(hold)
	t.tween_property(_banner, "modulate:a", 0.0, 0.5)


func _process(delta: float) -> void:
	if _running and not _done:
		_time += delta
		# hits taken (for the rank): every drop in health is one
		if Game.player_hp < _hp_seen:
			_hits += 1
		_hp_seen = Game.player_hp
	_alive = _alive.filter(func(m): return is_instance_valid(m) and int(m.get("hp")) > 0)
	_title.text = "%s%s" % [def.get("name", ""), "  (Heroico)" if Game.dungeon_heroic else ""]
	var mm := int(_time) / 60
	var ss := int(_time) % 60
	if _done:
		_info.text = "¡Superada!  ·  %d:%02d" % [mm, ss]
	elif _wave == 0:
		_info.text = "Prepárate..."
	else:
		_info.text = "Oleada %d / %d   ·   Enemigos: %d   ·   %d:%02d" % [_wave, Game.dungeon_waves(), _alive.size(), mm, ss]
	if _running and not _done and _wave > 0 and _alive.is_empty() and not _spawning:
		_running = false
		_wave_cleared()


var _spawning := false


func _next_wave() -> void:
	_wave += 1
	var last := _wave == Game.dungeon_waves()
	Game.sfx("horn", -4.0 if not last else 0.0, 0.0)
	_say("¡Oleada final!" if last else "Oleada %d" % _wave)
	_spawning = true
	var pool: Array = def["pool"]
	var n := 4 + _wave * 2
	var elites := 1 if _wave == 3 else (2 if _wave == 4 else 0)
	var lv := Game.dungeon_level() + (_wave - 1) / 2
	if def.has("tower"):
		# shorter floors, but elites from the start and more of them as you climb
		elites = mini(1 + int(def["floor"]) / 8 + (_wave - 1), 5)
		n = 4 + _wave * 2 + mini(int(def["floor"]) / 6, 4)
	if last and String(def["boss"]) != "":
		_summon(String(def["boss"]), _center + Vector2(0, -40), lv + 2, false, true)
		n = 6
	for i in n:
		var a := randf() * TAU
		var p := _center + Vector2(cos(a) * randf_range(90, 200), sin(a) * randf_range(60, 130))
		_summon(String(pool.pick_random()), p, lv, i < elites, false)
		await get_tree().create_timer(0.18).timeout
	await get_tree().create_timer(1.0).timeout
	_spawning = false
	_running = true


## A magic circle opens; a moment later the monster steps out of it.
func _summon(mon_name: String, at: Vector2, lv: int, elite: bool, boss: bool) -> void:
	var md: Dictionary = MonsterDefs.DEFS.get(mon_name, {})
	if md.is_empty():
		return
	var world := get_parent()
	if world.has_method("is_walkable") and not world.is_walkable(at):
		var free: Vector2 = world.call("_walkable_in", Rect2(at - Vector2(48, 48), Vector2(96, 96)))
		if free != Vector2.INF:
			at = free
	var fx := Node2D.new()
	fx.set_script(SUMMON)
	fx.set("color", Color(1, 0.75, 0.3) if elite or boss else def.get("color", Color(0.7, 0.5, 1.0)))
	fx.set("big", boss)
	fx.position = at
	world.get_node("Entities").add_child(fx)
	await get_tree().create_timer(0.8).timeout
	var m := (load("res://scenes/monsters/monster.tscn") as PackedScene).instantiate()
	var v: Array = md["variants"].pick_random()
	m.set("frames", load(v[0]))
	m.set("sprite_offset_y", float(v[1]))
	for k in ["max_hp", "damage", "speed", "chase_speed", "attack_range", "gold", "sprite_scale"]:
		if md.has(k):
			m.set(k, md[k])
	if md.has("body_size"):
		m.set("body_size", md["body_size"])
	m.set("boss", boss or bool(md.get("boss", false)))
	m.set("monster_name", mon_name)
	m.set("base_name", mon_name)
	m.set("aggro_radius", 900.0)
	m.set("territory", 4000.0)
	m.set("forced_level", lv)
	m.set("no_respawn", true)
	m.set("elite", elite)
	if Game.dungeon_heroic:
		m.set("max_hp", int(int(md.get("max_hp", 5)) * 1.35))
	m.position = at
	world.get_node("Entities").add_child(m)
	if elite:
		(m.get_node("AnimatedSprite2D") as CanvasItem).self_modulate = Color(1.25, 1.1, 0.7)
	_alive.append(m)


func _wave_cleared() -> void:
	if _wave >= Game.dungeon_waves():
		_victory()
		return
	Game.sfx("quest", -4.0, 0.0)
	_say("¡Oleada superada!")
	Game.heal_player(int(Game.max_hp * 0.15))
	await get_tree().create_timer(3.5).timeout
	_next_wave()


func _victory() -> void:
	_done = true
	var rank := Game.dungeon_rank(_time, _hits)
	Game.sfx("level_up", 0.0, 0.0)
	Game.shake(3.0, 0.5)
	_say("¡Mazmorra superada!  Rango %s" % rank, 3.0)
	var chest := Node2D.new()
	chest.set_script(load("res://scripts/objects/dungeon_chest.gd"))
	chest.set("rank", rank)
	chest.set("secs", _time)
	chest.position = _center + Vector2(0, -8)
	get_parent().get_node("Entities").add_child(chest)
	if def.has("tower"):
		# the way up
		var up := (load("res://scenes/objects/dungeon_portal.tscn") as PackedScene).instantiate()
		up.set("mode", "next")
		up.set("label", "Subir al piso %d" % (int(def["floor"]) + 1))
		up.set("color", Color(1.0, 0.45, 0.55))
		up.position = _center + Vector2(0, -70)
		get_parent().get_node("Entities").add_child(up)


func _exit_portal(at: Vector2, label: String) -> void:
	var scene := load("res://scenes/objects/dungeon_portal.tscn") as PackedScene
	var p := scene.instantiate()
	p.set("mode", "exit")
	p.set("label", label)
	p.set("color", def.get("color", Color(0.7, 0.5, 1.0)))
	p.position = at
	get_parent().get_node("Entities").add_child(p)
