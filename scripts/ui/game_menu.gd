extends CanvasLayer
## Hero menu with four tabs: character & equipment (C), inventory (I / Tab), skills (K) and
## talents (L): the three main attributes and the talent tree. Pauses the game while open.

const TABS := ["character", "inventory", "skills", "talents"]
const TAB_TITLES := {"character": "Personaje", "inventory": "Inventario", "skills": "Habilidades", "talents": "Talentos"}
const TAB_KEYS := {"character": "C", "inventory": "I", "skills": "K", "talents": "L"}
const PAPER := Color(0.93, 0.87, 0.72)
const PAPER_DARK := Color(0.86, 0.78, 0.6)
const WOOD := Color(0.36, 0.23, 0.13)
const INK := Color(0.25, 0.16, 0.1)
const INK_SOFT := Color(0.47, 0.33, 0.22)
const GOLD := Color(0.62, 0.42, 0.08)
const SLOTS := 24
const STAT_NAMES := {"atk": "Ataque", "def": "Defensa", "hp": "Vida", "mana": "Maná", "speed": "Velocidad",
	"crit": "Crítico", "crit_dmg": "Daño crítico", "lifesteal": "Robo de vida", "skill_dmg": "Habilidades"}

var _root: Control
var _tab_buttons := {}
var _pages := {}
var _tab := "character"
# character
var _equip_box: VBoxContainer
var _bag_grid: GridContainer
var _bag_sel := -1
var _eq_icon: TextureRect
var _eq_name: Label
var _eq_desc: Label
var _eq_btn: Button
var _portrait: TextureRect
var _look_label: Label
var _stat_grid: GridContainer
var _next_look: Label
# inventory
var _grid: GridContainer
var _sel_item := ""
var _item_icon: TextureRect
var _item_name: Label
var _item_kind: Label
var _item_desc: Label
var _use_btn: Button
var _inv_footer: Label
# skills
var _skill_header: Label
var _skill_list: VBoxContainer
var _skill_sel := "giro"
var _sk_icon: TextureRect
var _sk_name: Label
var _sk_pips: HBoxContainer
var _sk_desc: Label
var _sk_next: Label
var _sk_meta: Label
var _sk_btn: Button
# talents
var _tp_label: Label
var _main_labels := {}
var _main_buttons := {}
var _respec: Button
var _tree: Control
var _tl_icon: TextureRect
var _tl_name: Label
var _tl_branch: Label
var _tl_desc: Label
var _tl_state: Label
var _tl_btn: Button


func _ready() -> void:
	layer = 16
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.hide()
	Game.stats_changed.connect(func(): if _root.visible: _refresh())


# =============================================================================
# Helpers
# =============================================================================

func _box(bg: Color, border: Color, width := 1, margin := 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.content_margin_left = margin + 1; s.content_margin_right = margin + 1
	s.content_margin_top = margin; s.content_margin_bottom = margin
	s.anti_aliasing = false
	return s


func _paper(bg := PAPER) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(bg, Color(0.55, 0.42, 0.28)))
	return p


