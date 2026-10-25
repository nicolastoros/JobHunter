extends Node2D
## A column of light where an epic or legendary piece dropped: rises, shimmers and fades in ~2.5 s.

var color := Color(1, 0.66, 0.15)
var _t := 0.0
const LIFE := 2.6


func _ready() -> void:
	z_index = 3


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var grow := minf(_t / 0.25, 1.0)
	var fade := 1.0 - maxf(0.0, (_t - LIFE * 0.6) / (LIFE * 0.4))
	var h := 90.0 * grow
	var pulse := 0.85 + 0.15 * sin(_t * 12.0)
	for i in 4:
		var w := (10.0 - i * 2.5) * pulse
		var c := color
		c.a = (0.16 + i * 0.12) * fade
		draw_rect(Rect2(-w / 2.0, -h, w, h), c)
	var glow := color
	glow.a = 0.35 * fade
	draw_circle(Vector2.ZERO, 9.0 * pulse, glow)
	# little sparks climbing the beam
	for i in 5:
		var y := -fmod(_t * 40.0 + i * 19.0, h)
		var x := sin(_t * 6.0 + i * 1.7) * 4.0
		var s := color.lightened(0.5)
		s.a = fade
		draw_rect(Rect2(x - 1, y - 1, 2, 2), s)
