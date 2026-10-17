extends CanvasLayer
## In-game developer map editor ("RPG maker" style): move/place props and characters, paint tiles,
## paint smart terrain, undo, save the scene and play-test from the camera position.

const CATALOG_PATH := "res://resources/editor/catalog.json"
const WALKMASK_RES := "res://resources/world/walkmask.res"
const LAYER_NAMES := {
	"Ground": "Suelo", "GroundOverlay": "Tierra / superposición", "Road": "Caminos", "Detail": "Detalles",
	"Water": "Agua", "WaterFx": "Olas", "Coast": "Costa", "Dock": "Muelles", "DockFx": "Pilotes",
	"Fence": "Cercas", "Walls": "Muros", "Towers": "Torres", "Rim": "Bordes de fuente", "WaterCity": "Agua de fuente",
}
const TERRAINS := {
	"Camino empedrado": {"layer": "Road", "src": 3, "nine": [1, 1], "inner": {"se": [4, 1], "sw": [6, 1], "ne": [4, 3], "nw": [6, 3]}, "center": [[2, 2]]},
	"Sendero de tierra": {"layer": "GroundOverlay", "src": 2, "nine": [19, 1], "inner": {"se": [22, 1], "sw": [23, 1], "ne": [22, 2], "nw": [23, 2]}, "center": [[20, 2]]},
	"Tierra de cultivo": {"layer": "GroundOverlay", "src": 2, "field": true, "center": [[2, 2], [3, 2], [2, 3], [3, 3]]},
	"Pavimento de ladrillo": {"layer": "Ground", "src": 0, "brick": true},
	"Pasto": {"layer": "Ground", "src": 2, "single": [17, 8], "clears": ["GroundOverlay", "Road", "Detail"]},
	"Agua": {"layer": "Water", "src": 6, "single": [36, 0], "clears": ["Ground", "GroundOverlay", "Road", "Detail"], "solid": true},
}
## Ready-made tile stamps (layer, atlas source, rect in tiles). Dragging repeats the pattern.
const STAMPS := {
	"Muelle · tablones (horizontal)": {"layer": "Dock", "src": 7, "rect": [0, 0, 7, 4]},
	"Muelle · pasarela (vertical)": {"layer": "Dock", "src": 7, "rect": [7, 1, 2, 2]},
	"Muelle · punta de pasarela": {"layer": "Dock", "src": 7, "rect": [7, 3, 2, 1]},
	"Muelle · poste de amarre": {"layer": "DockFx", "src": 7, "rect": [4, 9, 1, 2]},
	"Muelle · poste de esquina": {"layer": "DockFx", "src": 7, "rect": [3, 9, 1, 2]},
	"Muelle · pilote en el agua": {"layer": "DockFx", "src": 8, "rect": [0, 0, 1, 2]},
	"Valla de madera · horizontal": {"layer": "Fence", "src": 9, "rect": [9, 10, 2, 1], "solid": true},
	"Valla de madera · lado izquierdo": {"layer": "Fence", "src": 9, "rect": [11, 9, 1, 3], "solid": true},
	"Valla de madera · lado derecho": {"layer": "Fence", "src": 9, "rect": [12, 9, 1, 3], "solid": true},
	"Valla de madera · esquinas inferiores": {"layer": "Fence", "src": 9, "rect": [18, 11, 3, 1], "solid": true},
	"Cerca de granja · corral 3×3": {"layer": "Fence", "src": 2, "rect": [20, 15, 3, 3], "solid": true},
	"Cerca de granja · tramo horizontal": {"layer": "Fence", "src": 2, "rect": [21, 15, 1, 1], "solid": true},
	"Cerca de granja · tramo vertical": {"layer": "Fence", "src": 2, "rect": [20, 16, 1, 1], "solid": true},
}
const TOOL_INFO := {
	"select": ["Seleccionar [V]", "Clic: seleccionar · Arrastrar: mover · F: voltear · Ctrl+D: duplicar · Supr: eliminar"],
	"object": ["Objetos [O]", "Elige un objeto en la paleta y haz clic en el mapa para colocarlo. Clic derecho: soltar."],
	"paint": ["Pintar tiles [B]", "Elige una plantilla, o una capa y un tile. Mantén el clic y arrastra sobre la paleta para tomar varios tiles juntos. Clic: pintar (arrastrando se repite el patrón) · Clic derecho: borrar."],
	"terrain": ["Terreno [T]", "Pinceles con bordes automáticos. Clic: pintar · Clic derecho: borrar."],
	"erase": ["Goma [E]", "Borra tiles de la capa elegida."],
}

var world: Node2D
var cam: Camera2D
var canvas: Node2D
var catalog := {}
var tool := "select"
var show_grid := true
var snap := true
var brush_size := 1
var mouse_over_world := false

var selected: Node2D
var hovered: Node2D
var place_item: Dictionary = {}
var _ghost_tex: Texture2D
var paint_layer: TileMapLayer
var paint_source := -1
var paint_coords := Vector2i.ZERO
var paint_size := Vector2i.ONE      # stamp size in tiles (drag on the palette to pick several)
var _stamp_anchor := Vector2i.ZERO   # cell where the current stroke started; the pattern repeats from here
var _atlas_drag := false
var _atlas_from := Vector2i.ZERO
var _empty_cache := {}               # "src|x|y" -> tile is fully transparent
var paint_texture: Texture2D
var terrain_name := "Camino empedrado"

var _undo: Array = []
var _stroke: Dictionary = {}
var _dragging := false
var _drag_from := Vector2.ZERO
var _drag_offset := Vector2.ZERO
var _panning := false
var _dirty := false
var _counter := 0
var _prev_scale_mode := 0
var _test_positions := {}
var _testing := false

# UI
var _root: Control
var _tool_buttons := {}
var _panels := {}
var _status: Label
var _dock_title: Label
var _inspector: Label
var _obj_grid: GridContainer
var _obj_category: OptionButton
var _obj_search: LineEdit
var _paint_layer_opt: OptionButton
var _paint_src_opt: OptionButton
var _paint_collision: CheckBox
var _stamp_opt: OptionButton
var _atlas_rect: TextureRect
var _atlas_sel: ColorRect
var _erase_layer_opt: OptionButton
var _terrain_list: ItemList
var _busy_label: Label
var _test_bar: Control
var _layers: Array[TileMapLayer] = []


