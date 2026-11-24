extends Control
## Class choice: three cards (Guerrero, Arquero, Mago), each with its hero animated (standing, then
## attacking, turning around), what it does and its bonus. Used by the title screen for a new game
## (mode "new") and by the Guild's class master to change class (mode "change", costs gold).

signal chosen(cls: String)
signal closed

var mode := "new"
var _sprites: Array[AnimatedSprite2D] = []
var _t := 0.0
var _step := 0
const _CYCLE := ["idle_down", "attack_down", "walk_right", "attack_right", "idle_left", "attack_left", "walk_up", "attack_up"]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 6)
	add_child(root)
	var title := _label("Elige tu clase" if mode == "new" else "Maestro de clases", 17, Color(1, 0.84, 0.46))
	root.add_child(title)
	var sub := _label("Podrás cambiarla más tarde en el Gremio (segundo piso)." if mode == "new" else
		("Tu primer cambio es gratis." if Game.class_change_cost() == 0 else "Cambiar de clase cuesta %d de oro. Lo aprendido en cada clase se conserva." % GameData.CLASS_CHANGE_COST), 8, Color(0.9, 0.85, 0.75))
	root.add_child(sub)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	root.add_child(row)
	var first: Button = null
	for cls in GameData.CLASS_ORDER:
		var b := _card(cls, row)
		if first == null or cls == Game.hero_class and mode == "new":
			first = b
	if mode == "change":
		var back := Button.new()
		back.text = "Volver"
		back.add_theme_font_size_override("font_size", 9)
		back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		back.pressed.connect(_close)
		root.add_child(back)
	if first:
		first.grab_focus.call_deferred()


func _label(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.03))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _card(cls: String, row: Container) -> Button:
	var c: Dictionary = GameData.CLASSES[cls]
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(138, 0)
	row.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	panel.add_child(vb)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(120, 62)
	vb.add_child(stage)
	var spr := AnimatedSprite2D.new()
	var tier := Game.look_tier() if mode == "change" else 1
	spr.sprite_frames = load(String(c["frames"]) % tier)
	spr.position = Vector2(69, 34)
	spr.scale = Vector2(1.6, 1.6)
	spr.play("idle_down")
	stage.add_child(spr)
	_sprites.append(spr)
	vb.add_child(_label(String(c["name"]), 13, c["color"]))
	var d := _label(String(c["desc"]), 7, Color(0.95, 0.92, 0.85))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(128, 0)
	vb.add_child(d)
	var p := _label(String(c["perk"]), 7, Color(0.6, 1.0, 0.6))
	p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.custom_minimum_size = Vector2(128, 0)
	vb.add_child(p)
	var sk := PackedStringArray()
	for s in GameData.skills_for(cls):
		sk.append(String(s["name"]))
	var skl := _label("Habilidades: " + ", ".join(sk) + ".", 6, Color(0.8, 0.8, 0.95))
	skl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skl.custom_minimum_size = Vector2(128, 0)
	vb.add_child(skl)
	var b := Button.new()
	b.add_theme_font_size_override("font_size", 9)
	if mode == "new":
		b.text = "Elegir"
	elif cls == Game.hero_class:
		b.text = "Tu clase"
		b.disabled = true
	else:
		var cost := Game.class_change_cost()
		b.text = "Cambiar" if cost == 0 else "Cambiar (%d oro)" % cost
		b.disabled = Game.class_change_reason(cls) != ""
	b.pressed.connect(_pick.bind(cls))
	b.focus_entered.connect(func(): panel.modulate = Color(1.15, 1.1, 1.0))
	b.focus_exited.connect(func(): panel.modulate = Color.WHITE)
	vb.add_child(b)
	return b


func _process(delta: float) -> void:
	_t += delta
	if _t >= 1.4:
		_t = 0.0
		_step = (_step + 1) % _CYCLE.size()
		for s in _sprites:
			if s.sprite_frames.has_animation(_CYCLE[_step]):
				s.play(_CYCLE[_step])


func _pick(cls: String) -> void:
	Game.sfx("ui_open", -2.0, 0.0)
	chosen.emit(cls)
	if mode == "change":
		Game.set_class(cls)
		_close()


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if mode == "change" and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