func _ink(text: String, size := 8, color := INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_constant_override("line_spacing", -3)
	return l


func _header(text: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.add_child(_ink(text, 9))
	var line := ColorRect.new()
	line.color = Color(0.62, 0.48, 0.3)
	line.custom_minimum_size = Vector2(0, 1)
	v.add_child(line)
	return v


func _icon(spec, px := 16) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Game.icon_texture(spec)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(px, px)
	t.size = Vector2(px, px)
	var pixel: bool = spec is Array or (px % 16 == 0 and not String(spec).contains("/skills/"))
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel else CanvasItem.TEXTURE_FILTER_LINEAR
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _button(text: String, cb: Callable, size := 8) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(cb)
	return b


## A square slot; `selected` draws a gold border.
func _slot(size: float, selected := false, empty := false) -> Button:
	var slot := Button.new()
	slot.custom_minimum_size = Vector2(size, size)
	slot.focus_mode = Control.FOCUS_NONE
	var st := _box(Color(0.8, 0.66, 0.47) if not empty else Color(0.8, 0.7, 0.54, 0.75),
		Color(0.95, 0.72, 0.2) if selected else Color(0.6, 0.45, 0.3), 2 if selected else 1, 0)
	var hov := st.duplicate() as StyleBoxFlat
	hov.bg_color = Color(0.87, 0.75, 0.55)
	for k in ["normal", "pressed", "focus", "disabled"]:
		slot.add_theme_stylebox_override(k, st)
	slot.add_theme_stylebox_override("hover", hov)
	slot.disabled = empty
	return slot


func _place_icon(parent: Control, spec, px: int, slot_size: float) -> TextureRect:
	var ic := _icon(spec, px)
	ic.position = Vector2((slot_size - px) / 2.0, (slot_size - px) / 2.0)
	parent.add_child(ic)
	return ic


func _scroll(child: Control) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(child)
	return sc


func _pips(parent: HBoxContainer, rank: int, mx: int, color := Color(0.85, 0.6, 0.15)) -> void:
	for c in parent.get_children():
		c.queue_free()
	for i in mx:
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(6, 4)
		r.color = color if i < rank else Color(0.55, 0.45, 0.35, 0.45)
		parent.add_child(r)


func _stat_row(grid: GridContainer, label: String, value: String, highlight := false) -> void:
	grid.add_child(_ink(label, 7, INK_SOFT))
	var v := _ink(value, 7, GOLD if highlight else INK)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(v)


# =============================================================================
# Build
# =============================================================================

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.02, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var board := PanelContainer.new()
	board.add_theme_stylebox_override("panel", _box(WOOD, Color(0.18, 0.1, 0.06), 3, 5))
	board.position = Vector2(4, 3)
	board.size = Vector2(472, 264)
	board.custom_minimum_size = board.size
	_root.add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	board.add_child(vb)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 2)
	vb.add_child(tabs)
	for t in TABS:
		var b := Button.new()
		b.text = "%s  [%s]" % [TAB_TITLES[t], TAB_KEYS[t]]
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 8)
		b.custom_minimum_size = Vector2(92, 17)
		b.pressed.connect(show_tab.bind(t))
		tabs.add_child(b)
		_tab_buttons[t] = b
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(spacer)
	var close := _button("Cerrar", close_menu)
	close.text = "Cerrar  [Esc]"
	tabs.add_child(close)
	var page := PanelContainer.new()
	page.add_theme_stylebox_override("panel", _box(PAPER_DARK, Color(0.55, 0.42, 0.28), 1, 4))
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(page)
	var stack := Control.new()
	stack.clip_contents = true
	page.add_child(stack)
	_pages["character"] = _build_character()
	_pages["inventory"] = _build_inventory()
	_pages["skills"] = _build_skills()
	_pages["talents"] = _build_talents()
	for k in _pages:
		var p: Control = _pages[k]
		p.set_anchors_preset(Control.PRESET_FULL_RECT)
		stack.add_child(p)


func _style_tabs() -> void:
	for t in _tab_buttons:
		var b: Button = _tab_buttons[t]
		var active: bool = t == _tab
		var st: StyleBoxFlat
		if active:
			st = _box(PAPER_DARK, Color(0.55, 0.42, 0.28), 1, 2)
			st.border_width_bottom = 0
			st.expand_margin_bottom = 1
		else:
			st = _box(Color(0.25, 0.15, 0.09), Color(0.42, 0.28, 0.16), 1, 2)
		var hov := st.duplicate() as StyleBoxFlat
		if not active:
			hov.bg_color = Color(0.32, 0.2, 0.12)
		for k in ["normal", "pressed", "focus"]:
			b.add_theme_stylebox_override(k, st)
		b.add_theme_stylebox_override("hover", hov)
		var fc := INK if active else Color(0.9, 0.82, 0.66)
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(k, fc)


