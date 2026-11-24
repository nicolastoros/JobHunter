extends CanvasLayer
## Hunter's diary (O): the login streak and today's reward, the quarry of the day, three daily
## tasks, the Guild's chest for finishing all three, and the weekly task.
## Opens by itself the first time you play each day.

const PAPER := Color(0.93, 0.87, 0.72)
const PAPER_DARK := Color(0.85, 0.77, 0.6)
const INK := Color(0.25, 0.16, 0.1)
const INK_SOFT := Color(0.47, 0.33, 0.22)
const GOLD := Color(0.62, 0.42, 0.08)
const GOOD := Color(0.13, 0.42, 0.14)

var _root: Control
var _body: VBoxContainer
var _auto_pending := false


func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.02, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var board := PanelContainer.new()
	board.add_theme_stylebox_override("panel", _box(Color(0.36, 0.23, 0.13), Color(0.18, 0.1, 0.06), 3, 6))
	board.custom_minimum_size = Vector2(440, 246)
	board.size = board.custom_minimum_size
	_root.add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	board.add_child(vb)
	var head := HBoxContainer.new()
	vb.add_child(head)
	var title := Label.new()
	title.text = "DIARIO DEL CAZADOR"
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(1, 0.86, 0.5))
	title.add_theme_constant_override("outline_size", 4)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := Button.new()
	close.text = "Cerrar [Esc]"
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 8)
	close.pressed.connect(close_diary)
	head.add_child(close)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 4)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_body)
	_root.hide()
	Game.daily_changed.connect(func(): if _root.visible: _refresh())
	Game.daily_reward_ready.connect(func(): _auto_pending = true)


func _process(_delta: float) -> void:
	# opens by itself once a day, as soon as you are free to look at it
	if _auto_pending and not _root.visible and _free():
		_auto_pending = false
		if Game.tutorial_step >= 4:
			open()
		else:
			Game.toast("Tienes una recompensa diaria esperando en el diario (O).")


func _free() -> bool:
	return get_tree().get_first_node_in_group("player") != null and not Game.menu_open and not Game.input_locked and not Game.editing


func _unhandled_input(event: InputEvent) -> void:
	if _root.visible:
		if event.is_action_pressed("daily") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
			get_viewport().set_input_as_handled()
			close_diary()
		return
	if event.is_action_pressed("daily") and _free():
		get_viewport().set_input_as_handled()
		open()


func open() -> void:
	Game.check_new_day()
	Game.sfx("ui_open", -2.0, 0.0)
	Game.menu_open = true
	get_tree().paused = true
	_root.show()
	_refresh()


func close_diary() -> void:
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
	l.add_theme_constant_override("line_spacing", -3)
	return l


func _button(text: String, enabled: bool, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = not enabled
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 7)
	b.pressed.connect(func():
		on_press.call()
		_refresh())
	return b


func _bar(frac: float, w := 120.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 5)
	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.45, 0.35, 0.5)
	bg.size = Vector2(w, 4)
	bg.position.y = 1
	c.add_child(bg)
	var fg := ColorRect.new()
	fg.color = Color(0.85, 0.6, 0.15) if frac < 1.0 else Color(0.3, 0.7, 0.3)
	fg.size = Vector2(roundf(w * clampf(frac, 0.0, 1.0)), 4)
	fg.position.y = 1
	c.add_child(fg)
	return c


func _paper() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(PAPER, Color(0.55, 0.42, 0.28), 1, 4))
	return p


