class_name SpeechBubble
extends Node2D
## Small, subtle speech bubble that floats above a character's head.

const FONT_SIZE := 7
const MAX_TEXT_WIDTH := 96.0
const PAD := Vector2(4, 2)
const LINE_H := 8.0
const MAX_ACTIVE := 5
const BG := Color(1.0, 0.97, 0.88, 0.94)
const BORDER := Color(0.35, 0.25, 0.18, 0.85)
const TEXT := Color(0.22, 0.15, 0.1)

static var active_count := 0
static var _active: Array = []

var _lines: PackedStringArray = []
var _lift := 0.0
var _size := Vector2.ZERO
var _tween: Tween
var _showing := false
var _font: Font


func _ready() -> void:
	z_index = 60
	_font = ThemeDB.fallback_font
	modulate.a = 0.0
	visible = false


## Shows a line; returns false when too many bubbles are already on screen.
func say(text: String, duration := 3.2, force := false) -> bool:
	if _showing or (not force and active_count >= MAX_ACTIVE):
		return false
	_showing = true
	active_count += 1
	_lines = _wrap(text)
	var w := 0.0
	for l in _lines:
		w = maxf(w, _font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x)
	_size = Vector2(ceilf(w) + PAD.x * 2.0, _lines.size() * LINE_H + PAD.y * 2.0)
	# keep clear of other bubbles: lift this one above any it would cover, or give up
	_lift = 0.0
	var placed := false
	for attempt in 4:
		if not _overlaps_others():
			placed = true
			break
		_lift += _size.y + 3.0
	if not placed:
		_showing = false
		active_count = maxi(active_count - 1, 0)
		return false
	_active.append(self)
	visible = true
	queue_redraw()
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.25)
	_tween.tween_interval(duration)
	_tween.tween_property(self, "modulate:a", 0.0, 0.45)
	_tween.tween_callback(_done)
	return true


## Bubble rectangle in global (world) coordinates.
func global_rect() -> Rect2:
	var r := Rect2(Vector2(-roundf(_size.x * 0.5), -_size.y - 3.0 - _lift), _size)
	return Rect2(global_position + r.position, r.size).grow(2.0)


func _overlaps_others() -> bool:
	var mine := global_rect()
	for b in _active:
		if b != self and is_instance_valid(b) and b._showing and b.global_rect().intersects(mine):
			return true
	return false


func hide_now() -> void:
	if _showing:
		if _tween:
			_tween.kill()
		_done()


func _wrap(text: String) -> PackedStringArray:
	var out := PackedStringArray()
	var cur := ""
	for word in text.split(" "):
		var test := word if cur == "" else cur + " " + word
		if cur != "" and _font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x > MAX_TEXT_WIDTH:
			out.append(cur)
			cur = word
		else:
			cur = test
	if cur != "":
		out.append(cur)
	return out


func _draw() -> void:
	if not _showing:
		return
	var r := Rect2(Vector2(-roundf(_size.x * 0.5), -_size.y - 3.0 - _lift), _size)
	draw_rect(r, BG)
	draw_rect(r, BORDER, false, 1.0)
	if _lift == 0.0:
		draw_colored_polygon(PackedVector2Array([Vector2(-3, -3.5), Vector2(3, -3.5), Vector2(0, 0)]), BG)
		draw_line(Vector2(-3, -3), Vector2(0, 0), BORDER)
		draw_line(Vector2(3, -3), Vector2(0, 0), BORDER)
	else:
		draw_line(Vector2(0, r.end.y), Vector2(0, 0), BORDER)
	var y := r.position.y + PAD.y + FONT_SIZE
	for l in _lines:
		draw_string(_font, Vector2(r.position.x + PAD.x, y), l, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT)
		y += LINE_H


func _done() -> void:
	_active.erase(self)
	visible = false
	modulate.a = 0.0
	if _showing:
		_showing = false
		active_count = maxi(active_count - 1, 0)


func _exit_tree() -> void:
	_active.erase(self)
	if _showing:
		_showing = false
		active_count = maxi(active_count - 1, 0)