func _ready() -> void:
	layer = 50
	world = get_tree().current_scene as Node2D
	Game.input_locked = true
	var f := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if f:
		catalog = JSON.parse_string(f.get_as_text())
	_prev_scale_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	cam = Camera2D.new()
	cam.zoom = Vector2(3, 3)
	world.add_child(cam)
	var player := world.get_node_or_null("Entities/Player") as Node2D
	cam.global_position = player.global_position if player else Vector2(640, 480)
	cam.make_current()
	canvas = Node2D.new()
	canvas.set_script(load("res://scripts/editor/editor_canvas.gd"))
	canvas.editor = self
	world.add_child(canvas)
	var hud := world.get_node_or_null("HUD") as CanvasLayer
	if hud:
		hud.visible = false
	var order := ["Ground", "GroundOverlay", "Road", "Detail", "Walls", "Fence", "Dock", "Coast", "Water", "WaterFx", "Towers", "DockFx", "Rim", "WaterCity"]
	var found: Array[TileMapLayer] = []
	for c in world.get_children():
		if c is TileMapLayer:
			found.append(c)
	for n in order:
		for l in found:
			if String(l.name) == n:
				_layers.append(l)
	for l in found:
		if not l in _layers:
			_layers.append(l)
	_build_ui()
	_set_tool("select")
	_flash("Modo desarrollador activo. Guarda con Ctrl+S.")


# =============================================================================
# UI
# =============================================================================

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var th := Theme.new()
	th.default_font_size = 15
	_root.theme = th
	add_child(_root)
	# top bar
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 46
	_root.add_child(top)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	top.add_child(hb)
	var title := Label.new()
	title.text = "  MODO DESARROLLADOR  "
	title.add_theme_color_override("font_color", Color(0.7, 0.85, 1))
	hb.add_child(title)
	for t in ["select", "object", "paint", "terrain", "erase"]:
		var b := Button.new()
		b.text = TOOL_INFO[t][0]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_set_tool.bind(t))
		hb.add_child(b)
		_tool_buttons[t] = b
	hb.add_child(VSeparator.new())
	var grid := CheckBox.new(); grid.text = "Grilla [G]"; grid.button_pressed = true; grid.focus_mode = Control.FOCUS_NONE
	grid.toggled.connect(func(v): show_grid = v)
	hb.add_child(grid)
	var sn := CheckBox.new(); sn.text = "Ajustar"; sn.button_pressed = true; sn.focus_mode = Control.FOCUS_NONE
	sn.tooltip_text = "Ajusta posiciones a la grilla de 8 px (mantén Shift para mover libre)"
	sn.toggled.connect(func(v): snap = v)
	hb.add_child(sn)
	var spacer := Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(spacer)
	for pair in [["Deshacer", _undo_last], ["Guardar", _save], ["Probar aquí", _start_test], ["Salir", _exit]]:
		var b := Button.new(); b.text = pair[0]; b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(pair[1])
		hb.add_child(b)
	# left dock
	var dock := PanelContainer.new()
	dock.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	dock.offset_top = 50
	dock.offset_bottom = -34
	dock.offset_right = 330
	_root.add_child(dock)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 8)
	dock.add_child(dv)
	_dock_title = Label.new()
	_dock_title.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	dv.add_child(_dock_title)
	_panels["select"] = _build_select_panel()
	_panels["object"] = _build_object_panel()
	_panels["paint"] = _build_paint_panel()
	_panels["terrain"] = _build_terrain_panel()
	_panels["erase"] = _build_erase_panel()
	for p in _panels.values():
		p.size_flags_vertical = Control.SIZE_EXPAND_FILL
		dv.add_child(p)
	# status bar
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -30
	_root.add_child(bar)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 13)
	bar.add_child(_status)
	_busy_label = Label.new()
	_busy_label.set_anchors_preset(Control.PRESET_CENTER)
	_busy_label.add_theme_font_size_override("font_size", 26)
	_busy_label.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	_busy_label.add_theme_constant_override("outline_size", 8)
	_busy_label.visible = false
	_root.add_child(_busy_label)
	# play-test bar
	_test_bar = PanelContainer.new()
	_test_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_test_bar.offset_left = -260
	_test_bar.offset_bottom = 46
	var back := Button.new(); back.text = "Volver al editor [F1]"; back.pressed.connect(_stop_test)
	_test_bar.add_child(back)
	_test_bar.visible = false
	add_child(_test_bar)
	_test_bar.theme = th


func _help(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(0.82, 0.78, 0.7))
	return l


func _build_select_panel() -> Control:
	var v := VBoxContainer.new()
	v.add_child(_help(TOOL_INFO["select"][1] + "\n\nCámara: WASD/flechas o botón central del mouse · Rueda: zoom"))
	_inspector = Label.new()
	_inspector.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inspector.text = "Nada seleccionado"
	v.add_child(_inspector)
	var hb := HBoxContainer.new()
	for pair in [["Voltear", _flip_selected], ["Duplicar", _duplicate_selected], ["Eliminar", _delete_selected]]:
		var b := Button.new(); b.text = pair[0]; b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(pair[1])
		hb.add_child(b)
	v.add_child(hb)
	return v


func _build_object_panel() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_obj_category = OptionButton.new()
	_obj_category.focus_mode = Control.FOCUS_NONE
	var cats: Array = []
	for it in catalog.get("items", []):
		if not it["category"] in cats:
			cats.append(it["category"])
	for ch in catalog.get("characters", []):
		if not ch["category"] in cats:
			cats.append(ch["category"])
	for c in cats:
		_obj_category.add_item(c)
	_obj_category.item_selected.connect(func(_i): _fill_objects())
	v.add_child(_obj_category)
	_obj_search = LineEdit.new()
	_obj_search.placeholder_text = "Buscar..."
	_obj_search.text_changed.connect(func(_t): _fill_objects())
	v.add_child(_obj_search)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	_obj_grid = GridContainer.new()
	_obj_grid.columns = 4
	_obj_grid.add_theme_constant_override("h_separation", 4)
	_obj_grid.add_theme_constant_override("v_separation", 4)
	sc.add_child(_obj_grid)
	v.add_child(_help(TOOL_INFO["object"][1]))
	_fill_objects()
	return v


