extends Node2D
## Badge over important characters and places: an icon on a round plate and what they do
## ("Herrera", "Establo"...). Same icons as on the minimap.

var kind := "forge"
var _icon: Texture2D
var _title := ""
var _t := 0.0


func _ready() -> void:
	z_index = 9
	var d: Dictionary = GameData.POI.get(kind, {})
	_icon = Game.icon_texture(d.get("icon", [16, 16]))
	_title = d.get("title", "")
	_t = randf() * TAU


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var bob := roundf(sin(_t * 2.2) * 1.0)
	var c := Vector2(0, bob)
	draw_circle(c, 8.5, Color(0.2, 0.12, 0.06, 0.9))
	draw_circle(c, 7.5, Color(0.96, 0.88, 0.66))
	draw_texture_rect(_icon, Rect2(c - Vector2(6, 6), Vector2(12, 12)), false)
	if _title != "":
		var f := ThemeDB.fallback_font
		var w := f.get_string_size(_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
		var p := Vector2(-w / 2.0, 15 + bob)
		draw_string_outline(f, p, _title, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, 3, Color(0.1, 0.06, 0.03, 0.9))
		draw_string(f, p, _title, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(1, 0.88, 0.5))