func _refresh() -> void:
	for c in _body.get_children():
		c.queue_free()
	var d: Dictionary = Game.daily
	# ---- streak: seven days, today's reward
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 4)
	_body.add_child(top)
	var streak := _paper()
	streak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(streak)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 2)
	streak.add_child(sv)
	sv.add_child(_ink("Racha: %d días seguidos" % int(d.get("streak", 1)), 8))
	var days := HBoxContainer.new()
	days.add_theme_constant_override("separation", 2)
	sv.add_child(days)
	var today := Game.streak_day()
	for i in GameData.STREAK_REWARDS.size():
		var r: Dictionary = GameData.STREAK_REWARDS[i]
		var cell := PanelContainer.new()
		var done: bool = i < today or (i == today and not d.get("reward_pending", false))
		var bg := Color(0.98, 0.88, 0.55) if i == today else (PAPER_DARK if done else Color(0.9, 0.84, 0.7))
		cell.add_theme_stylebox_override("panel", _box(bg, Color(0.85, 0.62, 0.2) if i == today else Color(0.6, 0.47, 0.32), 2 if i == today else 1, 2))
		cell.custom_minimum_size = Vector2(34, 30)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", -2)
		cell.add_child(cv)
		cv.add_child(_ink("Día %d" % (i + 1), 6, INK_SOFT))
		var what := "%d oro" % int(r["gold"])
		if r.has("piece"):
			what = "★ Equipo" if float(r["piece"]) >= 3.0 else "Equipo"
		elif r.has("eter"):
			what = "+ maná"
		cv.add_child(_ink(("✓ " if done else "") + what, 6, GOOD if done else (GOLD if i == today else INK)))
		days.add_child(cell)
	var claim := _button("Recoger recompensa de hoy" if d.get("reward_pending", false) else "Recompensa de hoy recogida",
		d.get("reward_pending", false), func(): Game.claim_streak_reward())
	sv.add_child(claim)
	# ---- quarry of the day
	var prey := _paper()
	prey.custom_minimum_size = Vector2(118, 0)
	top.add_child(prey)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 1)
	prey.add_child(pv)
	pv.add_child(_ink("★ Presa del día", 8, GOLD))
	var pname: String = d.get("prey", "")
	var b := Game.bestiary_entry(pname)
	if not b.is_empty():
		var tex := TextureRect.new()
		var sf := load(b["frames"]) as SpriteFrames
		if sf and sf.has_animation(&"idle_down"):
			tex.texture = sf.get_frame_texture(&"idle_down", 0)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex.custom_minimum_size = Vector2(0, 30)
		pv.add_child(tex)
	pv.add_child(_ink(pname, 8))
	var pl := _ink("Doble de oro y de botín, +renombre. Lleva ★ sobre la cabeza.", 6, INK_SOFT)
	pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pl.custom_minimum_size = Vector2(108, 0)
	pv.add_child(pl)
	# ---- tasks
	var tasks := _paper()
	tasks.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(tasks)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 2)
	tasks.add_child(tv)
	tv.add_child(_ink("Tareas de hoy", 8))
	var list: Array = d.get("tasks", [])
	for i in list.size():
		var t: Dictionary = list[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		tv.add_child(row)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		col.add_child(_ink(t["text"], 7, GOOD if t["claimed"] else INK))
		var pr := HBoxContainer.new()
		pr.add_theme_constant_override("separation", 4)
		pr.add_child(_bar(float(t["p"]) / maxf(1.0, float(t["n"]))))
		pr.add_child(_ink("%d / %d   ·   %d oro, %d renombre" % [int(t["p"]), int(t["n"]), int(t["gold"]), int(t["renown"])], 6, INK_SOFT))
		col.add_child(pr)
		var ready_: bool = not t["claimed"] and int(t["p"]) >= int(t["n"])
		var idx := i
		row.add_child(_button("Cobrada" if t["claimed"] else ("Cobrar" if ready_ else "En curso"), ready_, func(): Game.claim_daily(idx)))
	var bonus := HBoxContainer.new()
	tv.add_child(bonus)
	var bl := _ink("Completa las 3 tareas: Cofre del Gremio (pieza con buenas probabilidades de rareza)", 6, GOLD)
	bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bonus.add_child(bl)
	bonus.add_child(_button("Recogido" if d.get("bonus", false) else "Abrir cofre", Game.daily_bonus_ready(), func(): Game.claim_daily_bonus()))
	# ---- weekly
	var wk: Dictionary = d.get("weekly", {})
	if not wk.is_empty():
		var wrow := HBoxContainer.new()
		wrow.add_theme_constant_override("separation", 6)
		tv.add_child(wrow)
		var wc := VBoxContainer.new()
		wc.add_theme_constant_override("separation", 0)
		wc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wrow.add_child(wc)
		wc.add_child(_ink("Semanal: " + String(wk["text"]), 7, GOOD if wk["claimed"] else Color(0.45, 0.15, 0.7)))
		var wp := HBoxContainer.new()
		wp.add_theme_constant_override("separation", 4)
		wp.add_child(_bar(float(wk["p"]) / maxf(1.0, float(wk["n"]))))
		wp.add_child(_ink("%d / %d   ·   %d oro y una pieza épica o mejor" % [int(wk["p"]), int(wk["n"]), int(wk["gold"])], 6, INK_SOFT))
		wc.add_child(wp)
		var wready: bool = not wk["claimed"] and int(wk["p"]) >= int(wk["n"])
		wrow.add_child(_button("Cobrada" if wk["claimed"] else ("Cobrar" if wready else "En curso"), wready, func(): Game.claim_weekly()))