func _thumb_for_item(it: Dictionary) -> Texture2D:
	var at := AtlasTexture.new()
	at.atlas = load(it["texture"])
	var r: Array = it["region"]
	at.region = Rect2(r[0], r[1], r[2], r[3])
	return at


func _thumb_for_char(ch: Dictionary) -> Texture2D:
	var sf := load(ch["frames"]) as SpriteFrames
	if sf == null:
		return null
	for a in [&"default", &"idle_down", &"walk_down"]:
		if sf.has_animation(a) and sf.get_frame_count(a) > 0:
			return sf.get_frame_texture(a, 0)
	var names := sf.get_animation_names()
	return sf.get_frame_texture(names[0], 0) if names.size() > 0 else null


func _fill_objects() -> void:
	for c in _obj_grid.get_children():
		c.queue_free()
	if _obj_category.item_count == 0:
		return
	var cat := _obj_category.get_item_text(_obj_category.selected)
	var q := _obj_search.text.to_lower() if _obj_search else ""
	var entries: Array = []
	for it in catalog.get("items", []):
		if it["category"] == cat and (q == "" or q in String(it["name"]).to_lower()):
			entries.append({"kind": "item", "data": it, "tex": null})
	for ch in catalog.get("characters", []):
		if ch["category"] == cat and (q == "" or q in String(ch["name"]).to_lower()):
			entries.append({"kind": "char", "data": ch, "tex": null})
	for e in entries:
		var b := Button.new()
		b.custom_minimum_size = Vector2(72, 72)
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = e["data"]["name"]
		b.icon = _thumb_for_item(e["data"]) if e["kind"] == "item" else _thumb_for_char(e["data"])
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.pressed.connect(_pick_entry.bind(e))
		_obj_grid.add_child(b)


func _build_paint_panel() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_stamp_opt = OptionButton.new()
	_stamp_opt.focus_mode = Control.FOCUS_NONE
	_stamp_opt.add_item("Plantillas: muelle y vallas...")
	for k in STAMPS:
		_stamp_opt.add_item(k)
	_stamp_opt.item_selected.connect(_on_stamp_selected)
	v.add_child(_stamp_opt)
	_paint_layer_opt = _layer_option()
	_paint_layer_opt.item_selected.connect(func(_i): paint_layer = _layer_from(_paint_layer_opt))
	v.add_child(_paint_layer_opt)
	_paint_src_opt = OptionButton.new()
	_paint_src_opt.focus_mode = Control.FOCUS_NONE
	var ts := _first_tileset()
	if ts:
		for i in ts.get_source_count():
			var sid := ts.get_source_id(i)
			var src := ts.get_source(sid) as TileSetAtlasSource
			if src and src.texture:
				_paint_src_opt.add_item(src.texture.resource_path.get_file().get_basename(), sid)
	_paint_src_opt.item_selected.connect(func(_i):
		paint_coords = Vector2i.ZERO
		paint_size = Vector2i.ONE
		_show_atlas())
	v.add_child(_paint_src_opt)
	_paint_collision = CheckBox.new()
	_paint_collision.text = "Tile con colisión (sólido)"
	_paint_collision.focus_mode = Control.FOCUS_NONE
	v.add_child(_paint_collision)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	_atlas_rect = TextureRect.new()
	_atlas_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_atlas_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_atlas_rect.gui_input.connect(_on_atlas_input)
	sc.add_child(_atlas_rect)
	_atlas_sel = ColorRect.new()
	_atlas_sel.color = Color(1, 0.85, 0.3, 0.45)
	_atlas_sel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_atlas_rect.add_child(_atlas_sel)
	v.add_child(_help(TOOL_INFO["paint"][1]))
	paint_layer = _layer_from(_paint_layer_opt)
	_show_atlas()
	return v


func _build_terrain_panel() -> Control:
	var v := VBoxContainer.new()
	_terrain_list = ItemList.new()
	_terrain_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_terrain_list.focus_mode = Control.FOCUS_NONE
	for k in TERRAINS:
		_terrain_list.add_item(k)
	_terrain_list.select(0)
	_terrain_list.item_selected.connect(func(i): terrain_name = _terrain_list.get_item_text(i))
	v.add_child(_terrain_list)
	v.add_child(_brush_size_row())
	v.add_child(_help(TOOL_INFO["terrain"][1]))
	return v


func _build_erase_panel() -> Control:
	var v := VBoxContainer.new()
	_erase_layer_opt = _layer_option()
	v.add_child(_erase_layer_opt)
	v.add_child(_brush_size_row())
	v.add_child(_help(TOOL_INFO["erase"][1]))
	return v


func _brush_size_row() -> Control:
	var hb := HBoxContainer.new()
	var l := Label.new(); l.text = "Tamaño del pincel"
	hb.add_child(l)
	var sp := SpinBox.new(); sp.min_value = 1; sp.max_value = 7; sp.step = 1; sp.value = brush_size
	sp.value_changed.connect(func(v): brush_size = int(v))
	hb.add_child(sp)
	return hb


func _layer_option() -> OptionButton:
	var o := OptionButton.new()
	o.focus_mode = Control.FOCUS_NONE
	for l in _layers:
		if l.name == "Solids":
			continue
		o.add_item(LAYER_NAMES.get(String(l.name), String(l.name)))
		o.set_item_metadata(o.item_count - 1, l)
	if o.item_count == 0:
		o.add_item("(este mapa no tiene capas de tiles)")
		o.disabled = true
	return o


func _layer_from(o: OptionButton) -> TileMapLayer:
	if o.disabled or o.item_count == 0:
		return null
	return o.get_item_metadata(o.selected) as TileMapLayer


func _first_tileset() -> TileSet:
	for l in _layers:
		if l.tile_set:
			return l.tile_set
	return null


func _show_atlas() -> void:
	var ts := _first_tileset()
	if ts == null or _paint_src_opt.item_count == 0:
		return
	paint_source = _paint_src_opt.get_item_id(_paint_src_opt.selected)
	var src := ts.get_source(paint_source) as TileSetAtlasSource
	paint_texture = src.texture
	_atlas_rect.texture = src.texture
	_atlas_rect.custom_minimum_size = src.texture.get_size() * 2.0
	_update_atlas_sel()


