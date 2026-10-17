extends CanvasLayer
## Hunters' Guild board, three tabs:
##  - Pedidos: story requests (accept, track, cash in).
##  - Contratos: three repeatable hunting contracts that renew when cashed in.
##  - Ranking: the hero's guild rank and renown, and the ranking of Valdoria's hunters.

const RANK_COLORS := {"E": Color(0.1, 0.28, 0.12), "D": Color(0.08, 0.16, 0.42), "C": Color(0.42, 0.28, 0.02),
	"B": Color(0.5, 0.1, 0.05), "A": Color(0.38, 0.06, 0.42), "S": Color(0.55, 0.38, 0.0)}
const TABS := ["quests", "contracts", "ranking"]
const TAB_TITLES := {"quests": "Pedidos", "contracts": "Contratos", "ranking": "Ranking"}
const PAPER := Color(0.93, 0.87, 0.72)
const PAPER_DARK := Color(0.86, 0.78, 0.6)
const INK := Color(0.25, 0.16, 0.1)
const INK_SOFT := Color(0.47, 0.33, 0.22)
const GOLD := Color(0.62, 0.42, 0.08)
const GOOD := Color(0.13, 0.42, 0.14)
## Item icon shown for each contract target.
const TARGET_ICONS := {"Limo": "gel", "Limo extraño": "gel", "Goblin": "abalorio", "Gnoll": "piel",
	"Gólem de las Ruinas": "nucleo", "Ent Ancestral": "corteza", "Rey Limo": "corona"}

var _root: Control
var _tab := "quests"
var _tab_buttons := {}
var _pages := {}
var _portraits := {}
# quests
var _list: VBoxContainer
var _title: Label
var _meta: Label
var _desc: Label
var _reward: Label
var _accept: Button
var _selected := -1
# contracts
var _contract_box: HBoxContainer
var _reroll: Button
# ranking
var _rank_letter: Label
var _rank_title: Label
var _rank_info: Label
var _rank_bar: ColorRect
var _rank_bar_bg: ColorRect
var _table: VBoxContainer


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.hide()
	Game.quest_board_requested.connect(open)
	Game.quests_changed.connect(func(): if _root.visible: _refresh())
	Game.stats_changed.connect(func(): if _root.visible and _tab != "quests": _refresh())


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


func _button(text: String, cb: Callable, size := 8) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(cb)
	return b


func _portrait(tier: int) -> Texture2D:
	if _portraits.has(tier):
		return _portraits[tier]
	var sf := load("res://resources/sprite_frames/swordsman_lvl%d.tres" % tier) as SpriteFrames
	var a := AtlasTexture.new()
	var f := sf.get_frame_texture(&"idle_down", 0) as AtlasTexture
	a.atlas = f.atlas
	a.region = Rect2(f.region.position + Vector2(20, 14), Vector2(24, 24))
	_portraits[tier] = a
	return a


# =============================================================================
# Build
# =============================================================================

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.02, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var board := PanelContainer.new()
	board.add_theme_stylebox_override("panel", _box(Color(0.36, 0.23, 0.13), Color(0.18, 0.1, 0.06), 3, 5))
	board.position = Vector2(4, 3)
	board.size = Vector2(472, 264)
	board.custom_minimum_size = board.size
	_root.add_child(board)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	board.add_child(vb)
	var head := Label.new()
	head.text = "GREMIO DE CAZADORES DE VALDORIA"
	head.add_theme_font_size_override("font_size", 10)
	head.add_theme_color_override("font_color", Color(1, 0.86, 0.5))
	head.add_theme_constant_override("outline_size", 4)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(head)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 2)
	vb.add_child(tabs)
	for t in TABS:
		var b := Button.new()
		b.text = TAB_TITLES[t]
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 8)
		b.custom_minimum_size = Vector2(96, 17)
		b.pressed.connect(show_tab.bind(t))
		tabs.add_child(b)
		_tab_buttons[t] = b
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(sp)
	tabs.add_child(_button("Cerrar  [Esc]", close_board))
	var page := PanelContainer.new()
	page.add_theme_stylebox_override("panel", _box(PAPER_DARK, Color(0.55, 0.42, 0.28), 1, 4))
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(page)
	var stack := Control.new()
	stack.clip_contents = true
	page.add_child(stack)
	_pages["quests"] = _build_quests()
	_pages["contracts"] = _build_contracts()
	_pages["ranking"] = _build_ranking()
	for k in _pages:
		(_pages[k] as Control).set_anchors_preset(Control.PRESET_FULL_RECT)
		stack.add_child(_pages[k])