func _build_character() -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	# worn equipment
	var eq := _paper()
	eq.custom_minimum_size = Vector2(132, 0)
	hb.add_child(eq)
	var ev := VBoxContainer.new()
	ev.add_theme_constant_override("separation", 2)
	eq.add_child(ev)
	ev.add_child(_header("Equipo"))
	_equip_box = VBoxContainer.new()
	_equip_box.add_theme_constant_override("separation", 2)
	ev.add_child(_equip_box)
	var hint := _ink("Clic en una pieza para quitártela.", 6, INK_SOFT)
	ev.add_child(hint)
	# bag + details
	var mid := _paper()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(mid)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 3)
	mid.add_child(mv)
	mv.add_child(_header("Bolsa de equipo"))
	_bag_grid = GridContainer.new()
	_bag_grid.columns = 6
	_bag_grid.add_theme_constant_override("h_separation", 2)
	_bag_grid.add_theme_constant_override("v_separation", 2)
	mv.add_child(_bag_grid)
	var det := HBoxContainer.new()
	det.add_theme_constant_override("separation", 5)
	mv.add_child(det)
	_eq_icon = _icon([0, 0], 32)
	_eq_icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	det.add_child(_eq_icon)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 1)
	dv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	det.add_child(dv)
	_eq_name = _ink("", 8)
	dv.add_child(_eq_name)
	_eq_desc = _ink("", 7)
	_eq_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_eq_desc.custom_minimum_size = Vector2(110, 0)
	dv.add_child(_eq_desc)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mv.add_child(grow)
	_eq_btn = _button("Equipar", _on_equip)
	var bb := HBoxContainer.new()
	bb.alignment = BoxContainer.ALIGNMENT_END
	bb.add_child(_eq_btn)
	mv.add_child(bb)
	# hero & stats
	var st := _paper()
	st.custom_minimum_size = Vector2(136, 0)
	hb.add_child(st)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 1)
	st.add_child(sv)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _box(Color(0.42, 0.55, 0.32), Color(0.3, 0.38, 0.22), 1, 0))
	frame.custom_minimum_size = Vector2(0, 50)
	sv.add_child(frame)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(_portrait)
	_look_label = _ink("", 8)
	_look_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sv.add_child(_look_label)
	_stat_grid = GridContainer.new()
	_stat_grid.columns = 2
	_stat_grid.add_theme_constant_override("v_separation", -2)
	sv.add_child(_stat_grid)
	_next_look = _ink("", 6, INK_SOFT)
	_next_look.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sv.add_child(_next_look)
	return hb


func _build_inventory() -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	var left := _paper()
	hb.add_child(left)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 3)
	left.add_child(lv)
	lv.add_child(_header("Bolsa"))
	_grid = GridContainer.new()
	_grid.columns = 6
	_grid.add_theme_constant_override("h_separation", 3)
	_grid.add_theme_constant_override("v_separation", 3)
	lv.add_child(_grid)
	var right := _paper()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(right)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 3)
	right.add_child(pv)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	pv.add_child(top)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _box(Color(0.8, 0.66, 0.47), Color(0.6, 0.45, 0.3), 1, 3))
	top.add_child(frame)
	_item_icon = _icon([0, 0], 32)
	frame.add_child(_item_icon)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	top.add_child(tv)
	_item_name = _ink("", 10)
	tv.add_child(_item_name)
	_item_kind = _ink("", 7, GOLD)
	tv.add_child(_item_kind)
	_item_desc = _ink("", 8)
	_item_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_item_desc.custom_minimum_size = Vector2(150, 0)
	pv.add_child(_item_desc)
	var ub := HBoxContainer.new()
	_use_btn = _button("Usar", _on_use)
	ub.add_child(_use_btn)
	pv.add_child(ub)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pv.add_child(grow)
	_inv_footer = _ink("", 7, INK_SOFT)
	pv.add_child(_inv_footer)
	return hb