func _update_atlas_sel() -> void:
	_atlas_sel.size = Vector2(paint_size) * 32.0
	_atlas_sel.position = Vector2(paint_coords) * 32.0


## Click a tile, or hold and drag to pick a block of tiles (RPG Maker style).
func _on_atlas_input(ev: InputEvent) -> void:
	var grid := Vector2i.ONE
	if paint_texture:
		grid = Vector2i(paint_texture.get_size() / 16.0)
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		var c := Vector2i((ev as InputEventMouseButton).position / 32.0).clamp(Vector2i.ZERO, grid - Vector2i.ONE)
		if ev.pressed:
			_atlas_drag = true
			_atlas_from = c
			_set_atlas_rect(c, c)
		elif _atlas_drag:
			_atlas_drag = false
			if paint_size == Vector2i.ONE:
				_flash("Tile %s elegido" % paint_coords)
			else:
				_flash("Bloque de %d×%d tiles elegido" % [paint_size.x, paint_size.y])
	elif ev is InputEventMouseMotion and _atlas_drag:
		var c := Vector2i((ev as InputEventMouseMotion).position / 32.0).clamp(Vector2i.ZERO, grid - Vector2i.ONE)
		_set_atlas_rect(_atlas_from, c)


func _set_atlas_rect(a: Vector2i, b: Vector2i) -> void:
	paint_coords = Vector2i(mini(a.x, b.x), mini(a.y, b.y))
	paint_size = Vector2i(absi(a.x - b.x) + 1, absi(a.y - b.y) + 1)
	_update_atlas_sel()


func _on_stamp_selected(i: int) -> void:
	if i == 0:
		return
	var st: Dictionary = STAMPS[_stamp_opt.get_item_text(i)]
	var found := false
	for j in _paint_layer_opt.item_count:
		var l := _paint_layer_opt.get_item_metadata(j) as TileMapLayer
		if l and String(l.name) == st["layer"]:
			_paint_layer_opt.select(j)
			paint_layer = l
			found = true
	if not found:
		_flash("Este mapa no tiene la capa %s." % st["layer"])
		return
	var idx := _paint_src_opt.get_item_index(int(st["src"]))
	if idx < 0:
		_flash("Este mapa no tiene esa hoja de tiles.")
		return
	_paint_src_opt.select(idx)
	_show_atlas()
	var r: Array = st["rect"]
	paint_coords = Vector2i(r[0], r[1])
	paint_size = Vector2i(r[2], r[3])
	_paint_collision.button_pressed = st.get("solid", false)
	_update_atlas_sel()
	_flash("Plantilla: %s" % _stamp_opt.get_item_text(i))


## Top-left cell of the stamp block containing `c` (blocks repeat from the stroke's first cell).
func stamp_origin_for(c: Vector2i) -> Vector2i:
	var d := c - _stamp_anchor
	return c - Vector2i(posmod(d.x, paint_size.x), posmod(d.y, paint_size.y))


func _tile_is_empty(source_id: int, coords: Vector2i) -> bool:
	var key := "%d|%d|%d" % [source_id, coords.x, coords.y]
	if _empty_cache.has(key):
		return _empty_cache[key]
	var empty := false
	var src := _first_tileset().get_source(source_id) as TileSetAtlasSource
	if src and src.texture:
		var img := src.texture.get_image()
		if img:
			empty = img.get_region(Rect2i(coords * 16, Vector2i(16, 16))).is_invisible()
	_empty_cache[key] = empty
	return empty


func _set_tool(t: String) -> void:
	tool = t
	for k in _tool_buttons:
		_tool_buttons[k].button_pressed = k == t
	for k in _panels:
		_panels[k].visible = k == t
	_dock_title.text = TOOL_INFO[t][0]
	if t != "object":
		place_item = {}


func _flash(text: String) -> void:
	if _status:
		_status.text = "  " + text


# =============================================================================
# Input
# =============================================================================

func _process(delta: float) -> void:
	if _testing:
		if Input.is_key_pressed(KEY_F1):
			_stop_test()
		return
	var focus := get_viewport().gui_get_focus_owner()
	if not (focus is LineEdit or focus is SpinBox):
		var v := Vector2.ZERO
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): v.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): v.x += 1
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): v.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): v.y += 1
		if not Input.is_key_pressed(KEY_CTRL):
			cam.global_position += v * 420.0 * delta / cam.zoom.x
	var hovered_ctrl := get_viewport().gui_get_hovered_control()
	mouse_over_world = hovered_ctrl == null
	var m := _mouse_world()
	var cell := Vector2i(floor(m.x / 16.0), floor(m.y / 16.0))
	if tool == "select" and not _dragging and mouse_over_world:
		hovered = _pick_at(m)
	var info := "Celda %d, %d  ·  Píxel %d, %d  ·  Zoom x%.1f" % [cell.x, cell.y, int(m.x), int(m.y), cam.zoom.x]
	if selected and is_instance_valid(selected):
		info += "  ·  Seleccionado: %s" % selected.name
	_status.text = "  " + info + ("   ●  cambios sin guardar" if _dirty else "")


func _unhandled_input(ev: InputEvent) -> void:
	if _testing:
		return
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_at(1.15)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_at(1.0 / 1.15)
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_on_left_down()
			else:
				_on_left_up()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_on_right_down()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and not mb.pressed:
			_end_stroke()
	elif ev is InputEventMouseMotion:
		var mm := ev as InputEventMouseMotion
		if _panning:
			cam.global_position -= mm.relative / cam.zoom.x
		elif _dragging and selected:
			var target := _mouse_world() + _drag_offset
			if snap and not Input.is_key_pressed(KEY_SHIFT):
				target = target.snapped(Vector2(8, 8))
			selected.global_position = target
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and tool in ["paint", "terrain", "erase"]:
			_paint_at(_mouse_world(), false)
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and tool in ["paint", "terrain"]:
			_paint_at(_mouse_world(), true)
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		var k := ev as InputEventKey
		var focus := get_viewport().gui_get_focus_owner()
		if focus is LineEdit:
			return
		if k.ctrl_pressed and k.keycode == KEY_Z: _undo_last()
		elif k.ctrl_pressed and k.keycode == KEY_S: _save()
		elif k.ctrl_pressed and k.keycode == KEY_D: _duplicate_selected()
		elif k.keycode == KEY_DELETE or k.keycode == KEY_BACKSPACE: _delete_selected()
		elif k.keycode == KEY_F: _flip_selected()
		elif k.keycode == KEY_V: _set_tool("select")
		elif k.keycode == KEY_O: _set_tool("object")
		elif k.keycode == KEY_B: _set_tool("paint")
		elif k.keycode == KEY_T: _set_tool("terrain")
		elif k.keycode == KEY_E: _set_tool("erase")
		elif k.keycode == KEY_G: show_grid = not show_grid
		elif k.keycode == KEY_ESCAPE:
			selected = null
			place_item = {}
		get_viewport().set_input_as_handled()


