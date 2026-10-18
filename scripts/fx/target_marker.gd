extends Node2D
## Marks the monster the hero has locked on (Tab): a pulsing ring at its feet and an arrow above it.

var _t := 0.0


func _ready() -> void:
	z_index = 55
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _process(delta: float) -> void:
	_t += delta
	var tg := Game.target
	visible = tg != null and is_instance_valid(tg)
	if visible:
		global_position = tg.global_position
	queue_redraw()


func _draw() -> void:
	var tg := Game.target
	if tg == null or not is_instance_valid(tg):
		return
	var big: bool = tg.get("boss") == true
	var r := (14.0 if big else 9.0) + sin(_t * 6.0) * 1.2
	var col := Color(1, 0.3, 0.2, 0.9)
	draw_arc(Vector2(0, -1), r, 0, TAU, 28, Color(0, 0, 0, 0.5), 3.0)
	draw_arc(Vector2(0, -1), r, 0, TAU, 28, col, 1.5)
	# four ticks rotating around the ring
	for i in 4:
		var a := _t * 1.5 + i * PI / 2.0
		var dir := Vector2(cos(a), sin(a) * 0.5)
		draw_line(dir * (r - 2.0), dir * (r + 3.0), Color(1, 0.85, 0.4), 1.5)
	var top := float(tg.get("sprite_offset_y")) * 2.0 - 12.0 + sin(_t * 5.0) * 1.5
	draw_colored_polygon(PackedVector2Array([Vector2(-4, top - 5), Vector2(4, top - 5), Vector2(0, top)]), col)
	draw_polyline(PackedVector2Array([Vector2(-4, top - 5), Vector2(4, top - 5), Vector2(0, top), Vector2(-4, top - 5)]), Color(0.15, 0.05, 0.03), 1.0)
