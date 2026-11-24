extends CanvasLayer
## Dungeon panels: at a portal (name, lore, level, the set it drops, your record, Normal / Heroic),
## and the victory panel when its chest is opened (rank, time and everything you got).

const PAPER := Color(0.93, 0.87, 0.72)
const INK := Color(0.25, 0.16, 0.1)
const INK_SOFT := Color(0.47, 0.33, 0.22)
const GOLD := Color(0.62, 0.42, 0.08)
const BAD := Color(0.62, 0.14, 0.1)
const RANK_COLORS := {"S": Color(1, 0.75, 0.1), "A": Color(0.3, 0.75, 0.35), "B": Color(0.35, 0.55, 0.9), "C": Color(0.6, 0.55, 0.5)}

var _root: Control
var _body: VBoxContainer
var _id := ""


func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var board := PanelContainer.new()
	board.add_theme_stylebox_override("panel", _box(Color(0.22, 0.16, 0.28), Color(0.1, 0.06, 0.14), 3, 7))
	board.custom_minimum_size = Vector2(320, 210)
	board.size = board.custom_minimum_size
	_root.add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 4)
	board.add_child(_body)
	_root.hide()
	Game.dungeon_menu_requested.connect(open)
	Game.dungeon_victory_panel.connect(victory)


func _unhandled_input(event: InputEvent) -> void:
	if _root.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()


