extends Node2D
## A summoning circle: opens, spins its runes and flashes when the monster steps out (~1 s).

var color := Color(0.7, 0.5, 1.0)
var big := false
var _t := 0.0
const LIFE := 1.05


func _ready() -> void:
	z_index = -1


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var r := (26.0 if big else 14.0) * minf(_t / 0.35, 1.0)
	var a := 1.0 if _t < 0.8 else 1.0 - (_t - 0.8) / (LIFE - 0.8)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.5))
	draw_circle(Vector2.ZERO, r, Color(color, 0.25 * a))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(color, 0.9 * a), 1.5)
	draw_arc(Vector2.ZERO, r * 0.7, 0.0, TAU, 24, Color(color.lightened(0.3), 0.7 * a), 1.0)
	for i in 6:
		var ang := _t * 3.0 + i * TAU / 6.0
		var p := Vector2(cos(ang), sin(ang)) * r * 0.85
		draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), Color(1, 1, 1, a))
	if _t > 0.7:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var f := 1.0 - (_t - 0.7) / (LIFE - 0.7)
		draw_rect(Rect2(-r * 0.3, -40, r * 0.6, 40), Color(color.lightened(0.5), 0.5 * f))
