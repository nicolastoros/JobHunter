extends CanvasLayer
## On-screen controls for phones and tablets (only shown on touch screens):
##  - floating joystick on the left half (push it to the edge to run),
##  - Attack and Talk buttons on the right,
##  - the HUD action bar becomes tappable (potion and skills 1-6),
##  - Menu, Map and Pause buttons under the portrait.

const DEAD := 0.22
const RUN_AT := 0.92
const JOY_R := 30.0

## Set to true to show the controls on a desktop (testing).
static var force := false

var _root: Control
var _joy_index := -1
var _joy_origin := Vector2.ZERO
var _joy_vec := Vector2.ZERO
var _pressed := {}          # touch index -> button id
var _flash := {}            # button id -> time left (pressed look)
var _icons := {}
var _font: Font


func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not (force or DisplayServer.is_touchscreen_available()):
		queue_free()
		return
	# taps must not count as sword swings through the emulated mouse click
	for ev in InputMap.action_get_events("attack"):
		if ev is InputEventMouseButton:
			InputMap.action_erase_event("attack", ev)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.draw.connect(_draw_controls)
	add_child(_root)
	_font = ThemeDB.fallback_font
	_icons["attack"] = Game.icon_texture([0, 128])
	var hint := get_parent().get_node_or_null("ControlsHint")
	if hint:
		hint.visible = false


func _vp() -> Vector2:
	return _root.get_viewport_rect().size


func _buttons() -> Dictionary:
	var v := _vp()
	var b := {
		"attack": [Vector2(v.x - 38, v.y - 46), 21.0],
		"interact": [Vector2(v.x - 84, v.y - 26), 14.0],
		"menu": [Vector2(18, 64), 11.0],
		"map": [Vector2(44, 64), 11.0],
		"pause": [Vector2(70, 64), 11.0],
	}
	return b


func _gameplay_locked() -> bool:
	if Game.menu_open or Game.editing or get_tree().paused:
		return true
	# boards and the forge lock input too; only a dialogue keeps the Talk/Attack buttons
	return Game.input_locked and not _dialogue_open()


func _dialogue_open() -> bool:
	var d := get_parent().get_node_or_null("DialogueBox") as Control
	return d != null and d.visible


