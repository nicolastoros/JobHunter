extends CanvasLayer
## Stable at the Eastern Farms: buy the riding deer and companions, and choose who travels with you.

const PAPER := Color(0.93, 0.87, 0.72)
const INK := Color(0.25, 0.16, 0.1)
const INK_SOFT := Color(0.47, 0.33, 0.22)
const GOLD := Color(0.62, 0.42, 0.08)
const BAD := Color(0.62, 0.14, 0.1)

var _root: Control
var _cards: HBoxContainer
var _gold: Label


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
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 5)
	_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_cards)
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


func _card(title: String, frames_path: String, desc: String, price: int, rank: String, button_text: String, enabled: bool, on_press: Callable, owned: bool) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _box(Color(0.97, 0.92, 0.75) if owned else PAPER, Color(0.85, 0.62, 0.2) if owned else Color(0.55, 0.42, 0.28), 2 if owned else 1, 5))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	card.add_child(v)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _box(Color(0.42, 0.55, 0.32), Color(0.3, 0.38, 0.22), 1, 0))
	frame.custom_minimum_size = Vector2(0, 52)
	v.add_child(frame)
	var pic := TextureRect.new()
	pic.texture = _portrait(frames_path)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(pic)
	v.add_child(_ink(title, 9))
	var d := _ink(desc, 7, INK_SOFT)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(110, 0)
	v.add_child(d)
	if not owned:
		v.add_child(_ink("Precio: %d de oro" % price, 8, GOLD if Game.gold >= price else BAD))
		v.add_child(_ink("Licencia: rango %s" % rank, 7, INK if Game.rank_at_least(rank) else BAD))
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(grow)
	var b := Button.new()
	b.text = button_text
	b.disabled = not enabled
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 8)
	b.pressed.connect(func():
		on_press.call()
		_refresh())
	v.add_child(b)
	return card


func _refresh() -> void:
	for c in _cards.get_children():
		c.queue_free()
	_gold.text = "Tu oro: %d      Licencia actual: rango %s" % [Game.gold, Game.guild_rank()[1]]
	var m := GameData.MOUNT
	if Game.has_mount:
		_cards.add_child(_card(m["name"], m["frames"], m["desc"], m["price"], m["rank"], "Tuyo · tecla H para montar", false, func(): pass, true))
	else:
		var why := Game.stable_block_reason(int(m["price"]), m["rank"])
		_cards.add_child(_card(m["name"], m["frames"], m["desc"], m["price"], m["rank"], "Comprar" if why == "" else why, why == "", func(): Game.buy_mount(), false))
	for id in GameData.PETS:
		var p: Dictionary = GameData.PETS[id]
		var pid: String = id
		if pid in Game.pets:
			var active := Game.active_pet == pid
			_cards.add_child(_card(p["name"], p["frames"], p["desc"], p["price"], p["rank"], "Dejar en el establo" if active else "Llevar conmigo", true,
				func(): Game.set_active_pet("" if active else pid), true))
		else:
			var why := Game.stable_block_reason(int(p["price"]), p["rank"])
			_cards.add_child(_card(p["name"], p["frames"], p["desc"], p["price"], p["rank"], "Comprar" if why == "" else why, why == "", func(): Game.buy_pet(pid), false))