func _build_quests() -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 5)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(190, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hb.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	scroll.add_child(_list)
	var paper := _paper()
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(paper)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 3)
	paper.add_child(pv)
	_title = _ink("", 10)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_meta = _ink("", 7, INK_SOFT)
	_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc = _ink("", 8)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_desc.custom_minimum_size = Vector2(180, 0)
	_reward = _ink("", 8, GOLD)
	for n in [_title, _meta, _desc, _reward]:
		pv.add_child(n)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	pv.add_child(buttons)
	_accept = _button("Aceptar pedido", _on_accept)
	buttons.add_child(_accept)
	return hb


func _build_contracts() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.add_child(_ink("Encargos de caza que se renuevan cada vez que los cobras. Siempre hay trabajo para un cazador.", 7, INK_SOFT))
	_contract_box = HBoxContainer.new()
	_contract_box.add_theme_constant_override("separation", 5)
	_contract_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_contract_box)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 6)
	v.add_child(foot)
	var tip := _ink("Racha: abate presas sin pausa (menos de 6 s entre una y otra) y cada presa da hasta +90 % de renombre.", 7, INK_SOFT)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(tip)
	_reroll = _button("Otros contratos", func():
		Game.reroll_contracts()
		_refresh(), 7)
	foot.add_child(_reroll)
	return v


func _build_ranking() -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 5)
	var me := _paper()
	me.custom_minimum_size = Vector2(150, 0)
	hb.add_child(me)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 2)
	me.add_child(mv)
	mv.add_child(_ink("Tu rango en el Gremio", 8, INK_SOFT))
	_rank_letter = _ink("E", 30, GOLD)
	_rank_letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mv.add_child(_rank_letter)
	_rank_title = _ink("", 10)
	_rank_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mv.add_child(_rank_title)
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 6)
	mv.add_child(bar)
	_rank_bar_bg = ColorRect.new()
	_rank_bar_bg.color = Color(0.55, 0.45, 0.35, 0.5)
	_rank_bar_bg.size = Vector2(136, 5)
	bar.add_child(_rank_bar_bg)
	_rank_bar = ColorRect.new()
	_rank_bar.color = Color(0.85, 0.6, 0.15)
	_rank_bar.size = Vector2(0, 5)
	bar.add_child(_rank_bar)
	_rank_info = _ink("", 7)
	_rank_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rank_info.custom_minimum_size = Vector2(136, 0)
	mv.add_child(_rank_info)
	var tp := _paper()
	tp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(tp)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 1)
	tp.add_child(tv)
	var hdr := HBoxContainer.new()
	for pair in [["#", 18], ["", 20], ["Cazador", 92], ["Rango", 36], ["Nivel", 34], ["Renombre", 60]]:
		var l := _ink(pair[0], 7, INK_SOFT)
		l.custom_minimum_size = Vector2(pair[1], 0)
		hdr.add_child(l)
	tv.add_child(hdr)
	_table = VBoxContainer.new()
	_table.add_theme_constant_override("separation", 1)
	tv.add_child(_table)
	return hb


# =============================================================================
# Open / close / tabs
# =============================================================================

func open() -> void:
	Game.input_locked = true
	_root.show()
	show_tab(_tab)
	if _selected < 0:
		_select(0)


func close_board() -> void:
	_root.hide()
	await get_tree().process_frame
	Game.input_locked = false