func _process(delta: float) -> void:
	for k in _flash.keys():
		_flash[k] -= delta
		if _flash[k] <= 0.0:
			_flash.erase(k)
	if _gameplay_locked() and _joy_index != -1:
		_release_joy()
	_root.queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_on_press(t.index, t.position)
		else:
			_on_release(t.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _joy_index:
			_joy_vec = (d.position - _joy_origin) / JOY_R
			if _joy_vec.length() > 1.0:
				_joy_vec = _joy_vec.normalized()
			_apply_joy()


func _on_press(index: int, pos: Vector2) -> void:
	if _gameplay_locked():
		return
	var btns := _buttons()
	for id in btns:
		if pos.distance_to(btns[id][0]) <= float(btns[id][1]) + 6.0:
			if Game.input_locked and not id in ["attack", "interact"]:
				return
			_pressed[index] = id
			_flash[id] = 0.15
			_fire(id)
			get_viewport().set_input_as_handled()
			return
	var slot := _bar_slot(pos)
	if slot >= 0:
		_flash["slot%d" % slot] = 0.15
		_fire(["attack", "use_potion", "skill_1", "skill_2", "skill_3", "skill_4", "skill_5", "skill_6"][slot])
		get_viewport().set_input_as_handled()
		return
	if pos.x < _vp().x * 0.45 and _joy_index == -1 and not Game.input_locked:
		_joy_index = index
		_joy_origin = pos
		_joy_vec = Vector2.ZERO
		get_viewport().set_input_as_handled()


func _on_release(index: int) -> void:
	if index == _joy_index:
		_release_joy()
	_pressed.erase(index)


## Index of the action-bar slot under `pos` (0 sword, 1 potion, 2-7 skills) or -1.
func _bar_slot(pos: Vector2) -> int:
	var hud := get_parent().get_node_or_null("PlayerHud")
	if hud == null or hud.get("action_bar") == null:
		return -1
	var bar: Control = hud.get("action_bar")
	var r := bar.get_global_rect().grow(3)
	if not r.has_point(pos):
		return -1
	var k := int((pos.x - r.position.x - 3.0) / 16.0)
	return k if k >= 0 and k <= 7 else -1


func _fire(action: String) -> void:
	var a: String = {"menu": "character", "map": "map", "pause": "pause"}.get(action, action)
	var e := InputEventAction.new()
	e.action = a
	e.pressed = true
	Input.parse_input_event(e)
	var r := InputEventAction.new()
	r.action = a
	r.pressed = false
	Input.parse_input_event.call_deferred(r)


func _apply_joy() -> void:
	var v := _joy_vec if _joy_vec.length() >= DEAD else Vector2.ZERO
	_set_axis("move_left", "move_right", v.x)
	_set_axis("move_up", "move_down", v.y)
	if v.length() >= RUN_AT:
		Input.action_press("run")
	else:
		Input.action_release("run")


func _set_axis(neg: String, pos: String, x: float) -> void:
	if x < 0.0:
		Input.action_press(neg, -x)
		Input.action_release(pos)
	elif x > 0.0:
		Input.action_press(pos, x)
		Input.action_release(neg)
	else:
		Input.action_release(neg)
		Input.action_release(pos)


func _release_joy() -> void:
	_joy_index = -1
	_joy_vec = Vector2.ZERO
	_apply_joy()


# --- drawing ------------------------------------------------------------------------------

func _draw_controls() -> void:
	if _gameplay_locked():
		return
	var btns := _buttons()
	var locked := Game.input_locked
	# joystick
	if not locked:
		var base := _joy_origin if _joy_index != -1 else Vector2(56, _vp().y - 58)
		var alpha := 0.55 if _joy_index != -1 else 0.25
		_root.draw_circle(base, JOY_R, Color(0.1, 0.07, 0.05, alpha * 0.8))
		_root.draw_arc(base, JOY_R, 0, TAU, 32, Color(0.95, 0.85, 0.6, alpha), 1.5)
		var knob := base + _joy_vec * JOY_R
		_root.draw_circle(knob, 11.0, Color(0.95, 0.85, 0.6, alpha + 0.2))
		if _joy_vec.length() >= RUN_AT:
			_text(base + Vector2(0, JOY_R + 9), "Corriendo", 6, Color(1, 0.8, 0.4, 0.9))
	for id in btns:
		if locked and not id in ["attack", "interact"]:
			continue
		var c: Vector2 = btns[id][0]
		var r: float = btns[id][1]
		var hot := _flash.has(id)
		_root.draw_circle(c, r, Color(0.16, 0.1, 0.06, 0.8 if hot else 0.55))
		_root.draw_arc(c, r, 0, TAU, 28, Color(1, 0.86, 0.45, 0.95 if hot else 0.6), 1.5)
		match id:
			"attack":
				_root.draw_texture_rect(_icons["attack"], Rect2(c - Vector2(10, 10), Vector2(20, 20)), false)
			"interact":
				_text(c + Vector2(0, 3), "E", 10, Color(1, 0.92, 0.7))
			"menu":
				_text(c + Vector2(0, 2), "Menú", 5, Color(1, 0.92, 0.7))
			"map":
				_text(c + Vector2(0, 2), "Mapa", 5, Color(1, 0.92, 0.7))
			"pause":
				_text(c + Vector2(0, 2), "II", 7, Color(1, 0.92, 0.7))
	for k in _flash:
		if String(k).begins_with("slot"):
			var hud := get_parent().get_node_or_null("PlayerHud")
			if hud and hud.get("action_bar"):
				var r: Rect2 = (hud.get("action_bar") as Control).get_global_rect()
				var i := int(String(k).substr(4))
				_root.draw_rect(Rect2(r.position + Vector2(3 + 16 * i, 2), Vector2(16, 16)), Color(1, 0.9, 0.5, 0.45))


func _text(center: Vector2, s: String, size: int, col: Color) -> void:
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_root.draw_string_outline(_font, center - Vector2(w / 2.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color(0.08, 0.05, 0.03))
	_root.draw_string(_font, center - Vector2(w / 2.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