func _build_skills() -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	var left := _paper()
	left.custom_minimum_size = Vector2(196, 0)
	hb.add_child(left)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 2)
	left.add_child(lv)
	_skill_header = _ink("", 8)
	lv.add_child(_skill_header)
	_skill_list = VBoxContainer.new()
	_skill_list.add_theme_constant_override("separation", 2)
	lv.add_child(_skill_list)
	var right := _paper()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 3)
	right.add_child(rv)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	rv.add_child(top)
	_sk_icon = _icon(GameData.SKILLS[0]["icon"], 40)
	top.add_child(_sk_icon)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 2)
	top.add_child(tv)
	_sk_name = _ink("", 11)
	tv.add_child(_sk_name)
	_sk_pips = HBoxContainer.new()
	_sk_pips.add_theme_constant_override("separation", 2)
	tv.add_child(_sk_pips)
	_sk_meta = _ink("", 7, INK_SOFT)
	tv.add_child(_sk_meta)
	_sk_desc = _ink("", 8)
	_sk_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sk_desc.custom_minimum_size = Vector2(150, 0)
	rv.add_child(_sk_desc)
	_sk_next = _ink("", 7, GOLD)
	_sk_next.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rv.add_child(_sk_next)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(grow)
	var bb := HBoxContainer.new()
	bb.alignment = BoxContainer.ALIGNMENT_END
	_sk_btn = _button("Aprender", _on_skill_btn)
	bb.add_child(_sk_btn)
	rv.add_child(bb)
	return hb


func _build_talents() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	# points + the three main attributes
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 4)
	v.add_child(top)
	var pts := _paper(Color(0.36, 0.25, 0.15))
	pts.custom_minimum_size = Vector2(48, 0)
	top.add_child(pts)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", -2)
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	pts.add_child(pv)
	var pl := _ink("Puntos", 7, Color(0.92, 0.84, 0.66))
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(pl)
	_tp_label = _ink("0", 14, Color(1, 0.86, 0.45))
	_tp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(_tp_label)
	var sub := _ink("+3 por nivel", 6, Color(0.85, 0.76, 0.6))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(sub)
	for m in GameData.MAINS:
		var card := _paper()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(card)
		var ch := HBoxContainer.new()
		ch.add_theme_constant_override("separation", 4)
		card.add_child(ch)
		var ic := _icon(m["icon"], 20)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ch.add_child(ic)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", -2)
		cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ch.add_child(cv)
		var name_l := _ink("", 8, (m["color"] as Color).darkened(0.25))
		cv.add_child(name_l)
		var d := _ink(m["desc"], 6, INK_SOFT)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(46, 0)
		cv.add_child(d)
		var bv := VBoxContainer.new()
		bv.add_theme_constant_override("separation", 1)
		bv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ch.add_child(bv)
		var id: String = m["id"]
		var b1 := _button("+1", func(): Game.add_attribute(id, 1), 7)
		var b5 := _button("+5", func(): Game.add_attribute(id, 5), 7)
		b1.custom_minimum_size = Vector2(22, 0)
		b5.custom_minimum_size = Vector2(22, 0)
		bv.add_child(b1)
		bv.add_child(b5)
		_main_labels[id] = name_l
		_main_buttons[id] = [b1, b5]
	# tree + detail
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 4)
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(bottom)
	var tp := _paper(Color(0.9, 0.83, 0.67))
	bottom.add_child(tp)
	_tree = Control.new()
	_tree.set_script(load("res://scripts/ui/talent_tree.gd"))
	tp.add_child(_tree)
	_tree.connect("node_selected", func(_id): _refresh_talent_detail())
	var dp := _paper()
	dp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(dp)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 2)
	dp.add_child(dv)
	var dt := HBoxContainer.new()
	dt.add_theme_constant_override("separation", 4)
	dv.add_child(dt)
	_tl_icon = _icon(GameData.TI + "vigor.png", 28)
	dt.add_child(_tl_icon)
	var dtv := VBoxContainer.new()
	dtv.add_theme_constant_override("separation", -2)
	dt.add_child(dtv)
	_tl_name = _ink("", 9)
	_tl_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tl_name.custom_minimum_size = Vector2(72, 0)
	dtv.add_child(_tl_name)
	_tl_branch = _ink("", 6, INK_SOFT)
	dtv.add_child(_tl_branch)
	_tl_desc = _ink("", 7)
	_tl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tl_desc.custom_minimum_size = Vector2(92, 0)
	dv.add_child(_tl_desc)
	_tl_state = _ink("", 7, GOLD)
	_tl_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tl_state.custom_minimum_size = Vector2(92, 0)
	dv.add_child(_tl_state)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dv.add_child(grow)
	_tl_btn = _button("Aprender", _on_talent_btn)
	dv.add_child(_tl_btn)
	_respec = _button("Reiniciar talentos", func():
		Game.reset_talents()
		_refresh(), 7)
	dv.add_child(_respec)
	return v


