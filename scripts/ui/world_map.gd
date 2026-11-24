extends CanvasLayer
## World map (N): every region as its own map picture, the roads between them and where you are.
## Regions you have never visited stay hidden ("???") until you get there.

const PAPER := Color(0.93, 0.87, 0.72)
const INK := Color(0.25, 0.16, 0.1)
const INK_SOFT := Color(0.47, 0.33, 0.22)
const GOLD := Color(1, 0.8, 0.3)

var _root: Control
var _canvas: Control
var _t := 0.0
var _pics := {}
var _stone_buttons: Control   # one button per awake rune stone: click to travel
var _hover := ""


func _ready() -> void:
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.035, 0.03, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_map)
	_root.add_child(_canvas)
	_stone_buttons = Control.new()
	_stone_buttons.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stone_buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_stone_buttons)
	_root.hide()


func _unhandled_input(event: InputEvent) -> void:
	if _root.visible:
		if event.is_action_pressed("world_map") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause") or event.is_action_pressed("map"):
			get_viewport().set_input_as_handled()
			close()
		return
	if event.is_action_pressed("world_map") and _can_open():
		get_viewport().set_input_as_handled()
		open()


func _can_open() -> bool:
	return get_tree().get_first_node_in_group("player") != null and not Game.menu_open and not Game.input_locked and not Game.editing


func open() -> void:
	Game.sfx("ui_open", -2.0, 0.0)
	Game.menu_open = true
	get_tree().paused = true
	_root.show()
	_build_stone_buttons.call_deferred()


func close() -> void:
	_root.hide()
	get_tree().paused = false
	Game.menu_open = false


func _process(delta: float) -> void:
	if _root.visible:
		_t += delta
		_canvas.queue_redraw()


func _pic(path: String) -> Texture2D:
	if not _pics.has(path):
		_pics[path] = load(path) if ResourceLoader.exists(path) else null
	return _pics[path]


func _region(file: String) -> Dictionary:
	for r in GameData.WORLD_MAP:
		if r["file"] == file:
			return r
	return {}


func _rect(r: Dictionary, origin: Vector2) -> Rect2:
	var size: Vector2 = r["tiles"] * 2.0 * GameData.WORLD_SCALE
	return Rect2(origin + r["pos"], size)


## Top-left of the world drawing, so the whole world sits centred on screen.
func _origin() -> Vector2:
	var box := Rect2()
	for i in GameData.WORLD_MAP.size():
		var rr := _rect(GameData.WORLD_MAP[i], Vector2.ZERO)
		box = rr if i == 0 else box.merge(rr)
	return (_canvas.size - box.size) / 2.0 - box.position + Vector2(0, 8)


func _stone_point(w: Dictionary, origin: Vector2) -> Vector2:
	var r := _region(w["map"])
	return _rect(r, origin).position + (w["pos"] as Vector2) * 2.0 * GameData.WORLD_SCALE


## Awake rune stones become buttons on the map: hover shows the name, click travels there.
func _build_stone_buttons() -> void:
	for c in _stone_buttons.get_children():
		c.queue_free()
	var origin := _origin()
	for w in GameData.WAYSTONES:
		if not Game.is_waystone_unlocked(w["id"]):
			continue
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.size = Vector2(16, 16)
		b.position = _stone_point(w, origin) - Vector2(8, 8)
		b.tooltip_text = "Viajar a %s" % w["name"]
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var id: String = w["id"]
		b.mouse_entered.connect(func(): _hover = id)
		b.mouse_exited.connect(func(): if _hover == id: _hover = "")
		b.pressed.connect(func():
			close()
			Game.teleport_to(id))
		_stone_buttons.add_child(b)


