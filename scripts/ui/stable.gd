extends CanvasLayer
## Stable at the Eastern Farms: buy the riding deer and companions, and choose who travels with you.

const PAPER := Color(0.93, 0.87, 0.72)
const INK := Color(0.25, 0.16, 0.1)
const INK_SOFT := Color(0.47, 0.33, 0.22)
const GOLD := Color(0.62, 0.42, 0.08)
const BAD := Color(0.62, 0.14, 0.1)

var _root: Control
var _list: VBoxContainer
var _gold: Label
var _sel := "mount"
var _pic: TextureRect
var _title: Label
var _info: Label
var _perk: Label
var _desc: Label
var _action: Button

func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.hide()
	Game.stable_requested.connect(open)


func _box(bg: Color, border: Color, width := 1, margin := 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.content_margin_left = margin + 1; s.content_margin_right = margin + 1
	s.content_margin_top = margin; s.content_margin_bottom = margin
	s.anti_aliasing = false
	return s


func _ink(text: String, size := 8, color := INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_constant_override("line_spacing", -3)
	return l


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.02, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var board := PanelContainer.new()
	board.add_theme_stylebox_override("panel", _box(Color(0.36, 0.23, 0.13), Color(0.18, 0.1, 0.06), 3, 6))
	board.size = Vector2(430, 236)
	board.custom_minimum_size = board.size
	_root.add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	board.add_child(vb)
	var head := Label.new()
	head.text = "ESTABLO DE LAS GRANJAS DEL ESTE"
	head.add_theme_font_size_override("font_size", 10)
	head.add_theme_color_override("font_color", Color(1, 0.86, 0.5))
	head.add_theme_constant_override("outline_size", 4)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(head)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 5)
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", _box(PAPER, Color(0.55, 0.42, 0.28), 1, 3))
	left.custom_minimum_size = Vector2(176, 0)
	hb.add_child(left)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", _box(PAPER, Color(0.55, 0.42, 0.28), 1, 5))
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 3)
	right.add_child(rv)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	rv.add_child(top)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _box(Color(0.42, 0.55, 0.32), Color(0.3, 0.38, 0.22), 1, 0))
	frame.custom_minimum_size = Vector2(64, 64)
	top.add_child(frame)
	_pic = TextureRect.new()
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(_pic)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tv)
	_title = _ink("", 10)
	tv.add_child(_title)
	_info = _ink("", 8, INK_SOFT)
	tv.add_child(_info)
	_perk = _ink("", 8, Color(0.13, 0.42, 0.14))
	tv.add_child(_perk)
	_desc = _ink("", 8, INK_SOFT)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size = Vector2(200, 0)
	rv.add_child(_desc)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(grow)
	_action = Button.new()
	_action.focus_mode = Control.FOCUS_NONE
	_action.add_theme_font_size_override("font_size", 8)
	_action.pressed.connect(_on_action)
	rv.add_child(_action)
	var foot := HBoxContainer.new()
	vb.add_child(foot)
	_gold = Label.new()
	_gold.add_theme_font_size_override("font_size", 8)
	_gold.add_theme_color_override("font_color", Color(1, 0.86, 0.45))
	_gold.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(_gold)
	var close := Button.new()
	close.text = "Cerrar"
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 8)
	close.pressed.connect(close_stable)
	foot.add_child(close)


func open() -> void:
	Game.input_locked = true
	Game.menu_open = true
	get_tree().paused = true
	_root.show()
	_refresh()


func close_stable() -> void:
	_root.hide()
	get_tree().paused = false
	Game.menu_open = false
	await get_tree().process_frame
	Game.input_locked = false


func _unhandled_input(event: InputEvent) -> void:
	if _root.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close_stable()


func _portrait(frames_path: String) -> Texture2D:
	var sf := load(frames_path) as SpriteFrames
	return sf.get_frame_texture(&"idle_down", 0) if sf and sf.has_animation(&"idle_down") else null


