extends CanvasLayer
## Bestiary & achievements (B). Bestiary: a page per creature, filled as you hunt it (stars give
## permanent bonuses against it); creatures you have never beaten are silhouettes. Achievements:
## every goal unlocks a title you can wear (it shows in the Guild ranking).

const PAPER := Color(0.93, 0.87, 0.72)
const PAPER_DARK := Color(0.85, 0.77, 0.6)
const INK := Color(0.25, 0.16, 0.1)
const INK_SOFT := Color(0.47, 0.33, 0.22)
const GOLD := Color(0.62, 0.42, 0.08)
const GOOD := Color(0.13, 0.42, 0.14)

var _root: Control
var _page: Control
var _tab := "bestiary"
var _tabs: Array[Button] = []


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
	board.custom_minimum_size = Vector2(450, 250)
	board.size = board.custom_minimum_size
	_root.add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	board.add_child(vb)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 3)
	vb.add_child(head)
	for pair in [["bestiary", "Bestiario"], ["achievements", "Logros y títulos"], ["chronicle", "Crónica"]]:
		var b := Button.new()
		b.text = pair[1]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 8)
		var id: String = pair[0]
		b.pressed.connect(func():
			_tab = id
			_refresh())
		head.add_child(b)
		_tabs.append(b)
	var grow := Control.new()
	grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(grow)
	var close := Button.new()
	close.text = "Cerrar [Esc]"
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 8)
	close.pressed.connect(close_codex)
	head.add_child(close)
	var paper := PanelContainer.new()
	paper.add_theme_stylebox_override("panel", _box(PAPER, Color(0.55, 0.42, 0.28), 1, 4))
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(paper)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	paper.add_child(scroll)
	_page = VBoxContainer.new()
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_page)
	_root.hide()


func _free() -> bool:
	return get_tree().get_first_node_in_group("player") != null and not Game.menu_open and not Game.input_locked and not Game.editing


func _unhandled_input(event: InputEvent) -> void:
	if _root.visible:
		if event.is_action_pressed("codex") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
			get_viewport().set_input_as_handled()
			close_codex()
		return
	if event.is_action_pressed("codex") and _free():
		get_viewport().set_input_as_handled()
		open()


func open() -> void:
	Game.sfx("ui_open", -2.0, 0.0)
	Game.menu_open = true
	get_tree().paused = true
	_root.show()
	_refresh()


func close_codex() -> void:
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


func _refresh() -> void:
	_tabs[0].button_pressed = _tab == "bestiary"
	_tabs[1].button_pressed = _tab == "achievements"
	_tabs[2].button_pressed = _tab == "chronicle"
	for c in _page.get_children():
		c.queue_free()
	if _tab == "bestiary":
		_bestiary()
	elif _tab == "achievements":
		_achievements()
	else:
		_chronicle()


func _bestiary() -> void:
	var found := 0
	for b in GameData.BESTIARY:
		if int(Game.kills.get(b["name"], 0)) > 0:
			found += 1
	_page.add_child(_ink("Criaturas descubiertas: %d / %d   ·   Cada ★ da +%d %% de daño y +%d %% de oro contra esa criatura." % [
		found, GameData.BESTIARY.size(), int(GameData.BESTIARY_DMG * 100), int(GameData.BESTIARY_GOLD * 100)], 7, INK_SOFT))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	_page.add_child(grid)
	for b in GameData.BESTIARY:
		var n: String = b["name"]
		var k := int(Game.kills.get(n, 0))
		var stars := Game.bestiary_stars(n)
		var card := PanelContainer.new()
		var boss: bool = b.get("boss", false)
		card.add_theme_stylebox_override("panel", _box(PAPER_DARK if k > 0 else Color(0.78, 0.72, 0.6), Color(0.75, 0.45, 0.15) if boss else Color(0.6, 0.47, 0.32), 2 if boss else 1, 3))
		card.custom_minimum_size = Vector2(82, 0)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		card.add_child(v)
		var tex := TextureRect.new()
		var sf := load(b["frames"]) as SpriteFrames
		if sf and sf.has_animation(&"idle_down"):
			tex.texture = sf.get_frame_texture(&"idle_down", 0)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex.custom_minimum_size = Vector2(0, 34)
		if k == 0:
			tex.modulate = Color(0.1, 0.07, 0.05, 0.75)   # a silhouette until you beat one
		v.add_child(tex)
		var title := _ink(n if k > 0 else "???", 7, INK)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(title)
		var st := _ink("★".repeat(stars) + "☆".repeat(3 - stars), 9, GOLD)
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(st)
		var nxt := Game.bestiary_next(n)
		var info := ("%d derrotados" % k) + (("  ·  ★ en %d" % nxt) if nxt > 0 else "  ·  completo")
		var il := _ink(info, 6, INK_SOFT)
		il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(il)
		var wl := _ink((b["where"] + ("  (jefe)" if boss else "")) if k > 0 else "Sin descubrir", 6, INK_SOFT)
		wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(wl)
		grid.add_child(card)