func _zoom_at(factor: float) -> void:
	var before := _mouse_world()
	var z := clampf(cam.zoom.x * factor, 0.6, 8.0)
	cam.zoom = Vector2(z, z)
	var after := _mouse_world()
	cam.global_position += before - after


func _mouse_world() -> Vector2:
	return canvas.get_global_mouse_position()


func visible_world_rect() -> Rect2:
	var vs := get_viewport().get_visible_rect().size / cam.zoom.x
	var c := cam.get_screen_center_position()
	return Rect2(c - vs / 2.0, vs)


func snapped_mouse() -> Vector2:
	var m := _mouse_world()
	if snap and not Input.is_key_pressed(KEY_SHIFT):
		m = m.snapped(Vector2(8, 8))
	return m


func _on_left_down() -> void:
	var m := _mouse_world()
	match tool:
		"select":
			selected = _pick_at(m)
			_update_inspector()
			if selected:
				_dragging = true
				_drag_from = selected.global_position
				_drag_offset = selected.global_position - m
		"object":
			if place_item:
				_place(snapped_mouse())
			else:
				_flash("Elige primero un objeto en la paleta.")
		"paint", "terrain", "erase":
			_stamp_anchor = Vector2i(floor(m.x / 16.0), floor(m.y / 16.0))
			_paint_at(m, false)


func _on_left_up() -> void:
	if _dragging and selected:
		if selected.global_position != _drag_from:
			_push_undo({"type": "move", "node": selected, "from": _drag_from, "to": selected.global_position})
	_dragging = false
	_end_stroke()


func _on_right_down() -> void:
	match tool:
		"object":
			place_item = {}
			_flash("Colocación cancelada.")
		"paint", "terrain":
			var m := _mouse_world()
			_stamp_anchor = Vector2i(floor(m.x / 16.0), floor(m.y / 16.0))
			_paint_at(m, true)
		"select":
			selected = null
			_update_inspector()


# =============================================================================
# Selection & objects
# =============================================================================

func _containers() -> Array:
	var out: Array = []
	for path in ["Entities/Props", "Entities/Actors", "Entities/Citizens", "Entities/Animals", "Entities", "FloorDecor"]:
		var n := world.get_node_or_null(path)
		if n:
			out.append(n)
	return out


func _selectables() -> Array:
	var out: Array = []
	for cont in _containers():
		for c in cont.get_children():
			if c is Node2D and not (String(c.name) in ["Props", "Actors", "Citizens", "Animals", "Player"]):
				out.append(c)
	return out


func node_rect(n: Node2D) -> Rect2:
	var spr: Node = n if (n is Sprite2D or n is AnimatedSprite2D) else null
	if spr == null:
		for c in n.get_children():
			if c is Sprite2D or c is AnimatedSprite2D:
				spr = c
				break
	if spr is Sprite2D:
		var s := spr as Sprite2D
		var r := s.get_rect()
		return Rect2(s.global_position + r.position, r.size)
	if spr is AnimatedSprite2D:
		var a := spr as AnimatedSprite2D
		var sz := Vector2(32, 32)
		if a.sprite_frames and a.sprite_frames.has_animation(a.animation) and a.sprite_frames.get_frame_count(a.animation) > 0:
			sz = a.sprite_frames.get_frame_texture(a.animation, 0).get_size()
		return Rect2(a.global_position + a.offset - sz / 2.0, sz)
	return Rect2(n.global_position - Vector2(8, 8), Vector2(16, 16))


func _pick_at(p: Vector2) -> Node2D:
	var best: Node2D = null
	var best_floor: Node2D = null
	for n in _selectables():
		if not (n as CanvasItem).visible:
			continue
		var r := node_rect(n)
		if r.has_point(p):
			if n.get_parent().name == "FloorDecor":
				best_floor = n
			elif best == null or n.global_position.y > best.global_position.y:
				best = n
	return best if best else best_floor


func _update_inspector() -> void:
	if selected == null or not is_instance_valid(selected):
		_inspector.text = "Nada seleccionado"
		return
	var kind := "Objeto"
	if selected.scene_file_path.ends_with("walker.tscn"):
		kind = "Ciudadano (camina)"
	elif selected.scene_file_path.ends_with("actor.tscn"):
		kind = "Personaje / animación"
	elif selected.scene_file_path.ends_with("wild_animal.tscn"):
		kind = "Animal"
	_inspector.text = "%s\n%s\nPosición: %d, %d" % [selected.name, kind, int(selected.global_position.x), int(selected.global_position.y)]


func _pick_entry(e: Dictionary) -> void:
	place_item = e
	_set_tool("object")
	place_item = e
	_ghost_tex = _thumb_for_item(e["data"]) if e["kind"] == "item" else _thumb_for_char(e["data"])
	_flash("Colocando: %s  (clic para colocar, clic derecho para soltar)" % e["data"]["name"])


func draw_ghost(c: CanvasItem, at: Vector2) -> void:
	if _ghost_tex == null:
		return
	var sz := _ghost_tex.get_size()
	var off := Vector2(-sz.x / 2.0, -sz.y)
	if place_item["kind"] == "item":
		var o: Array = place_item["data"]["origin"]
		off = Vector2(-o[0], -o[1])
	elif place_item["data"].has("offset_y"):
		off = Vector2(-sz.x / 2.0, float(place_item["data"]["offset_y"]) - sz.y / 2.0)
	c.draw_texture(_ghost_tex, at + off, Color(1, 1, 1, 0.6))


