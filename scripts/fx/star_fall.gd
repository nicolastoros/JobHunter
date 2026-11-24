extends Node2D
## Star seal: a star drops from the sky onto the enemy and bursts in a ring of light (~0.7 s).

var _t := 0.0
const FALL := 0.35
const LIFE := 0.75


func _ready() -> void:
	z_index = 6


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var c := Color(0.6, 0.88, 1.0)
	if _t < FALL:
		var k := _t / FALL
		var p := Vector2(-40.0, -160.0).lerp(Vector2(0, -8), k)
		draw_line(p + Vector2(-20, -60) * (1.0 - k * 0.5) * 0.4, p, Color(c, 0.5), 3.0)
		_star(p, 6.0, Color(1, 1, 1))
		_star(p, 4.0, c)
		return
	var b := (_t - FALL) / (LIFE - FALL)
	var a := 1.0 - b
	draw_circle(Vector2(0, -6), 10.0 * (1.0 - b), Color(1, 1, 1, a))
	draw_arc(Vector2(0, -6), 8.0 + 40.0 * b, 0.0, TAU, 32, Color(c, a), 2.0)
	for i in 8:
		var d := Vector2.RIGHT.rotated(i * TAU / 8.0)
		draw_line(Vector2(0, -6) + d * (6.0 + 30.0 * b), Vector2(0, -6) + d * (12.0 + 38.0 * b), Color(1, 1, 1, a), 1.5)


func _star(at: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI / 2.0 + i * TAU / 10.0
		pts.append(at + Vector2(cos(ang), sin(ang)) * (r if i % 2 == 0 else r * 0.45))
	draw_colored_polygon(pts, col)