# =============================================================================
# Open / close
# =============================================================================

func open(tab: String) -> void:
	Game.menu_open = true
	Game.input_locked = true
	get_tree().paused = true
	_root.show()
	show_tab(tab)


func close_menu() -> void:
	_root.hide()
	get_tree().paused = false
	Game.menu_open = false
	await get_tree().process_frame
	Game.input_locked = false


func show_tab(tab: String) -> void:
	_tab = tab
	for k in _pages:
		_pages[k].visible = k == tab
	_style_tabs()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if Game.editing:
		return
	var wanted := ""
	for t in TABS:
		if event.is_action_pressed(t):
			wanted = t
	if _root.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause") or wanted == _tab:
			get_viewport().set_input_as_handled()
			close_menu()
		elif wanted != "":
			get_viewport().set_input_as_handled()
			show_tab(wanted)
	elif wanted != "" and not Game.input_locked and not get_tree().paused:
		var p := get_tree().get_first_node_in_group("player")
		if p == null or p.call("is_dead"):
			return
		get_viewport().set_input_as_handled()
		open(wanted)


# =============================================================================
# Content
# =============================================================================

func _refresh() -> void:
	match _tab:
		"character": _refresh_character()
		"inventory": _refresh_inventory()
		"skills": _refresh_skills()
		"talents": _refresh_talents()


static func _bonus_text(e: Dictionary) -> String:
	var parts: Array[String] = []
	for k in ["atk", "def", "hp", "mana", "speed", "crit", "crit_dmg", "lifesteal", "skill_dmg"]:
		if e.has(k):
			var v = e[k]
			if k in ["speed", "crit", "crit_dmg", "lifesteal", "skill_dmg"]:
				parts.append("%s %+d %%" % [STAT_NAMES[k], int(round(float(v) * 100))])
			else:
				parts.append("%s %+d" % [STAT_NAMES[k], int(v)])
	return "   ".join(parts)


