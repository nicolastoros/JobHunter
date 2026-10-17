extends Node2D
## Small bobbing "E" bubble drawn above an NPC the player can talk to.

@export var key_text := "E"

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var bob := roundf(sin(_t * 5.0) * 1.0)
	var r := Rect2(-5, -10 + bob, 10, 10)
	draw_rect(r, Color(0.12, 0.08, 0.07, 0.92))
	draw_rect(r, Color(0.85, 0.64, 0.25), false, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-2, bob), Vector2(2, bob), Vector2(0, 3 + bob)]), Color(0.85, 0.64, 0.25))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-5, -2 + bob), key_text, HORIZONTAL_ALIGNMENT_CENTER, 10, 8, Color(1, 0.95, 0.8))
