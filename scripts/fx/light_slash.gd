extends Node2D
## Straight blade of light for "Tajo de luz": shoots out in a direction and fades.

var dir := Vector2.RIGHT
var length := 130.0
var _t := 0.0
const LIFE := 0.32


func _ready() -> void:
	z_index = 60


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / LIFE
	var reach := length * minf(1.0, k * 2.5)
	var side := Vector2(-dir.y, dir.x)
	var a := 1.0 - k
	var tip := dir * reach
	draw_colored_polygon(PackedVector2Array([side * 7.0, tip, -side * 7.0]), Color(1, 0.95, 0.7, 0.45 * a))
	draw_line(Vector2.ZERO, tip, Color(1, 1, 0.9, 0.95 * a), 3.0)
	draw_line(side * 3.0, tip * 0.9, Color(0.7, 0.9, 1, 0.6 * a), 1.0)
	draw_line(-side * 3.0, tip * 0.9, Color(0.7, 0.9, 1, 0.6 * a), 1.0)
