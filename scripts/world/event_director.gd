extends Node
## World events on wild maps: every few minutes a colossal version of one of the bosses appears
## somewhere on the plain. The Guild's hunters rush to fight it; whoever fights it and survives
## gets a share of the spoils. If nobody beats it in time, it leaves.

const NAMES := {"Gólem de las Ruinas": "Gólem colosal", "Ent Ancestral": "Ent colosal", "Rey Limo": "Rey Limo colosal"}

var _next := 0.0
var _boss: Node2D = null
var _left := 0.0
var _world: Node


func _ready() -> void:
	_world = get_parent()
	_next = randf_range(GameData.EVENT_FIRST.x, GameData.EVENT_FIRST.y)


func _process(delta: float) -> void:
	if Game.editing or get_tree().paused:
		return
	if _boss != null and is_instance_valid(_boss) and int(_boss.get("hp")) > 0:
		_left -= delta
		if _left <= 0.0:
			_retreat()
		return
	_boss = null
	_next -= delta
	if _next <= 0.0:
		_next = randf_range(GameData.EVENT_EVERY.x, GameData.EVENT_EVERY.y)
		spawn_event()


## Seconds left before the colossus leaves (0 if there is no event).
func time_left() -> float:
	return _left if _boss != null and is_instance_valid(_boss) else 0.0


func spawn_event() -> Node2D:
	var templates: Array = []
	for m in get_tree().get_nodes_in_group("monsters"):
		if m.get("boss") and not m.get("event_boss"):
			templates.append(m)
	if templates.is_empty():
		return null
	var t: Node2D = templates.pick_random()
	var pos := _spawn_point(t.global_position)
	var m: Node2D = (load("res://scenes/monsters/monster.tscn") as PackedScene).instantiate()
	var base_name: String = t.get("monster_name")
	m.set("frames", t.get("frames"))
	m.set("monster_name", NAMES.get(base_name, base_name + " colosal"))
	m.set("base_name", base_name)
	m.set("max_hp", t.get("_base_hp"))
	m.set("damage", t.get("_base_damage"))
	m.set("gold", int(t.get("_base_gold")) * 3)
	for k in ["speed", "chase_speed", "attack_cooldown", "sprite_offset_y", "body_size"]:
		m.set(k, t.get(k))
	m.set("aggro_radius", float(t.get("aggro_radius")) * 1.3)
	m.set("attack_range", float(t.get("attack_range")) * 1.25)
	m.set("territory", 170.0)
	m.set("boss", true)
	m.set("event_boss", true)
	m.scale = Vector2(1.35, 1.35)
	m.position = pos
	_world.get_node("Entities").add_child(m)
	_boss = m
	_left = GameData.EVENT_DURATION
	var zone := _zone_name(pos)
	Game.world_event.emit("¡Un %s apareció en %s!" % [m.get("monster_name"), zone])
	return m


func _retreat() -> void:
	if _boss and is_instance_valid(_boss):
		Game.world_event.emit("El %s se retira..." % _boss.get("monster_name"))
		_boss.set("hp", 0)
		var t := _boss.create_tween()
		t.tween_property(_boss, "modulate:a", 0.0, 1.5)
		t.tween_callback(_boss.queue_free)
	_boss = null


func _spawn_point(fallback: Vector2) -> Vector2:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	var rects: Array[Rect2] = []
	var map_area := 1.0
	var ms = _world.get("map_size")
	if ms != null:
		map_area = float(ms.x * ms.y * 256)
	var zones: Dictionary = _world.get("zones") if _world.get("zones") != null else {}
	for z in zones:
		var r: Rect2 = zones[z]
		if r.get_area() < map_area * 0.3 and not String(z).begins_with("Campamento del"):
			rects.append(r)
	for i in 60:
		if rects.is_empty():
			break
		var r: Rect2 = rects.pick_random()
		var q := r.position + Vector2(randf() * r.size.x, randf() * r.size.y)
		var d := p.global_position.distance_to(q) if p else 400.0
		if d > 220.0 and d < 900.0 and _world.call("is_walkable", q):
			return q
	return fallback


func _zone_name(pos: Vector2) -> String:
	var zones: Dictionary = _world.get("zones") if _world.get("zones") != null else {}
	for z in zones:
		if (zones[z] as Rect2).has_point(pos) and (zones[z] as Rect2).get_area() < 1e6:
			return z
	return "la llanura"