func _box(bg: Color, border: Color, width := 1, margin := 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.content_margin_left = margin + 1; s.content_margin_right = margin + 1
	s.content_margin_top = margin; s.content_margin_bottom = margin
	s.anti_aliasing = false
	return s


func _ink(text: String, size := 8, color := INK, wrap := true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_constant_override("line_spacing", -2)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(290, 0)
	return l


func _title(text: String, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_outline_color", Color(0.06, 0.03, 0.08))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _show() -> void:
	Game.sfx("ui_open", -2.0, 0.0)
	Game.menu_open = true
	get_tree().paused = true
	_root.show()


func close() -> void:
	_root.hide()
	get_tree().paused = false
	Game.menu_open = false


func _clear() -> void:
	for c in _body.get_children():
		c.queue_free()


func open(id: String) -> void:
	_id = id
	_clear()
	var d := Game.dungeon_def(id)
	_body.add_child(_title(d["name"], d.get("color", Color(1, 0.86, 0.5)).lightened(0.2)))
	var paper := PanelContainer.new()
	paper.add_theme_stylebox_override("panel", _box(PAPER, Color(0.55, 0.42, 0.28), 1, 5))
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(paper)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	paper.add_child(v)
	var lore := _ink(d["lore"], 7, INK_SOFT)
	lore.custom_minimum_size = Vector2(290, 0)
	v.add_child(lore)
	var lv := int(d["level"])
	if d.has("tower"):
		v.add_child(_ink("Empiezas en el piso %d (nivel %d). Cada piso: %d oleadas; un jefe cada 5 pisos; un punto de control cada 10." % [
			Game.tower_checkpoint(), lv, GameData.TOWER_WAVES], 7, INK if Game.level >= lv - 6 else BAD))
		v.add_child(_ink("Tu récord: piso %d" % Game.tower_best() if Game.tower_best() > 0 else "Nadie ha vuelto para contar qué hay arriba.", 7, GOLD))
		v.add_child(_ink("Recompensas: oro, experiencia y equipo cada vez mejores. La probabilidad de piezas de Sello crece con cada piso.", 6, INK_SOFT))
	else:
		v.add_child(_ink("Nivel recomendado: %d   ·   Heroico: %d   ·   %d oleadas y un jefe: %s" % [lv, lv + 8, GameData.DUNGEON_WAVES, d["boss"]], 7,
			INK if Game.level >= lv - 3 else BAD))
	var sdef: Dictionary = GameData.SETS[d["set"]]
	if d.has("tower"):
		_tower_buttons()
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	v.add_child(row)
	row.add_child(_ink("Recompensa: pieza del set %s  " % sdef["name"], 7, GOLD, false))
	for pc in sdef["pieces"]:
		var t := TextureRect.new()
		t.texture = load(Game.eq_icon(pc))
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.custom_minimum_size = Vector2(16, 16)
		t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(t)
	v.add_child(_ink("Set (2): %s   ·   Set (4): %s" % [sdef["2_text"], sdef["4_text"]], 6, INK_SOFT))
	v.add_child(_ink("Además: equipo con buenas probabilidades de rareza, y quizá una pieza de Sello (SOS, SOM o SOSUN).", 6, INK_SOFT))
	var rec: Dictionary = Game.dungeon_records.get(_id, {})
	if not rec.is_empty():
		var tt := int(rec.get("time", 0))
		v.add_child(_ink("Tu mejor marca: rango %s · %d:%02d · %d victorias%s" % [rec.get("best", "C"), tt / 60, tt % 60, int(rec.get("clears", 0)),
			" · heroico superado" if bool(rec.get("heroic", false)) else ""], 7, RANK_COLORS.get(String(rec.get("best", "C")), INK)))
	var why := Game.dungeon_block_reason(_id, false)
	if why != "":
		v.add_child(_ink(why, 8, BAD))
	var bb := HBoxContainer.new()
	bb.alignment = BoxContainer.ALIGNMENT_CENTER
	bb.add_theme_constant_override("separation", 6)
	_body.add_child(bb)
	for pair in [["Entrar (Normal)", false], ["Entrar (Heroico)", true]]:
		var b := Button.new()
		b.text = pair[0]
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 8)
		var heroic: bool = pair[1]
		var reason := Game.dungeon_block_reason(_id, heroic)
		b.disabled = reason != ""
		b.tooltip_text = reason
		b.pressed.connect(func():
			close()
			Game.enter_dungeon(_id, heroic))
		bb.add_child(b)
	var c := Button.new()
	c.text = "Cerrar"
	c.focus_mode = Control.FOCUS_NONE
	c.add_theme_font_size_override("font_size", 8)
	c.pressed.connect(close)
	bb.add_child(c)
	_show()


func _tower_buttons() -> void:
	var why := Game.dungeon_block_reason(_id, false)
	if why != "":
		_body.add_child(_ink(why, 8, BAD))
	var bb := HBoxContainer.new()
	bb.alignment = BoxContainer.ALIGNMENT_CENTER
	bb.add_theme_constant_override("separation", 6)
	_body.add_child(bb)
	var b := Button.new()
	b.text = "Entrar (piso %d)" % Game.tower_checkpoint()
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 8)
	b.disabled = why != ""
	b.pressed.connect(func():
		close()
		Game.enter_dungeon(_id, false))
	bb.add_child(b)
	var c := Button.new()
	c.text = "Cerrar"
	c.focus_mode = Control.FOCUS_NONE
	c.add_theme_font_size_override("font_size", 8)
	c.pressed.connect(close)
	bb.add_child(c)
	_show()


func victory(rank: String, secs: float, got: Array) -> void:
	_clear()
	var in_tower := Game.current_dungeon == GameData.TOWER_ID
	_body.add_child(_title("¡Piso %d superado!" % Game.tower_floor if in_tower else "¡Mazmorra superada!", Color(1, 0.86, 0.5)))
	var big := Label.new()
	big.text = "Rango %s" % rank
	big.add_theme_font_size_override("font_size", 22)
	big.add_theme_color_override("font_color", RANK_COLORS.get(rank, Color.WHITE))
	big.add_theme_constant_override("outline_size", 6)
	big.add_theme_color_override("font_outline_color", Color(0.06, 0.03, 0.08))
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_child(big)
	var paper := PanelContainer.new()
	paper.add_theme_stylebox_override("panel", _box(PAPER, Color(0.55, 0.42, 0.28), 1, 5))
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(paper)
	var v := VBoxContainer.new()
	paper.add_child(v)
	var tt := int(secs)
	v.add_child(_ink("Tiempo: %d:%02d   ·   S: menos de 2:30 y 15 golpes recibidos como máximo" % [tt / 60, tt % 60], 7, INK_SOFT))
	v.add_child(_ink("Botín:", 8))
	for g in got:
		v.add_child(_ink("· " + String(g), 7))
	var bb := HBoxContainer.new()
	bb.alignment = BoxContainer.ALIGNMENT_CENTER
	_body.add_child(bb)
	if in_tower:
		var up := Button.new()
		up.text = "Subir al piso %d" % (Game.tower_floor + 1)
		up.focus_mode = Control.FOCUS_NONE
		up.add_theme_font_size_override("font_size", 8)
		up.pressed.connect(func():
			close()
			Game.tower_next())
		bb.add_child(up)
	var ok := Button.new()
	ok.text = "Volver al portal"
	ok.focus_mode = Control.FOCUS_NONE
	ok.add_theme_font_size_override("font_size", 8)
	ok.pressed.connect(func():
		close()
		Game.leave_dungeon())
	bb.add_child(ok)
	var stay := Button.new()
	stay.text = "Quedarme"
	stay.focus_mode = Control.FOCUS_NONE
	stay.add_theme_font_size_override("font_size", 8)
	stay.pressed.connect(close)
	bb.add_child(stay)
	_show()
