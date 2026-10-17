extends CanvasLayer
## Guild quest board: browse the posted requests and accept them.

const RANK_COLORS := {"E": Color(0.1, 0.28, 0.12), "D": Color(0.08, 0.16, 0.42), "C": Color(0.42, 0.28, 0.02),
	"B": Color(0.5, 0.1, 0.05), "A": Color(0.38, 0.06, 0.42)}

var _list: VBoxContainer
var _title: Label
var _meta: Label
var _desc: Label
var _reward: Label
var _accept: Button
var _selected := -1
var _root: Control


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.hide()
	Game.quest_board_requested.connect(open)
	Game.quests_changed.connect(_refresh)


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.02, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var board := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.36, 0.23, 0.13, 0.98)
	sb.border_color = Color(0.2, 0.12, 0.07)
	sb.set_border_width_all(3)
	sb.content_margin_left = 8; sb.content_margin_right = 8; sb.content_margin_top = 6; sb.content_margin_bottom = 8
	sb.anti_aliasing = false
	board.add_theme_stylebox_override("panel", sb)
	board.set_anchors_preset(Control.PRESET_TOP_LEFT)
	board.custom_minimum_size = Vector2(400, 220)
	board.position = Vector2(40, 25)
	board.size = Vector2(400, 220)
	_root.add_child(board)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	board.add_child(vb)
	var head := Label.new()
	head.text = "TABLÓN DE PEDIDOS — Gremio de Cazadores de Valdoria"
	head.add_theme_font_size_override("font_size", 10)
	head.add_theme_color_override("font_color", Color(1, 0.86, 0.5))
	head.add_theme_constant_override("outline_size", 4)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(head)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(170, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hb.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 3)
	scroll.add_child(_list)
	# parchment detail
	var paper := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.93, 0.87, 0.72)
	ps.border_color = Color(0.55, 0.42, 0.28)
	ps.set_border_width_all(1)
	ps.content_margin_left = 6; ps.content_margin_right = 6; ps.content_margin_top = 4; ps.content_margin_bottom = 4
	ps.anti_aliasing = false
	paper.add_theme_stylebox_override("panel", ps)
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(paper)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 3)
	paper.add_child(pv)
	var ink := Color(0.25, 0.16, 0.1)
	_title = Label.new(); _title.add_theme_font_size_override("font_size", 10); _title.add_theme_color_override("font_color", ink)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_meta = Label.new(); _meta.add_theme_font_size_override("font_size", 7); _meta.add_theme_color_override("font_color", Color(0.45, 0.3, 0.2))
	_desc = Label.new(); _desc.add_theme_font_size_override("font_size", 8); _desc.add_theme_color_override("font_color", ink)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reward = Label.new(); _reward.add_theme_font_size_override("font_size", 8); _reward.add_theme_color_override("font_color", Color(0.55, 0.38, 0.05))
	for n in [_title, _meta, _desc, _reward]:
		n.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		n.add_theme_constant_override("outline_size", 0)
		pv.add_child(n)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	pv.add_child(buttons)
	_accept = Button.new(); _accept.text = "Aceptar pedido"; _accept.pressed.connect(_on_accept)
	var close := Button.new(); close.text = "Cerrar"; close.pressed.connect(close_board)
	buttons.add_child(_accept); buttons.add_child(close)


func open() -> void:
	Game.input_locked = true
	_root.show()
	_refresh()
	if _selected < 0:
		_select(0)


func close_board() -> void:
	_root.hide()
	await get_tree().process_frame
	Game.input_locked = false


func _unhandled_input(event: InputEvent) -> void:
	if _root.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close_board()


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	for i in Game.quests.size():
		var q: Dictionary = Game.quests[i]
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "[%s] %s%s" % [q["rank"], q["title"], "  ✔" if q["state"] == "accepted" else ""]
		b.add_theme_font_size_override("font_size", 8)
		b.add_theme_color_override("font_color", RANK_COLORS.get(q["rank"], Color.WHITE))
		b.clip_text = true
		b.custom_minimum_size = Vector2(160, 0)
		b.pressed.connect(_select.bind(i))
		_list.add_child(b)
	if _selected >= 0:
		_select(_selected)


func _select(i: int) -> void:
	_selected = i
	var q: Dictionary = Game.quests[i]
	_title.text = q["title"]
	_meta.text = "Rango %s  ·  %s  ·  Solicita: %s" % [q["rank"], q["zone"], q["giver"]]
	_desc.text = q["desc"]
	_reward.text = "Recompensa: %d monedas de oro" % q["reward"]
	_accept.disabled = q["state"] != "open"
	_accept.text = "Aceptar pedido" if q["state"] == "open" else "En curso"
	if _list.get_child_count() > i:
		(_list.get_child(i) as Button).grab_focus()


func _on_accept() -> void:
	if _selected >= 0:
		Game.accept_quest(Game.quests[_selected]["id"])
		_select(_selected)