func _set_owner_rec(n: Node) -> void:
	n.owner = world
	if n.scene_file_path != "" and n != world:
		return
	for c in n.get_children():
		_set_owner_rec(c)


func _unique_name(base: String) -> String:
	_counter += 1
	return "%s_ed%d" % [base, _counter + Time.get_ticks_msec() % 100000]


func _place(at: Vector2) -> void:
	var e := place_item
	var d: Dictionary = e["data"]
	var node: Node2D
	var parent: Node
	if e["kind"] == "item":
		node = _make_prop(d)
		parent = world.get_node_or_null("FloorDecor") if d["floor"] else world.get_node_or_null("Entities/Props")
	else:
		node = _make_character(d, at)
		parent = world.get_node_or_null("Entities/Citizens" if d.get("walker", false) else ("Entities/Animals" if d.get("animal", false) else "Entities/Actors"))
	if parent == null:
		parent = world.get_node_or_null("Entities")
	if parent == null:
		parent = world
	node.position = at
	parent.add_child(node)
	_set_owner_rec(node)
	_push_undo({"type": "add", "node": node, "parent": parent})
	_flash("Colocado: %s" % d["name"])


func _make_prop(d: Dictionary) -> Node2D:
	var spr := Sprite2D.new()
	spr.texture = load(d["texture"])
	spr.centered = false
	var o: Array = d["origin"]
	spr.offset = Vector2(-o[0], -o[1])
	spr.region_enabled = true
	var r: Array = d["region"]
	spr.region_rect = Rect2(r[0], r[1], r[2], r[3])
	var base := String(d["key"]).capitalize().replace(" ", "")
	var feet: Array = d["feet"]
	if d["floor"] or feet.is_empty():
		spr.name = _unique_name(base)
		return spr
	var body := StaticBody2D.new()
	body.name = _unique_name(base)
	body.collision_mask = 0
	spr.name = "Sprite2D"
	body.add_child(spr)
	var i := 0
	for f in feet:
		var cs := CollisionShape2D.new()
		cs.name = "Shape%d" % i
		var rs := RectangleShape2D.new()
		rs.size = Vector2(f[2] - f[0], f[3] - f[1])
		cs.shape = rs
		cs.position = Vector2((f[0] + f[2]) / 2.0, (f[1] + f[3]) / 2.0)
		body.add_child(cs)
		i += 1
	return body


func _make_character(d: Dictionary, at: Vector2) -> Node2D:
	var n: Node2D
	var frames := load(d["frames"]) as SpriteFrames
	if d.get("walker", false):
		n = load("res://scenes/npc/walker.tscn").instantiate()
		n.set("frames", frames)
		n.set("npc_name", d["name"])
		n.set("lines", PackedStringArray(["¡Buen día!", "¿Has visto el mercado hoy?", "Valdoria es preciosa."]))
		n.set("guard", d.get("guard", false))
		n.set("mode", "guard" if d.get("guard", false) else "stroller")
		n.set("brain", true)
	elif d.get("animal", false):
		n = load("res://scenes/npc/wild_animal.tscn").instantiate()
		n.set("frames", frames)
		n.set("wander_rect", Rect2(at - Vector2(96, 64), Vector2(192, 128)))
	else:
		n = load("res://scenes/npc/actor.tscn").instantiate()
		n.set("frames", frames)
		n.set("sprite_offset", Vector2(0, float(d.get("offset_y", -12))))
		n.set("collide", d.get("collide", true))
	n.name = _unique_name(String(d["name"]).replace(" ", ""))
	return n


func _flip_selected() -> void:
	if selected == null:
		return
	var spr: Node = null
	for c in [selected] + selected.get_children():
		if c is Sprite2D or c is AnimatedSprite2D:
			spr = c
			break
	if spr:
		if selected.has_method("_apply") and "flip" in selected:
			selected.set("flip", not selected.get("flip"))
		else:
			spr.flip_h = not spr.flip_h
			for cs in selected.find_children("*", "CollisionShape2D", false, false):
				(cs as Node2D).position.x = -(cs as Node2D).position.x
		_dirty = true
		_push_undo({"type": "flip", "node": selected})


func _duplicate_selected() -> void:
	if selected == null:
		return
	var dup := selected.duplicate() as Node2D
	dup.name = _unique_name(String(selected.name).split("_ed")[0])
	selected.get_parent().add_child(dup)
	dup.global_position = selected.global_position + Vector2(16, 8)
	_set_owner_rec(dup)
	_push_undo({"type": "add", "node": dup, "parent": selected.get_parent()})
	selected = dup
	_update_inspector()


func _delete_selected() -> void:
	if selected == null or not is_instance_valid(selected):
		return
	var parent := selected.get_parent()
	var idx := selected.get_index()
	parent.remove_child(selected)
	_push_undo({"type": "delete", "node": selected, "parent": parent, "index": idx})
	_flash("Eliminado: %s (Ctrl+Z para deshacer)" % selected.name)
	selected = null
	_update_inspector()


# =============================================================================
# Tiles & terrain
# =============================================================================

func _layer_named(n: String) -> TileMapLayer:
	return world.get_node_or_null(n) as TileMapLayer


func _record(layer: TileMapLayer, cell: Vector2i) -> void:
	var key := "%s|%d|%d" % [layer.name, cell.x, cell.y]
	if _stroke.has(key):
		return
	_stroke[key] = [layer, cell, layer.get_cell_source_id(cell), layer.get_cell_atlas_coords(cell), layer.get_cell_alternative_tile(cell)]


func _end_stroke() -> void:
	if not _stroke.is_empty():
		_push_undo({"type": "tiles", "cells": _stroke.values()})
		_stroke = {}


func _ensure_tile(source_id: int, coords: Vector2i, solid := false) -> bool:
	var ts := _first_tileset()
	var src := ts.get_source(source_id) as TileSetAtlasSource
	if src == null:
		return false
	if not src.has_tile(coords):
		var base := src.get_tile_at_coords(coords)
		if base != Vector2i(-1, -1):
			return false   # part of another (animated) tile
		if coords.x < 0 or coords.y < 0 or coords.x >= src.get_atlas_grid_size().x or coords.y >= src.get_atlas_grid_size().y:
			return false
		if not src.has_room_for_tile(coords, Vector2i.ONE, 1, Vector2i.ZERO, 1):
			return false
		src.create_tile(coords)
	if solid:
		var td := src.get_tile_data(coords, 0)
		if td.get_collision_polygons_count(0) == 0:
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))
	return true