func _achievements() -> void:
	var got := Game.titles_unlocked.size()
	_page.add_child(_ink("Logros: %d / %d   ·   Título actual: %s   ·   Haz clic en un logro conseguido para llevar su título." % [
		got, GameData.ACHIEVEMENTS.size(), ("«%s»" % Game.active_title) if Game.active_title != "" else "ninguno"], 7, INK_SOFT))
	for a in GameData.ACHIEVEMENTS:
		var done: bool = Game.titles_unlocked.has(a["id"])
		var active: bool = done and Game.active_title == a["title"]
		var row := Button.new()
		row.focus_mode = Control.FOCUS_NONE
		row.custom_minimum_size = Vector2(0, 22)
		var st := _box(Color(0.98, 0.9, 0.62) if active else (PAPER_DARK if done else Color(0.88, 0.83, 0.72)),
			Color(0.85, 0.62, 0.2) if active else Color(0.62, 0.5, 0.36), 2 if active else 1, 0)
		for k in ["normal", "pressed", "focus", "disabled", "hover"]:
			row.add_theme_stylebox_override(k, st)
		row.disabled = not done
		var id: String = a["id"]
		row.pressed.connect(func():
			Game.set_title(id)
			Game.sfx("ui_open", -4.0, 0.0)
			_refresh())
		var name_ := _ink(("«%s»" % a["title"]) + ("   (en uso)" if active else ""), 8, GOLD if done else INK_SOFT)
		name_.position = Vector2(6, 1)
		name_.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(name_)
		var p := Game.achievement_progress(a)
		var goal := Game.achievement_goal(a)
		var desc := _ink("%s   %s" % [a["desc"], "✓" if done else "%d / %d" % [mini(p, goal), goal]], 6, GOOD if done else INK_SOFT)
		desc.position = Vector2(6, 11)
		desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(desc)
		_page.add_child(row)



## The story so far, chapter by chapter, and the lore of the three Seals.
func _chronicle() -> void:
	_page.add_child(_ink("Crónica del Quinto Viento", 10, GOLD))
	var intro := _ink("Empezaste a cazar cuando otros ya se retiraban. Hace mil años, el Devorador de Eclipses fue encerrado con tres Sellos: Estrella, Luna y Sol. Hoy alguien los está rompiendo... y los Cuatro Vientos, el grupo más fuerte de Valdoria, han decidido que tú los vas a ayudar. Quieras o no.", 7, INK_SOFT)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(420, 0)
	_page.add_child(intro)
	var cur := Game.story_step
	var last_ch := 0
	for i in GameData.STORY.size():
		var st: Dictionary = GameData.STORY[i]
		var ch := int(st["ch"])
		if i > cur:
			if ch != last_ch:
				_page.add_child(_ink("Capítulo %d: ???" % ch, 8, INK_SOFT))
				last_ch = ch
			continue
		if ch != last_ch:
			_page.add_child(_ink("Capítulo %d: %s" % [ch, GameData.STORY_CHAPTERS[ch]], 8, GOLD))
			last_ch = ch
		var done := i < cur
		var txt := String(st["text"]) + ((" (%d/%d)" % [Game.story_prog, int(st["n"])]) if st.has("n") and not done else "")
		var l := _ink(("✓ " if done else "» ") + txt + ((" — " + String(st["done"])) if done and st.has("done") else ""), 7, GOOD if done else INK)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(420, 0)
		_page.add_child(l)
	if Game.story_chapter() >= 8:
		_page.add_child(_ink("La Crónica ha terminado. Los Sellos brillan de nuevo, su poder aparece más a menudo en el equipo... y ahora eres tú quien entrena a los novatos.", 7, GOOD))
	_page.add_child(_ink("Los tres Sellos", 9, GOLD))
	for tier in [4, 5, 6]:
		var sd: Dictionary = GameData.SEALS[tier]
		var row := _ink("%s (%s) — %s: %s." % [sd["name"], sd["short"], sd["power"], sd["power_text"]], 7, GameData.RARITY_INK[tier])
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.custom_minimum_size = Vector2(420, 0)
		_page.add_child(row)
	_page.add_child(_ink("Rareza: Común < Rara < Épica < Legendaria < SOS < SOM < SOSUN. Has encontrado %d piezas de Sello." % int(Game.stats.get("seals", 0)), 7, INK_SOFT))