func _refresh_character() -> void:
	for c in _equip_box.get_children():
		c.queue_free()
	for slot_name in GameData.SLOTS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var worn: String = Game.equipped.get(slot_name, "")
		var b := _slot(24, false, worn == "")
		if worn != "":
			_place_icon(b, Game.eq_icon(worn), 20, 24)
			b.tooltip_text = "Quitar " + Game.eq(worn)["name"]
			b.pressed.connect(func():
				Game.unequip(slot_name)
				_refresh_character())
		row.add_child(b)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", -3)
		col.add_child(_ink(GameData.SLOT_NAMES[slot_name], 6, INK_SOFT))
		col.add_child(_ink(Game.eq(worn)["name"] if worn != "" else "—", 7))
		row.add_child(col)
		_equip_box.add_child(row)
	# bag
	for c in _bag_grid.get_children():
		c.queue_free()
	if _bag_sel >= Game.bag.size():
		_bag_sel = Game.bag.size() - 1
	if _bag_sel < 0 and Game.bag.size() > 0:
		_bag_sel = 0
	for i in 18:
		var empty := i >= Game.bag.size()
		var b := _slot(24, i == _bag_sel, empty)
		if not empty:
			var id: String = Game.bag[i]
			var ic := _place_icon(b, Game.eq_icon(id), 20, 24)
			if Game.equip_block_reason(id) != "":
				ic.modulate = Color(1, 0.55, 0.55, 0.75)
			b.tooltip_text = Game.eq(id)["name"]
			b.pressed.connect(func():
				_bag_sel = i
				_refresh_character())
		_bag_grid.add_child(b)
	if _bag_sel >= 0:
		var id: String = Game.bag[_bag_sel]
		var e: Dictionary = Game.eq(id)
		_eq_icon.texture = load(Game.eq_icon(id))
		_eq_icon.visible = true
		_eq_name.text = "%s  ·  %s" % [e["name"], GameData.SLOT_NAMES[e["slot"]]]
		var worn: String = Game.equipped.get(e["slot"], "")
		var cmp := ("\nLlevas: %s (%s)" % [Game.eq(worn)["name"], _bonus_text(Game.eq(worn))]) if worn != "" else ""
		_eq_desc.text = "%s\n%s\nRequiere nivel %d%s" % [_bonus_text(e), e["desc"], e["level"], cmp]
		var why := Game.equip_block_reason(id)
		_eq_btn.visible = true
		_eq_btn.disabled = why != ""
		_eq_btn.text = "Equipar" if why == "" else why
	else:
		_eq_icon.visible = false
		_eq_name.text = "La bolsa está vacía"
		_eq_desc.text = "Los monstruos a veces dejan armas y armaduras. Los jefes, siempre."
		_eq_btn.visible = false
	# hero
	var sf := load("res://resources/sprite_frames/swordsman_lvl%d.tres" % Game.look_tier()) as SpriteFrames
	if sf and sf.has_animation(&"idle_down"):
		var a := AtlasTexture.new()
		var f := sf.get_frame_texture(&"idle_down", 0) as AtlasTexture
		a.atlas = f.atlas
		a.region = Rect2(f.region.position + Vector2(12, 8), Vector2(40, 40))
		_portrait.texture = a
	_look_label.text = Game.look_title()
	for c in _stat_grid.get_children():
		c.queue_free()
	_stat_row(_stat_grid, "Nivel", "%d" % Game.level, true)
	_stat_row(_stat_grid, "Experiencia", "%d / %d" % [Game.xp, Game.xp_to_next()])
	_stat_row(_stat_grid, "Vida", "%d / %d" % [Game.player_hp, Game.max_hp])
	_stat_row(_stat_grid, "Maná", "%d / %d" % [int(Game.mana), int(Game.max_mana)])
	_stat_row(_stat_grid, "Estamina", "%d" % int(Game.max_stamina))
	_stat_row(_stat_grid, "Ataque", "%d" % Game.attack(), Game.buff_active())
	_stat_row(_stat_grid, "Defensa", "%d" % Game.defense())
	_stat_row(_stat_grid, "Crítico", "%d %%" % int(round(Game.crit_chance() * 100)))
	_stat_row(_stat_grid, "Esquiva", "%d %%" % int(round(Game.dodge_chance() * 100)))
	_stat_row(_stat_grid, "Velocidad", "%d %%" % int(round(Game.speed_mult() * 100)))
	if Game.tsum("lifesteal") > 0.0:
		_stat_row(_stat_grid, "Robo de vida", "%d %%" % int(round(Game.tsum("lifesteal") * 100)))
	_stat_row(_stat_grid, "Poder de habilidad", "%d %%" % int(round(Game.skill_power() * 100)))
	_stat_row(_stat_grid, "Rango del Gremio", "%s · %d" % [Game.guild_rank()[1], Game.renown], true)
	_next_look.text = ""
	for l in GameData.LOOKS:
		if int(l[0]) > Game.level:
			_next_look.text = "Nuevo aspecto en el nivel %d" % l[0]
			break