func _set_cell(layer: TileMapLayer, cell: Vector2i, source_id: int, coords: Vector2i) -> void:
	_record(layer, cell)
	if source_id < 0:
		layer.erase_cell(cell)
	else:
		layer.set_cell(cell, source_id, coords)
	_dirty = true


func _paint_at(p: Vector2, erase: bool) -> void:
	if not mouse_over_world:
		return
	var c := Vector2i(floor(p.x / 16.0), floor(p.y / 16.0))
	match tool:
		"paint":
			if paint_layer == null:
				_flash("Este mapa no tiene capas de tiles para pintar.")
				return
			# paint (or erase) the whole stamp block that contains c
			var o := stamp_origin_for(c)
			var bad := false
			for dy in paint_size.y:
				for dx in paint_size.x:
					var cell := o + Vector2i(dx, dy)
					if erase:
						if paint_layer.get_cell_source_id(cell) != -1:
							_set_cell(paint_layer, cell, -1, Vector2i.ZERO)
						continue
					var at := paint_coords + Vector2i(dx, dy)
					if _tile_is_empty(paint_source, at):
						continue   # transparent parts of a stamp keep what is underneath
					if _ensure_tile(paint_source, at, _paint_collision.button_pressed):
						if paint_layer.get_cell_source_id(cell) != paint_source or paint_layer.get_cell_atlas_coords(cell) != at:
							_set_cell(paint_layer, cell, paint_source, at)
					else:
						bad = true
			if bad:
				_flash("Algunos tiles no se pueden usar (son parte de una animación).")
		"erase":
			var l := _layer_from(_erase_layer_opt)
			if l:
				for cell in _brush_cells(c):
					_set_cell(l, cell, -1, Vector2i.ZERO)
		"terrain":
			_paint_terrain(c, erase)


func _brush_cells(c: Vector2i) -> Array:
	var out: Array = []
	var off := (brush_size - 1) / 2
	for dy in brush_size:
		for dx in brush_size:
			out.append(c + Vector2i(dx - off, dy - off))
	return out


func _terrain_coords(t: Dictionary) -> Array:
	var out: Array = []
	if t.has("nine"):
		var n: Array = t["nine"]
		for dy in 3:
			for dx in 3:
				out.append(Vector2i(n[0] + dx, n[1] + dy))
		for v in t["inner"].values():
			out.append(Vector2i(v[0], v[1]))
	if t.get("field", false):
		for y in range(1, 5):
			for x in range(1, 5):
				out.append(Vector2i(x, y))
	for v in t.get("center", []):
		out.append(Vector2i(v[0], v[1]))
	return out


func _is_member(layer: TileMapLayer, t: Dictionary, coords_set: Array, cell: Vector2i) -> bool:
	return layer.get_cell_source_id(cell) == int(t["src"]) and layer.get_cell_atlas_coords(cell) in coords_set


func _paint_terrain(c: Vector2i, erase: bool) -> void:
	var t: Dictionary = TERRAINS[terrain_name]
	var layer := _layer_named(t["layer"])
	if layer == null:
		_flash("Este mapa no tiene la capa %s." % t["layer"])
		return
	var cells := _brush_cells(c)
	for cell in cells:
		if erase:
			_set_cell(layer, cell, -1, Vector2i.ZERO)
			if t.get("solid", false):
				var so := _layer_named("Solids")
				if so: _set_cell(so, cell, -1, Vector2i.ZERO)
			continue
		for cl in t.get("clears", []):
			var other := _layer_named(cl)
			if other and other.get_cell_source_id(cell) != -1:
				_set_cell(other, cell, -1, Vector2i.ZERO)
		if t.get("brick", false):
			var at := Vector2i(12 + posmod(cell.x, 3), 15 + posmod(cell.y, 3))
			if _ensure_tile(0, at):
				_set_cell(layer, cell, 0, at)
		elif t.has("single"):
			var s: Array = t["single"]
			if _ensure_tile(int(t["src"]), Vector2i(s[0], s[1])):
				_set_cell(layer, cell, int(t["src"]), Vector2i(s[0], s[1]))
			if t.get("solid", false):
				var so := _layer_named("Solids")
				if so and _ensure_tile(0, Vector2i(14, 8), true):
					_set_cell(so, cell, 0, Vector2i(14, 8))
		else:
			var cen: Array = t["center"][0]
			_ensure_tile(int(t["src"]), Vector2i(cen[0], cen[1]))
			_set_cell(layer, cell, int(t["src"]), Vector2i(cen[0], cen[1]))
	if t.has("nine") or t.get("field", false):
		var coords_set := _terrain_coords(t)
		var todo := {}
		for cell in cells:
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					todo[cell + Vector2i(dx, dy)] = true
		for cell in todo:
			if _is_member(layer, t, coords_set, cell):
				_autotile_cell(layer, t, coords_set, cell)


func _autotile_cell(layer: TileMapLayer, t: Dictionary, coords_set: Array, cell: Vector2i) -> void:
	var m := func(dx: int, dy: int) -> bool: return _is_member(layer, t, coords_set, cell + Vector2i(dx, dy))
	var n: bool = m.call(0, -1); var s: bool = m.call(0, 1); var w: bool = m.call(-1, 0); var e: bool = m.call(1, 0)
	var k := "c"
	if not n and not w: k = "tl"
	elif not n and not e: k = "tr"
	elif not s and not w: k = "bl"
	elif not s and not e: k = "br"
	elif not n: k = "t"
	elif not s: k = "b"
	elif not w: k = "l"
	elif not e: k = "r"
	elif t.has("inner"):
		if not m.call(1, -1): k = "ne"
		elif not m.call(-1, -1): k = "nw"
		elif not m.call(1, 1): k = "se"
		elif not m.call(-1, 1): k = "sw"
	var at: Vector2i
	if t.get("field", false):
		var map := {"tl": Vector2i(1, 1), "t": Vector2i(2, 1), "tr": Vector2i(4, 1), "l": Vector2i(1, 2), "r": Vector2i(4, 2),
			"bl": Vector2i(1, 4), "b": Vector2i(2, 4), "br": Vector2i(4, 4)}
		if map.has(k):
			at = map[k]
		else:
			var cc: Array = t["center"][posmod(cell.x * 7 + cell.y * 3, t["center"].size())]
			at = Vector2i(cc[0], cc[1])
	elif k in ["ne", "nw", "se", "sw"]:
		var v: Array = t["inner"][k]
		at = Vector2i(v[0], v[1])
	else:
		var n9: Array = t["nine"]
		var off := {"tl": Vector2i(0, 0), "t": Vector2i(1, 0), "tr": Vector2i(2, 0), "l": Vector2i(0, 1), "c": Vector2i(1, 1),
			"r": Vector2i(2, 1), "bl": Vector2i(0, 2), "b": Vector2i(1, 2), "br": Vector2i(2, 2)}
		at = Vector2i(n9[0], n9[1]) + off[k]
		if k == "c" and t.has("center"):
			var cc2: Array = t["center"][0]
			at = Vector2i(cc2[0], cc2[1])
	if layer.get_cell_atlas_coords(cell) != at and _ensure_tile(int(t["src"]), at):
		_set_cell(layer, cell, int(t["src"]), at)