func show_tab(t: String) -> void:
	_tab = t
	for k in _pages:
		(_pages[k] as Control).visible = k == t
	for k in _tab_buttons:
		var b: Button = _tab_buttons[k]
		var active: bool = k == t
		var st := _box(PAPER_DARK, Color(0.55, 0.42, 0.28), 1, 2) if active else _box(Color(0.25, 0.15, 0.09), Color(0.42, 0.28, 0.16), 1, 2)
		if active:
			st.border_width_bottom = 0
			st.expand_margin_bottom = 1
		for s in ["normal", "pressed", "focus", "hover"]:
			b.add_theme_stylebox_override(s, st)
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(c, INK if active else Color(0.9, 0.82, 0.66))
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _root.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close_board()


func _refresh() -> void:
	match _tab:
		"quests": _refresh_quests()
		"contracts": _refresh_contracts()
		"ranking": _refresh_ranking()


# =============================================================================
# Quests
# =============================================================================

func _refresh_quests() -> void:
	for c in _list.get_children():
		c.queue_free()
	for i in Game.quests.size():
		var q: Dictionary = Game.quests[i]
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "[%s] %s%s" % [q["rank"], q["title"], _tag(q)]
		b.add_theme_font_size_override("font_size", 8)
		b.add_theme_color_override("font_color", RANK_COLORS.get(q["rank"], Color.WHITE))
		b.clip_text = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(180, 0)
		b.pressed.connect(_select.bind(i))
		_list.add_child(b)
	if _selected >= 0:
		_select(_selected)


func _select(i: int) -> void:
	_selected = i
	var q: Dictionary = Game.quests[i]
	_title.text = q["title"]
	_meta.text = "Rango %s  ·  %s  ·  Solicita: %s" % [q["rank"], q["zone"], q["giver"]]
	var desc: String = q["desc"]
	if q.has("target") and q["state"] in ["accepted", "done"]:
		desc += "\n\nProgreso: %d / %d" % [int(q.get("progress", 0)), int(q["target"][1])]
	elif q["state"] == "soon":
		desc += "\n\nEste pedido todavía no se puede aceptar."
	elif q["state"] == "claimed":
		desc += "\n\nYa cobraste este pedido. ¡Buen trabajo!"
	_desc.text = desc
	_reward.text = "Recompensa: %d de oro%s" % [q["reward"], ("  ·  %d de experiencia" % q["xp"]) if q.has("xp") else ""]
	match String(q["state"]):
		"open":
			_accept.text = "Aceptar pedido"; _accept.disabled = false
		"accepted":
			_accept.text = "En curso"; _accept.disabled = true
		"done":
			_accept.text = "Cobrar recompensa"; _accept.disabled = false
		"claimed":
			_accept.text = "Completado"; _accept.disabled = true
		_:
			_accept.text = "Próximamente"; _accept.disabled = true


func _on_accept() -> void:
	if _selected >= 0:
		var q: Dictionary = Game.quests[_selected]
		if q["state"] == "done":
			Game.claim_quest(q["id"])
		else:
			Game.accept_quest(q["id"])
		_refresh_quests()


static func _tag(q: Dictionary) -> String:
	match String(q["state"]):
		"accepted":
			return "   %d/%d" % [int(q.get("progress", 0)), int(q["target"][1])]
		"done":
			return "   ¡Listo!"
		"claimed":
			return "   (cobrado)"
		"soon":
			return "   (pronto)"
	return ""


# =============================================================================
# Contracts
# =============================================================================