func _on_equip() -> void:
	if _bag_sel >= 0 and Game.equip(_bag_sel):
		_bag_sel = -1
		_refresh_character()


func _refresh_inventory() -> void:
	for c in _grid.get_children():
		c.queue_free()
	var ids: Array = Game.inventory.keys()
	if _sel_item != "" and not _sel_item in ids:
		_sel_item = ""
	if _sel_item == "" and ids.size() > 0:
		_sel_item = ids[0]
	for i in SLOTS:
		var empty := i >= ids.size()
		var id: String = "" if empty else ids[i]
		var slot := _slot(30, id == _sel_item and not empty, empty)
		_grid.add_child(slot)
		if empty:
			continue
		slot.tooltip_text = GameData.ITEMS[id]["name"]
		_place_icon(slot, GameData.ITEMS[id]["icon"], 16, 30)
		var n := _ink(str(Game.item_count(id)), 7, Color(1, 0.97, 0.9))
		n.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.05))
		n.add_theme_constant_override("outline_size", 3)
		n.position = Vector2(17, 16)
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(n)
		slot.pressed.connect(func():
			_sel_item = id
			_refresh_inventory())
	if _sel_item == "":
		_item_icon.visible = false
		_item_name.text = "Bolsa vacía"
		_item_kind.text = ""
		_item_desc.text = "Los monstruos de la llanura sueltan materiales; Kara, la herrera, te los compra."
		_use_btn.visible = false
	else:
		var it: Dictionary = GameData.ITEMS[_sel_item]
		_item_icon.visible = true
		_item_icon.texture = Game.icon_texture(it["icon"])
		_item_name.text = it["name"]
		_item_kind.text = ("Consumible" if it.has("use") else "Material") + "   ·   %d en la bolsa" % Game.item_count(_sel_item)
		_item_desc.text = it["desc"]
		_use_btn.visible = it.has("use")
	var t := int(Game.play_time)
	_inv_footer.text = "Oro: %d      Tiempo de juego: %d h %02d min" % [Game.gold, t / 3600, (t / 60) % 60]


func _on_use() -> void:
	if _sel_item != "" and Game.use_item(_sel_item):
		_refresh_inventory()


