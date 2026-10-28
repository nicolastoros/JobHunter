extends Node2D
## Floating text. Two styles:
##  - "text": rises and fades (gold, item names, messages).
##  - "dmg" / "crit": damage skin. The number jumps out of the monster in a small arc, pops big and
##    settles, with a thick outline and a two-tone fill; criticals are larger, golden-red, with a star.

var text := ""
var color := Color.WHITE
var size := 8
var kind := "text"
var _t := 0.0
var _vel := Vector2.ZERO
var _life := 1.0


func _ready() -> void:
	if kind != "text":
		_vel = Vector2(randf_range(-38.0, 38.0), -95.0 if kind == "dmg" else -120.0)
		_life = 0.75 if kind == "dmg" else 1.05


func _process(delta: float) -> void:
	_t += delta
	if kind == "text":
		position.y -= 18.0 * delta
		modulate.a = clampf(1.4 - _t * 1.4, 0.0, 1.0)
	else:
		position += _vel * delta
		_vel.y += 260.0 * delta          # the arc
		_vel.x *= 1.0 - 2.0 * delta
		modulate.a = clampf((_life - _t) / 0.25, 0.0, 1.0)
	queue_redraw()
	if _t > _life:
		queue_free()


func _draw() -> void:
	var f := ThemeDB.fallback_font
	if kind == "text":
		if size > 8:
			var s0 := 1.0 + 0.6 * maxf(0.0, 1.0 - _t / 0.12)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(s0, s0))
		var w0 := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string_outline(f, Vector2(-w0 / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color(0.08, 0.05, 0.04))
		draw_string(f, Vector2(-w0 / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
		return
	var crit := kind == "crit"
	# pop: starts big, overshoots a little smaller, settles
	var p := _t / 0.16
	var s := 1.0
	if p < 1.0:
		s = lerpf(2.1 if crit else 1.7, 0.9, p)
	elif p < 1.6:
		s = lerpf(0.9, 1.0, (p - 1.0) / 0.6)
	draw_set_transform(Vector2.ZERO, randf_range(-0.04, 0.04) if crit and _t < 0.2 else 0.0, Vector2(s, s))
	var fs := size
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var at := Vector2(-w / 2.0, 0)
	if crit:
		_star(Vector2(0, -fs * 0.35), fs * 0.95, Color(1, 0.55, 0.1, 0.55 * modulate.a))
	var top := Color(1, 1, 1) if not crit else Color(1, 0.95, 0.45)
	var bottom := color if not crit else Color(1, 0.35, 0.12)
	draw_string_outline(f, at + Vector2(1, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0, 0, 0, 0.45))   # drop shadow
	draw_string_outline(f, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0.12, 0.04, 0.03))
	draw_string(f, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, bottom)
	# highlight: the same glyphs one pixel up in the lighter tone, half transparent
	draw_string(f, at + Vector2(0, -1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(top, 0.55))


func _star(center: Vector2, radius: float, c: Color) -> void:
	var pts := PackedVector2Array()
	var spin := _t * 3.0
	for i in 16:
		var a := spin + i * TAU / 16.0
		var r := radius if i % 2 == 0 else radius * 0.45
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, c)
