extends Control
## Minimap in the top-right corner (the map around the hero) and a full map with M.
## Uses the map picture the world generator renders (`minimap_path` on the map root, 2 px per tile).

const SIZE := Vector2(84, 60)
const MARGIN := Vector2(5, 5)
const PX_PER_TILE := 2.0

var _tex: Texture2D
var _map_px := Vector2.ONE   # map size in world pixels
var _big := false
var _t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_map.call_deferred()


func _load_map() -> void:
	var scene := get_tree().current_scene
	var path: String = scene.get("minimap_path") if scene and scene.get("minimap_path") != null else ""
	if path != "" and ResourceLoader.exists(path):
		_tex = load(path)
		var ms = scene.get("map_size")
		_map_px = Vector2(ms) * 16.0 if ms != null else _tex.get_size() / PX_PER_TILE * 16.0
	visible = _tex != null


func _unhandled_input(event: InputEvent) -> void:
	if _tex == null or Game.editing:
		return
	if event.is_action_pressed("map") and (not Game.input_locked or _big):
		get_viewport().set_input_as_handled()
		_big = not _big
		Game.input_locked = _big
		get_tree().paused = _big
	elif _big and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause") or (event is InputEventMouseButton and event.pressed)):
		get_viewport().set_input_as_handled()
		_big = false
		Game.input_locked = false
		get_tree().paused = false


func _process(delta: float) -> void:
	_t += delta
	if _tex:
		queue_redraw()


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


func _draw() -> void:
	var p := _player()
	if _tex == null or p == null:
		return
	if _big:
		_draw_big(p)
		return
	var vp := get_viewport_rect().size
	var area := Rect2(Vector2(vp.x - SIZE.x - MARGIN.x, MARGIN.y), SIZE)
	# frame
	draw_rect(area.grow(3), Color(0.2, 0.12, 0.07, 0.95))
	draw_rect(area.grow(2), Color(0.62, 0.45, 0.22))
	draw_rect(area.grow(1), Color(0.12, 0.08, 0.05))
	var scale := Vector2(_tex.get_size()) / _map_px          # texture px per world px
	var center := p.global_position * scale
	var src := Rect2(center - SIZE / 2.0, SIZE)
	src.position = src.position.clamp(Vector2.ZERO, Vector2(_tex.get_size()) - SIZE)
	draw_texture_rect_region(_tex, area, src)
	var to_screen := func(world: Vector2) -> Vector2:
		return area.position + world * scale - src.position
	_markers(to_screen, area, 1.0)
	_pois(to_screen, area, false)
	var pp: Vector2 = to_screen.call(p.global_position)
	_hero(pp, 1.0)
	var f := get_theme_default_font()
	var hint := "Mapa" if DisplayServer.is_touchscreen_available() else "M: mapa"
	draw_string(f, area.position + Vector2(2, SIZE.y - 2), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(1, 0.95, 0.8, 0.85))


func _draw_big(p: Node2D) -> void:
	var vp := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.03, 0.02, 0.02, 0.75))
	var fit := minf((vp.x - 40.0) / _tex.get_size().x, (vp.y - 40.0) / _tex.get_size().y)
	var sz := Vector2(_tex.get_size()) * fit
	var area := Rect2((vp - sz) / 2.0 + Vector2(0, 6), sz)
	draw_rect(area.grow(4), Color(0.2, 0.12, 0.07))
	draw_rect(area.grow(3), Color(0.62, 0.45, 0.22))
	draw_texture_rect(_tex, area, false)
	var scale := sz / _map_px
	var to_screen := func(world: Vector2) -> Vector2:
		return area.position + world * scale
	_markers(to_screen, area, 1.3)
	_pois(to_screen, area, true)
	_hero(to_screen.call(p.global_position), 1.5)
	var f := get_theme_default_font()
	var title := String(get_tree().current_scene.get("map_title")) if get_tree().current_scene.get("map_title") else "Mapa"
	draw_string(f, Vector2(area.position.x, area.position.y - 7), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 0.88, 0.55))
	draw_string(f, Vector2(area.end.x - 130, area.position.y - 7), "Rojo: monstruos   Oro: cofres   M: cerrar", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.95, 0.88, 0.72))


func _markers(to_screen: Callable, area: Rect2, k: float) -> void:
	for c in get_tree().get_nodes_in_group("chests"):
		if c.get("_opened"):
			continue
		var cp: Vector2 = to_screen.call((c as Node2D).global_position)
		if area.has_point(cp):
			var r := (2.0 + 0.5 * sin(_t * 5.0)) * k
			draw_rect(Rect2(cp - Vector2(r + 1, r + 1), Vector2(r + 1, r + 1) * 2), Color(0.25, 0.14, 0.02))
			draw_rect(Rect2(cp - Vector2(r, r), Vector2(r, r) * 2), Color(1, 0.84, 0.2))
	for m in get_tree().get_nodes_in_group("monsters"):
		if int(m.get("hp")) <= 0:
			continue
		var mp: Vector2 = to_screen.call((m as Node2D).global_position)
		if not area.has_point(mp):
			continue
		if m.get("boss"):
			draw_circle(mp, 2.5 * k, Color(1, 0.45, 0.1))
			draw_arc(mp, 3.5 * k, 0, TAU, 12, Color(0.2, 0.05, 0.02), 1.0)
		else:
			draw_rect(Rect2(mp - Vector2(1, 1) * k, Vector2(2, 2) * k), Color(0.9, 0.15, 0.1))
	for e in get_tree().current_scene.get_children():
		if e is Area2D and e.get("target_scene") != null and String(e.get("target_scene")) != "" and not String(e.name).begins_with("Door"):
			var ep: Vector2 = to_screen.call((e as Node2D).global_position)
			ep = ep.clamp(area.position + Vector2(3, 3), area.end - Vector2(3, 3))
			draw_rect(Rect2(ep - Vector2(2, 2) * k, Vector2(4, 4) * k), Color(0.3, 0.95, 0.4))


## Important characters and places: icon on a plate (and the name on the full map).
func _pois(to_screen: Callable, area: Rect2, big: bool) -> void:
	var items: Array = []
	for n in get_tree().get_nodes_in_group("poi"):
		items.append([(n as Node2D).global_position, String(n.get_meta("poi_kind", ""))])
	for e in get_tree().current_scene.get_children():
		if e is Area2D and e.get("label") != null and GameData.POI_DOORS.has(String(e.get("label"))):
			items.append([(e as Node2D).global_position, GameData.POI_DOORS[String(e.get("label"))]])
	var f := get_theme_default_font()
	for it in items:
		var d: Dictionary = GameData.POI.get(it[1], {})
		if d.is_empty():
			continue
		var p: Vector2 = to_screen.call(it[0])
		if not area.has_point(p):
			continue
		var r := 6.0 if big else 4.5
		draw_circle(p, r + 1.0, Color(0.2, 0.12, 0.06))
		draw_circle(p, r, Color(0.96, 0.88, 0.66))
		draw_texture_rect(Game.icon_texture(d["icon"]), Rect2(p - Vector2(r, r) * 0.8, Vector2(r, r) * 1.6), false)
		if big:
			var title: String = d.get("short", d["title"])
			var w := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
			draw_string_outline(f, p + Vector2(-w / 2.0, 15), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 3, Color(0.1, 0.06, 0.03))
			draw_string(f, p + Vector2(-w / 2.0, 15), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 0.9, 0.6))


func _hero(pp: Vector2, k: float) -> void:
	draw_circle(pp, 3.0 * k, Color(0.1, 0.06, 0.04))
	draw_circle(pp, 2.0 * k, Color(1, 1, 1))
