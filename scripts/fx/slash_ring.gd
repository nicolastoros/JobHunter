extends Node2D
## Short sweeping arc drawn around the player for the spin attack.

var radius := 46.0
var _t := 0.0
const LIFE := 0.28


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
	var a0 := -PI / 2.0 + k * TAU * 1.1
	var r := radius * (0.55 + 0.45 * k)
	var col := Color(1, 0.97, 0.85, 0.85 * (1.0 - k))
	draw_arc(Vector2.ZERO, r, a0 - 2.4, a0, 24, col, 3.0)
	draw_arc(Vector2.ZERO, r - 4.0, a0 - 1.6, a0, 16, Color(0.75, 0.9, 1, 0.6 * (1.0 - k)), 1.5)
