extends CanvasLayer
## Travel menu of the rune stones: every stone of Valdoria by region; awake ones can be travelled to,
## sleeping ones show where to find them.

const PAPER := Color(0.93, 0.87, 0.72)
const PAPER_DARK := Color(0.85, 0.77, 0.6)
const INK := Color(0.25, 0.16, 0.1)
const INK_SOFT := Color(0.47, 0.33, 0.22)
const GOLD := Color(0.62, 0.42, 0.08)

var _root: Control
var _list: VBoxContainer
var _from := ""


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
	board.add_theme_stylebox_override("panel", _box(Color(0.2, 0.18, 0.3), Color(0.1, 0.08, 0.16), 3, 6))
	board.custom_minimum_size = Vector2(300, 236)
	board.size = board.custom_minimum_size
	_root.add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	board.add_child(vb)
	var head := HBoxContainer.new()
	vb.add_child(head)
	var title := Label.new()
	title.text = "PIEDRAS RÚNICAS"
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	title.add_theme_constant_override("outline_size", 4)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := Button.new()
	close.text = "Cerrar [Esc]"
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 8)
	close.pressed.connect(close_menu)
	head.add_child(close)
	var paper := PanelContainer.new()
	paper.add_theme_stylebox_override("panel", _box(PAPER, Color(0.55, 0.42, 0.28), 1, 4))
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(paper)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	paper.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_root.hide()
	Game.waystone_menu_requested.connect(open)


func _unhandled_input(event: InputEvent) -> void:
	if _root.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close_menu()


func open(from_id: String) -> void:
	_from = from_id
	Game.sfx("ui_open", -2.0, 0.0)
	Game.menu_open = true
	get_tree().paused = true
	_root.show()
	_refresh()


func close_menu() -> void:
	_root.hide()
	get_tree().paused = false
	Game.menu_open = false


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
	return l


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	_list.add_child(_ink("Despiertas: %d / %d. Toca una piedra dormida (E) para despertarla." % [Game.waystones_unlocked.size(), GameData.WAYSTONES.size()], 7, INK_SOFT))
	for region in GameData.WORLD_MAP:
		var stones := GameData.WAYSTONES.filter(func(w): return w["map"] == region["file"])
		if stones.is_empty():
			continue
		var known: bool = Game.visited_maps.has(region["file"])
		_list.add_child(_ink(region["name"] if known else "Tierra desconocida", 8, GOLD))
		for w in stones:
			var awake := Game.is_waystone_unlocked(w["id"])
			var here: bool = w["id"] == _from
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			var icon := TextureRect.new()
			icon.texture = Game.icon_texture("res://assets/ui/icons/waystone.png")
			icon.custom_minimum_size = Vector2(14, 14)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.modulate = Color.WHITE if awake else Color(0.3, 0.3, 0.35, 0.6)
			row.add_child(icon)
			var name_ := _ink(w["name"] if (awake or known) else "???", 8, INK if awake else INK_SOFT)
			name_.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(name_)
			var b := Button.new()
			b.focus_mode = Control.FOCUS_NONE
			b.add_theme_font_size_override("font_size", 7)
			b.text = "Estás aquí" if here else ("Viajar" if awake else "Dormida")
			b.disabled = here or not awake
			var id: String = w["id"]
			b.pressed.connect(func():
				close_menu()
				Game.teleport_to(id))
			row.add_child(b)
			_list.add_child(row)
