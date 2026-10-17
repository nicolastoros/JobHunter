extends CanvasLayer
## Kara's forge: improve the equipment you are wearing (+1 ... +10) with gold and the materials
## that monsters drop.

const PAPER := Color(0.93, 0.87, 0.72)
const INK := Color(0.25, 0.16, 0.1)
const INK_SOFT := Color(0.47, 0.33, 0.22)
const GOOD := Color(0.13, 0.42, 0.14)
const BAD := Color(0.62, 0.14, 0.1)
const STAT_NAMES := {"atk": "Ataque", "def": "Defensa", "hp": "Vida", "mana": "Maná"}

var _root: Control
var _list: VBoxContainer
var _slot := "weapon"
var _icon: TextureRect
var _name: Label
var _stats: Label
var _cost_box: VBoxContainer
var _upgrade: Button
var _note: Label


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.hide()
	Game.forge_requested.connect(open)
	Game.stats_changed.connect(func(): if _root.visible: _refresh())


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


func _tex(spec, px: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Game.icon_texture(spec)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(px, px)
	t.size = Vector2(px, px)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


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
	board.position = Vector2(30, 18)
	board.size = Vector2(420, 234)
	board.custom_minimum_size = board.size
	_root.add_child(board)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	board.add_child(vb)
	var head := Label.new()
	head.text = "FORJA DE KARA — Mejora de equipo"
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
	left.add_theme_stylebox_override("panel", _box(PAPER, Color(0.55, 0.42, 0.28)))
	left.custom_minimum_size = Vector2(150, 0)
	hb.add_child(left)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 2)
	left.add_child(lv)
	lv.add_child(_ink("Equipo puesto", 9))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	lv.add_child(_list)
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", _box(PAPER, Color(0.55, 0.42, 0.28)))
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 3)
	right.add_child(rv)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	rv.add_child(top)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _box(Color(0.8, 0.66, 0.47), Color(0.6, 0.45, 0.3), 1, 3))
	top.add_child(frame)
	_icon = _tex([0, 0], 32)
	frame.add_child(_icon)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 1)
	top.add_child(tv)
	_name = _ink("", 10)
	tv.add_child(_name)
	_stats = _ink("", 8, INK_SOFT)
	tv.add_child(_stats)
	rv.add_child(_ink("Materiales para la mejora:", 8))
	_cost_box = VBoxContainer.new()
	_cost_box.add_theme_constant_override("separation", 1)
	rv.add_child(_cost_box)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(grow)
	_note = _ink("", 7, INK_SOFT)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.custom_minimum_size = Vector2(150, 0)
	rv.add_child(_note)
	var bb := HBoxContainer.new()
	bb.alignment = BoxContainer.ALIGNMENT_END
	bb.add_theme_constant_override("separation", 4)
	rv.add_child(bb)
	_upgrade = Button.new()
	_upgrade.text = "Mejorar"
	_upgrade.focus_mode = Control.FOCUS_NONE
	_upgrade.pressed.connect(func():
		Game.forge_upgrade(_slot)
		_refresh())
	bb.add_child(_upgrade)
	var close := Button.new()
	close.text = "Cerrar"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(close_forge)
	bb.add_child(close)


func open() -> void:
	Game.input_locked = true
	Game.menu_open = true
	get_tree().paused = true
	if not Game.equipped.has(_slot):
		_slot = Game.equipped.keys()[0] if Game.equipped.size() > 0 else "weapon"
	_root.show()
	_refresh()


func close_forge() -> void:
	_root.hide()
	get_tree().paused = false
	Game.menu_open = false
	await get_tree().process_frame
	Game.input_locked = false


func _unhandled_input(event: InputEvent) -> void:
	if _root.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close_forge()


static func _stat_line(e: Dictionary) -> String:
	var parts: Array[String] = []
	for k in ["atk", "def", "hp", "mana"]:
		if e.has(k) and int(e[k]) != 0:
			parts.append("%s %+d" % [STAT_NAMES[k], int(e[k])])
	return "   ".join(parts)


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	for slot in GameData.SLOTS:
		var entry: String = Game.equipped.get(slot, "")
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 25)
		var sel: bool = slot == _slot
		var st := _box(Color(0.96, 0.9, 0.76) if sel else Color(0.88, 0.8, 0.63), Color(0.95, 0.72, 0.2) if sel else Color(0.65, 0.5, 0.34), 2 if sel else 1, 0)
		for k in ["normal", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(k, st)
		b.add_theme_stylebox_override("hover", _box(Color(0.95, 0.88, 0.72), st.border_color, st.border_width_left, 0))
		b.disabled = entry == ""
		if entry != "":
			var ic := _tex(Game.eq_icon(entry), 20)
			ic.position = Vector2(3, 2)
			b.add_child(ic)
		var nm := _ink(Game.eq(entry)["name"] if entry != "" else "%s: —" % GameData.SLOT_NAMES[slot], 7, INK if entry != "" else INK_SOFT)
		nm.position = Vector2(27, 6)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(nm)
		b.pressed.connect(func():
			_slot = slot
			_refresh())
		_list.add_child(b)
	for c in _cost_box.get_children():
		c.queue_free()
	var entry: String = Game.equipped.get(_slot, "")
	if entry == "":
		_icon.visible = false
		_name.text = "Nada que mejorar"
		_stats.text = ""
		_note.text = "Equípate una pieza para que Kara pueda trabajarla."
		_upgrade.disabled = true
		return
	_icon.visible = true
	_icon.texture = load(Game.eq_icon(entry))
	var e := Game.eq(entry)
	var plus := Game.eq_plus(entry)
	if plus >= GameData.MAX_PLUS:
		_name.text = e["name"]
		_stats.text = _stat_line(e)
		_note.text = "Esta pieza ya no admite más mejoras. Es lo mejor que sé hacer."
		_upgrade.disabled = true
		_upgrade.text = "Máximo"
		return
	var nxt := Game.eq("%s+%d" % [Game.eq_base(entry), plus + 1])
	_name.text = "%s  →  +%d" % [e["name"], plus + 1]
	_stats.text = "Ahora: %s\nDespués: %s" % [_stat_line(e), _stat_line(nxt)]
	var cost := Game.forge_cost(entry)
	for id in cost["items"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		row.add_child(_tex(GameData.ITEMS[id]["icon"], 16))
		var have := Game.item_count(id)
		var need := int(cost["items"][id])
		row.add_child(_ink("%s   %d / %d" % [GameData.ITEMS[id]["name"], have, need], 8, GOOD if have >= need else BAD))
		_cost_box.add_child(row)
	var grow := HBoxContainer.new()
	grow.add_theme_constant_override("separation", 4)
	grow.add_child(_tex([16, 144], 16))
	grow.add_child(_ink("Oro   %d / %d" % [Game.gold, cost["gold"]], 8, GOOD if Game.gold >= int(cost["gold"]) else BAD))
	_cost_box.add_child(grow)
	var why := Game.forge_block_reason(_slot)
	_note.text = "Kara: \"Tráeme lo que sueltan las bestias de la llanura y te dejo esa pieza como nueva.\"" if why == "" else why
	_upgrade.disabled = why != ""
	_upgrade.text = "Mejorar a +%d" % (plus + 1)