## Entries of the stable: the mount first, then every companion.
func _entries() -> Array:
	var out := ["mount"]
	out.append_array(GameData.PETS.keys())
	return out


func _def(id: String) -> Dictionary:
	return GameData.MOUNT if id == "mount" else GameData.PETS[id]


func _owned(id: String) -> bool:
	return Game.has_mount if id == "mount" else id in Game.pets


func _status(id: String) -> String:
	if id == "mount":
		return "Tuyo · tecla H" if Game.has_mount else "%d oro" % int(GameData.MOUNT["price"])
	if Game.active_pet == id:
		return "Contigo"
	if id in Game.pets:
		return "En el establo"
	return "%d oro · %s" % [int(GameData.PETS[id]["price"]), GameData.PETS[id]["rank"]]


func _row(id: String) -> Button:
	var d := _def(id)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 24)
	var sel := id == _sel
	var st := _box(Color(0.97, 0.92, 0.75) if sel else Color(0.88, 0.8, 0.63), Color(0.95, 0.72, 0.2) if sel else Color(0.65, 0.5, 0.34), 2 if sel else 1, 0)
	for k in ["normal", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(k, st)
	b.add_theme_stylebox_override("hover", _box(Color(0.95, 0.88, 0.72), st.border_color, st.border_width_left, 0))
	var ic := TextureRect.new()
	ic.texture = _portrait(d["frames"])
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.position = Vector2(1, 0)
	ic.size = Vector2(24, 24)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ic)
	var nm := _ink(d["name"], 8, INK)
	nm.position = Vector2(27, 1)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(nm)
	var stl := _ink(_status(id), 7, GOLD if _owned(id) else INK_SOFT)
	stl.position = Vector2(27, 12)
	stl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(stl)
	b.pressed.connect(func():
		_sel = id
		_refresh())
	return b


func _on_action() -> void:
	if _sel == "mount":
		if not Game.has_mount:
			Game.buy_mount()
	elif _sel in Game.pets:
		Game.set_active_pet("" if Game.active_pet == _sel else _sel)
	else:
		Game.buy_pet(_sel)
	_refresh()


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	for id in _entries():
		_list.add_child(_row(id))
	_gold.text = "Tu oro: %d      Licencia actual: rango %s" % [Game.gold, Game.guild_rank()[1]]
	var d := _def(_sel)
	_pic.texture = _portrait(d["frames"])
	_title.text = d["name"]
	var owned := _owned(_sel)
	if owned:
		_info.text = "Ya es tuyo." if _sel == "mount" else ("Te acompaña ahora." if Game.active_pet == _sel else "Descansa en el establo.")
		_info.add_theme_color_override("font_color", GOLD)
	else:
		_info.text = "Precio: %d de oro · Licencia rango %s" % [int(d["price"]), d["rank"]]
		var ok := Game.gold >= int(d["price"]) and Game.rank_at_least(d["rank"])
		_info.add_theme_color_override("font_color", INK_SOFT if ok else BAD)
	_perk.text = ("Montura: corres %d %% más rápido" % int(round((float(d["speed"]) - 1.0) * 100.0))) if _sel == "mount" else "Bono mientras te acompaña: %s" % d.get("perk", "")
	_desc.text = d["desc"]
	if _sel == "mount":
		_action.text = "Tuyo · tecla H para montar" if owned else "Comprar"
		var why := "" if owned else Game.stable_block_reason(int(d["price"]), d["rank"])
		_action.disabled = owned or why != ""
		if why != "":
			_action.text = why
	elif owned:
		_action.text = "Dejar en el establo" if Game.active_pet == _sel else "Llevar conmigo"
		_action.disabled = false
	else:
		var why := Game.stable_block_reason(int(d["price"]), d["rank"])
		_action.text = "Comprar" if why == "" else why
		_action.disabled = why != ""
