extends Node2D
## Floating text that rises and fades (damage numbers, gold).

var text := ""
var color := Color.WHITE
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	position.y -= 18.0 * delta
	modulate.a = clampf(1.4 - _t * 1.4, 0.0, 1.0)
	queue_redraw()
	if _t > 1.0:
		queue_free()


func _draw() -> void:
	var f := ThemeDB.fallback_font
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	draw_string_outline(f, Vector2(-w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color(0.08, 0.05, 0.04))
	draw_string(f, Vector2(-w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
