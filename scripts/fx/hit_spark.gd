extends Node2D
## Impact flash where a blow lands: a bright core, sharp rays and an expanding ring (~0.18 s).
## Criticals are bigger and golden.

var crit := false
var _t := 0.0
var _rays: Array[Vector2] = []
const LIFE := 0.18


func _ready() -> void:
	z_index = 4
	rotation = randf() * TAU
	for i in (9 if crit else 6):
		var a := i * TAU / (9.0 if crit else 6.0) + randf_range(-0.25, 0.25)
		_rays.append(Vector2(cos(a), sin(a)) * randf_range(0.7, 1.0))


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / LIFE
	var size := (16.0 if crit else 11.0) * (0.6 + 0.6 * k)
	var a := 1.0 - k
	var core := Color(1, 1, 1, a) if not crit else Color(1, 0.95, 0.6, a)
	var edge := Color(1, 0.85, 0.45, a) if not crit else Color(1, 0.5, 0.15, a)
	draw_circle(Vector2.ZERO, size * 0.35 * (1.0 - k * 0.6), core)
	for r in _rays:
		var tip := r * size
		var side := Vector2(-r.y, r.x) * 1.6 * (1.0 - k)
		draw_colored_polygon(PackedVector2Array([side, tip, -side]), edge)
	draw_arc(Vector2.ZERO, size * (0.5 + k * 0.7), 0.0, TAU, 20, Color(core, a * 0.7), 1.0)