func _refresh_skills() -> void:
	_skill_header.text = "Experiencia de habilidad: %d" % Game.skill_xp
	for c in _skill_list.get_children():
		c.queue_free()
	for i in GameData.SKILLS.size():
		var s: Dictionary = GameData.SKILLS[i]
		var id: String = s["id"]
		var rank := Game.skill_rank(id)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 27)
		var sel := id == _skill_sel
		var st := _box(Color(0.96, 0.9, 0.76) if sel else Color(0.88, 0.8, 0.63), Color(0.95, 0.72, 0.2) if sel else Color(0.65, 0.5, 0.34), 2 if sel else 1, 0)
		for k in ["normal", "pressed", "focus"]:
			b.add_theme_stylebox_override(k, st)
		var hov := st.duplicate() as StyleBoxFlat
		hov.bg_color = Color(0.95, 0.88, 0.72)
		b.add_theme_stylebox_override("hover", hov)
		var ic := _icon(s["icon"], 21)
		ic.position = Vector2(3, 3)
		if rank == 0:
			ic.modulate = Color(0.55, 0.55, 0.55, 0.75)
		b.add_child(ic)
		var nm := _ink(s["name"], 8)
		nm.position = Vector2(29, 2)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(nm)
		var pips := HBoxContainer.new()
		pips.add_theme_constant_override("separation", 2)
		pips.position = Vector2(30, 17)
		pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pips(pips, rank, GameData.MAX_SKILL_RANK)
		b.add_child(pips)
		var key := _ink(str(i + 1) if rank > 0 else "Nv %d" % s["level"], 7, GOLD if rank > 0 else INK_SOFT)
		key.position = Vector2(165, 8)
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(key)
		b.pressed.connect(func():
			_skill_sel = id
			_refresh_skills())
		_skill_list.add_child(b)
	# detail
	var s := GameData.skill_def(_skill_sel)
	var idx := GameData.SKILLS.find(s)
	var rank := Game.skill_rank(_skill_sel)
	_sk_icon.texture = Game.icon_texture(s["icon"])
	_sk_icon.modulate = Color.WHITE if rank > 0 else Color(0.6, 0.6, 0.6, 0.8)
	_sk_name.text = s["name"]
	_pips(_sk_pips, rank, GameData.MAX_SKILL_RANK)
	var v := GameData.skill_values(_skill_sel, maxi(rank, 1), Game.attack())
	_sk_meta.text = "Tecla %d   ·   Maná %d   ·   Recarga %s s" % [idx + 1, int(Game.skill_mana_cost(_skill_sel)), str(snappedf(float(v["cd"]) * maxf(0.5, 1.0 - Game.tsum("cdr")), 0.1)).trim_suffix(".0")]
	_sk_desc.text = GameData.skill_text(_skill_sel, maxi(rank, 1), Game.attack())
	if rank == 0:
		_sk_next.text = "Se aprende a partir del nivel %d." % s["level"]
	elif rank < GameData.MAX_SKILL_RANK:
		_sk_next.text = "Rango %d: %s" % [rank + 1, GameData.skill_text(_skill_sel, rank + 1, Game.attack())]
	else:
		_sk_next.text = "Dominas esta habilidad."
	var why := Game.skill_block_reason(_skill_sel)
	var cost := GameData.skill_cost(rank)
	if rank >= GameData.MAX_SKILL_RANK:
		_sk_btn.text = "Rango máximo"
	elif Game.level < int(s["level"]):
		_sk_btn.text = "Requiere nivel %d" % s["level"]
	else:
		_sk_btn.text = ("Aprender" if rank == 0 else "Mejorar a rango %d" % (rank + 1)) + "  (%d exp.)" % cost
	_sk_btn.disabled = why != ""


func _on_skill_btn() -> void:
	Game.improve_skill(_skill_sel)
	_refresh_skills()


func _refresh_talents() -> void:
	_tp_label.text = str(Game.talent_points)
	for m in GameData.MAINS:
		var id: String = m["id"]
		(_main_labels[id] as Label).text = "%s   %d" % [m["name"], Game.attr(id)]
		for b in _main_buttons[id]:
			(b as Button).disabled = Game.talent_points <= 0
	_respec.text = "Reiniciar (%d oro)" % Game.respec_cost()
	_respec.tooltip_text = "Recupera todos los puntos de talento gastados."
	_tree.call("refresh")
	_refresh_talent_detail()


func _refresh_talent_detail() -> void:
	var id: String = _tree.get("selected")
	if id == "":
		id = "vigor"
		_tree.set("selected", id)
		_tree.call("refresh")
	var n := GameData.talent_node(id)
	var rank := Game.talent_rank(id)
	_tl_icon.texture = load(GameData.TI + id + ".png")
	_tl_name.text = n["name"]
	_tl_branch.text = "%s   ·   rango %d / %d" % [GameData.BRANCHES[int(n["branch"])]["name"], rank, n["max"]]
	_tl_desc.text = n["desc"]
	var why := Game.talent_block_reason(id)
	if rank >= int(n["max"]):
		_tl_state.text = "Completo."
	elif why != "":
		_tl_state.text = why
	else:
		_tl_state.text = "Disponible."
	_tl_btn.text = "Completo" if rank >= int(n["max"]) else "Aprender (1 punto)"
	_tl_btn.disabled = why != ""


func _on_talent_btn() -> void:
	Game.add_talent(_tree.get("selected"))
	_refresh_talents()