# =============================================================================
# Undo
# =============================================================================

func _push_undo(entry: Dictionary) -> void:
	_undo.append(entry)
	if _undo.size() > 200:
		_undo.pop_front()
	_dirty = true
	_update_inspector()


func _undo_last() -> void:
	_end_stroke()
	if _undo.is_empty():
		_flash("Nada que deshacer.")
		return
	var e: Dictionary = _undo.pop_back()
	match e["type"]:
		"move":
			(e["node"] as Node2D).global_position = e["from"]
		"add":
			var n: Node = e["node"]
			if n.get_parent():
				n.get_parent().remove_child(n)
			if selected == n:
				selected = null
		"delete":
			var p: Node = e["parent"]
			p.add_child(e["node"])
			p.move_child(e["node"], mini(e["index"], p.get_child_count() - 1))
			_set_owner_rec(e["node"])
		"flip":
			selected = e["node"]
			_flip_selected()
			_undo.pop_back()
		"tiles":
			for rec in e["cells"]:
				var l: TileMapLayer = rec[0]
				if rec[2] == -1:
					l.erase_cell(rec[1])
				else:
					l.set_cell(rec[1], rec[2], rec[3], rec[4])
	_update_inspector()
	_flash("Deshecho.")


# =============================================================================
# Save / test / exit
# =============================================================================

func _busy(text: String) -> void:
	_busy_label.text = text
	_busy_label.visible = text != ""
	_busy_label.position = get_viewport().get_visible_rect().size / 2.0 - Vector2(220, 20)


func _save() -> void:
	_end_stroke()
	var path := world.scene_file_path
	if path == "":
		_flash("No se puede guardar: la escena no tiene archivo.")
		return
	_busy("Guardando y recalculando navegación...")
	await get_tree().process_frame
	await get_tree().process_frame
	var hud := world.get_node_or_null("HUD") as CanvasLayer
	if hud:
		hud.visible = true
	# tile sets may have new tiles
	var saved_ts := {}
	for l in _layers:
		if l.tile_set and l.tile_set.resource_path != "" and not saved_ts.has(l.tile_set.resource_path):
			ResourceSaver.save(l.tile_set, l.tile_set.resource_path)
			saved_ts[l.tile_set.resource_path] = true
	var ps := PackedScene.new()
	var err := ps.pack(world)
	if err == OK:
		err = ResourceSaver.save(ps, path)
	if hud:
		hud.visible = false
	if err != OK:
		_busy("")
		_flash("Error al guardar (%d). ¿Se ejecuta desde la carpeta del proyecto?" % err)
		return
	if world.has_method("rebuild_walkmask"):
		await get_tree().physics_frame
		var img: Image = world.rebuild_walkmask()
		var wp: String = world.get("walkmask_path") if "walkmask_path" in world else "res://resources/world/walkmask.png"
		ResourceSaver.save(img, wp.get_basename() + ".res")
	_busy("")
	_dirty = false
	_flash("Guardado en %s" % path)


func _start_test() -> void:
	_end_stroke()
	_test_positions.clear()
	for n in _selectables():
		if n.scene_file_path.ends_with("walker.tscn") or n.scene_file_path.ends_with("wild_animal.tscn"):
			_test_positions[n] = n.global_position
	var player := world.get_node_or_null("Entities/Player") as Node2D
	if player == null:
		_flash("Este mapa no tiene jugador.")
		return
	_test_positions[player] = player.global_position
	var p := cam.get_screen_center_position()
	if world.has_method("is_walkable") and not world.is_walkable(p):
		p = world.find_path(p, p)[0] if not world.find_path(p, p).is_empty() else p
	player.global_position = p
	_testing = true
	Game.editing = false
	Game.input_locked = false
	get_tree().root.content_scale_mode = _prev_scale_mode
	(player.get_node("Camera2D") as Camera2D).make_current()
	(player.get_node("Camera2D") as Camera2D).reset_smoothing()
	_root.visible = false
	canvas.visible = false
	_test_bar.visible = true
	var hud := world.get_node_or_null("HUD") as CanvasLayer
	if hud:
		hud.visible = true


func _stop_test() -> void:
	if not _testing:
		return
	_testing = false
	Game.editing = true
	Game.input_locked = true
	for n in _test_positions:
		if is_instance_valid(n):
			n.global_position = _test_positions[n]
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	cam.make_current()
	_root.visible = true
	canvas.visible = true
	_test_bar.visible = false
	var hud := world.get_node_or_null("HUD") as CanvasLayer
	if hud:
		hud.visible = false


func _exit() -> void:
	if _dirty:
		var dlg := ConfirmationDialog.new()
		dlg.dialog_text = "Hay cambios sin guardar. ¿Salir de todos modos?"
		dlg.ok_button_text = "Salir sin guardar"
		dlg.cancel_button_text = "Volver"
		dlg.confirmed.connect(_do_exit)
		add_child(dlg)
		dlg.popup_centered(Vector2i(420, 140))
		return
	_do_exit()


func _do_exit() -> void:
	get_tree().root.content_scale_mode = _prev_scale_mode
	Game.stop_editing()
	Game.go_to_main_menu()
	queue_free()