func _refresh_contracts() -> void:
	for c in _contract_box.get_children():
		c.queue_free()
	for i in Game.contracts.size():
		var c: Dictionary = Game.contracts[i]
		var done := int(c["progress"]) >= int(c["count"])
		var card := _paper(Color(0.97, 0.92, 0.75) if done else PAPER)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_contract_box.add_child(card)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 3)
		card.add_child(v)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 4)
		v.add_child(top)
		var ic := TextureRect.new()
		ic.texture = Game.icon_texture(GameData.ITEMS[TARGET_ICONS.get(c["monster"], "gel")]["icon"])
		ic.custom_minimum_size = Vector2(24, 24)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		top.add_child(ic)
		var tl := _ink("Caza %d × %s" % [c["count"], c["monster"]], 9)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tl.custom_minimum_size = Vector2(90, 0)
		top.add_child(tl)
		var bar := Control.new()
		bar.custom_minimum_size = Vector2(0, 6)
		v.add_child(bar)
		var bg := ColorRect.new()
		bg.color = Color(0.55, 0.45, 0.35, 0.5)
		bg.size = Vector2(128, 5)
		bar.add_child(bg)
		var fill := ColorRect.new()
		fill.color = GOOD if done else Color(0.85, 0.6, 0.15)
		fill.size = Vector2(128.0 * float(c["progress"]) / float(c["count"]), 5)
		bar.add_child(fill)
		v.add_child(_ink("Progreso: %d / %d" % [c["progress"], c["count"]], 7, GOOD if done else INK_SOFT))
		v.add_child(_ink("Recompensa:", 7, INK_SOFT))
		v.add_child(_ink("%d de oro" % c["gold"], 8, GOLD))
		v.add_child(_ink("%d de renombre" % c["renown"], 8, GOLD))
		v.add_child(_ink("%d de exp. de habilidad" % c["sxp"], 8, GOLD))
		var grow := Control.new()
		grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(grow)
		var b := _button("Cobrar" if done else "En curso", func():
			Game.claim_contract(i)
			_refresh())
		b.disabled = not done
		v.add_child(b)
	_reroll.text = "Otros contratos (%d oro)" % Game.reroll_cost()


# =============================================================================
# Ranking
# =============================================================================

func _refresh_ranking() -> void:
	var rk := Game.guild_rank()
	var nxt := Game.next_guild_rank()
	_rank_letter.text = rk[1]
	_rank_letter.add_theme_color_override("font_color", RANK_COLORS.get(rk[1], GOLD))
	_rank_title.text = rk[2]
	if nxt.is_empty():
		_rank_bar.size.x = 136
		_rank_info.text = "Renombre: %d\nPuesto %d en el ranking.\n\nEres una leyenda del Gremio." % [Game.renown, Game.player_place()]
	else:
		var a := float(rk[0])
		var frac := (Game.renown - a) / (float(nxt[0]) - a)
		_rank_bar.size.x = roundf(136.0 * clampf(frac, 0.0, 1.0))
		_rank_info.text = "Renombre: %d / %d\nPuesto %d en el ranking.\n\nAl llegar a rango %s: oro, pociones y una pieza de equipo.\n\nSe gana renombre cazando (más en racha), con pedidos, contratos y cofres." % [
			Game.renown, nxt[0], Game.player_place(), nxt[1]]
	for c in _table.get_children():
		c.queue_free()
	var r := Game.ranking()
	var place := Game.player_place()
	for i in r.size():
		if i >= 10 and i + 1 != place:
			continue
		if i >= 10 and i + 1 == place:
			var dots := _ink("   ···", 7, INK_SOFT)
			_table.add_child(dots)
		_table.add_child(_rank_row(i + 1, r[i]))


func _rank_row(place: int, e: Dictionary) -> Control:
	var row := PanelContainer.new()
	var me: bool = e["player"]
	row.add_theme_stylebox_override("panel", _box(Color(0.98, 0.88, 0.55) if me else (Color(0, 0, 0, 0.04) if place % 2 == 0 else Color(0, 0, 0, 0)),
		Color(0.85, 0.62, 0.2) if me else Color(0, 0, 0, 0), 1 if me else 0, 0))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 0)
	row.add_child(hb)
	var medal := {1: Color(0.85, 0.65, 0.1), 2: Color(0.55, 0.55, 0.6), 3: Color(0.7, 0.42, 0.2)}
	var n := _ink(str(place), 8, medal.get(place, INK))
	n.custom_minimum_size = Vector2(18, 0)
	hb.add_child(n)
	var pic := TextureRect.new()
	pic.texture = _portrait(int(e["tier"]))
	pic.custom_minimum_size = Vector2(14, 14)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hb.add_child(pic)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(6, 0)
	hb.add_child(gap)
	for pair in [[e["name"], 92, INK], [e["rank"], 36, RANK_COLORS.get(e["rank"], INK)], [str(e["level"]), 34, INK], [str(e["renown"]), 60, GOLD]]:
		var l := _ink(pair[0], 8, pair[2])
		l.custom_minimum_size = Vector2(pair[1], 0)
		hb.add_child(l)
	return row