func _draw_map() -> void:
	var f := ThemeDB.fallback_font
	var vs := _canvas.size
	var origin := _origin()
	var here := Game.map_file()
	# title
	var title := "Mapamundi"
	var tw := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	_canvas.draw_string_outline(f, Vector2((vs.x - tw) / 2.0, 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color(0.15, 0.08, 0.04))
	_canvas.draw_string(f, Vector2((vs.x - tw) / 2.0, 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GOLD)
	var hint := "Haz clic en una piedra rúnica ◆ para viajar   ·   N / Esc: cerrar"
	_canvas.draw_string(f, Vector2(vs.x - f.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x - 10, vs.y - 8), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.8, 0.72, 0.58))
	# roads between regions (dashed)
	for l in GameData.WORLD_LINKS:
		var ra := _region(l[0])
		var rb := _region(l[2])
		if ra.is_empty() or rb.is_empty():
			continue
		var a := _rect(ra, origin).position + (l[1] as Vector2) * 2.0 * GameData.WORLD_SCALE
		var b := _rect(rb, origin).position + (l[3] as Vector2) * 2.0 * GameData.WORLD_SCALE
		_canvas.draw_dashed_line(a, b, Color(0.95, 0.8, 0.5, 0.9), 2.0, 4.0)
	# regions
	for r in GameData.WORLD_MAP:
		var rect := _rect(r, origin)
		var seen: bool = Game.visited_maps.has(r["file"]) or r["file"] == here
		var current: bool = r["file"] == here
		_canvas.draw_rect(rect.grow(3), Color(0.12, 0.07, 0.04))
		if seen and _pic(r["pic"]):
			_canvas.draw_texture_rect(_pic(r["pic"]), rect, false)
		else:
			_canvas.draw_rect(rect, Color(0.22, 0.17, 0.13))
			var q := "???"
			var qw := f.get_string_size(q, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			_canvas.draw_string(f, rect.get_center() + Vector2(-qw / 2.0, 4), q, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.5, 0.4))
		var border := GOLD if current else Color(0.55, 0.42, 0.28)
		_canvas.draw_rect(rect.grow(2), border, false, 2.0 if current else 1.0)
		# name and levels under the picture
		var name_: String = r["name"] if seen else ""
		var lv: Array = GameData.MAP_LEVELS.get(r["file"], [])
		var sub := ("Nivel %d-%d" % [lv[0], lv[1]]) if lv.size() == 2 else "Ciudad · zona segura"
		var nw := f.get_string_size(name_, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var y := rect.end.y + 11
		_canvas.draw_string_outline(f, Vector2(rect.get_center().x - nw / 2.0, y), name_, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color(0.1, 0.06, 0.03))
		_canvas.draw_string(f, Vector2(rect.get_center().x - nw / 2.0, y), name_, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, GOLD if current else PAPER)
		if seen:
			var sw := f.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
			var col := Color(0.75, 0.95, 0.7) if lv.is_empty() else Game.level_color(int(lv[0]), Game.level)
			_canvas.draw_string_outline(f, Vector2(rect.get_center().x - sw / 2.0, y + 8), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, 2, Color(0.1, 0.06, 0.03))
			_canvas.draw_string(f, Vector2(rect.get_center().x - sw / 2.0, y + 8), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, col)
		# rune stones: awake ones glow (and are buttons), sleeping ones are faint
		if seen:
			for w in GameData.WAYSTONES:
				if w["map"] != r["file"]:
					continue
				var wp := _stone_point(w, origin)
				if Game.is_waystone_unlocked(w["id"]):
					var hover: bool = _hover == w["id"]
					var rad := 5.0 if hover else 3.6
					_canvas.draw_circle(wp, rad + 1.2, Color(0.1, 0.08, 0.2))
					_canvas.draw_circle(wp, rad, Color(0.6, 0.85, 1.0, 0.8 + 0.2 * sin(_t * 4.0)))
					if hover:
						var nm: String = w["name"]
						var nw2 := f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
						_canvas.draw_string_outline(f, wp + Vector2(-nw2 / 2.0, -9), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 3, Color(0.08, 0.05, 0.12))
						_canvas.draw_string(f, wp + Vector2(-nw2 / 2.0, -9), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.75, 0.9, 1.0))
				else:
					_canvas.draw_circle(wp, 2.0, Color(0.15, 0.12, 0.2, 0.7))
		# the story objective's region
		var st := Game.story_current()
		if not st.is_empty():
			var omap := String(st.get("map", ""))
			if omap.begins_with("guild") or omap == "home.tscn":
				omap = "world.tscn"
			if omap == r["file"]:
				var sp := rect.position + Vector2(rect.size.x - 6, 6)
				if st.has("pos") and String(st.get("map", "")) == r["file"]:
					sp = rect.position + (st["pos"] as Vector2) * 2.0 * GameData.WORLD_SCALE
				var rr := 5.0 + sin(_t * 5.0)
				var star := PackedVector2Array()
				for i in 10:
					var ang := -PI / 2.0 + i * TAU / 10.0
					star.append(sp + Vector2(cos(ang), sin(ang)) * (rr if i % 2 == 0 else rr * 0.45))
				_canvas.draw_colored_polygon(star, Color(1, 0.82, 0.2))
				_canvas.draw_string_outline(f, sp + Vector2(7, 3), "Objetivo", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, 3, Color(0.1, 0.06, 0.03))
				_canvas.draw_string(f, sp + Vector2(7, 3), "Objetivo", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(1, 0.85, 0.35))
		# you are here
		if current:
			var p := get_tree().get_first_node_in_group("player") as Node2D
			if p:
				var at := rect.position + p.global_position / 16.0 * 2.0 * GameData.WORLD_SCALE
				var pulse := 3.0 + 1.5 * sin(_t * 6.0)
				_canvas.draw_circle(at, pulse + 2.0, Color(1, 1, 1, 0.35))
				_canvas.draw_circle(at, 2.5, Color(0.1, 0.06, 0.04))
				_canvas.draw_circle(at, 1.6, Color(1, 0.3, 0.2))
				var lbl := "Estás aquí"
				_canvas.draw_string_outline(f, at + Vector2(6, -4), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 3, Color(0.1, 0.06, 0.03))
				_canvas.draw_string(f, at + Vector2(6, -4), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 0.9, 0.6))
