extends Node2D
## A swirling portal. mode "enter": the door to a dungeon out in the world (E opens its panel).
## mode "exit": inside a dungeon, takes you back.

@export var dungeon_id := ""
@export var mode := "enter"
@export var label := ""
var color := Color(0.7, 0.5, 1.0)
var _t := 0.0


func _ready() -> void:
	z_index = 0
	if mode == "enter":
		var d := Game.dungeon_def(dungeon_id)
		color = d.get("color", color)
		label = d.get("name", "")
		add_to_group("poi")
		set_meta("poi_kind", "dungeon")
		add_to_group("dungeon_portals")


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var locked := mode == "enter" and Game.dungeon_block_reason(dungeon_id, false) != ""
	var c := color.darkened(0.55) if locked else color
	# stone ring
	draw_set_transform(Vector2(0, -2), 0.0, Vector2(1, 0.55))
	draw_circle(Vector2.ZERO, 17.0, Color(0.18, 0.15, 0.2))
	draw_circle(Vector2.ZERO, 14.0, Color(0.06, 0.04, 0.09))
	# the swirl
	for i in 3:
		var r := 12.0 - i * 3.5
		var a0 := _t * (2.5 + i) + i
		draw_arc(Vector2.ZERO, r, a0, a0 + 4.2, 18, Color(c.lightened(i * 0.2), 0.85 - i * 0.15), 2.0)
	draw_circle(Vector2.ZERO, 3.0 + sin(_t * 4.0), Color(c.lightened(0.6), 0.9))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# motes rising
	for i in 5:
		var y := -fmod(_t * 18.0 + i * 9.0, 40.0)
		var x := sin(_t * 2.0 + i * 1.3) * 9.0
		draw_rect(Rect2(x, y - 4, 2, 2), Color(c.lightened(0.4), 1.0 + y / 40.0))
	if label != "":
		var f := ThemeDB.fallback_font
		var w := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
		draw_string_outline(f, Vector2(-w / 2.0, -26), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, 3, Color(0.06, 0.04, 0.08))
		draw_string(f, Vector2(-w / 2.0, -26), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, c.lightened(0.3))


func set_focused(value: bool) -> void:
	$Prompt.visible = value


func interact(_player: Node) -> void:
	if mode == "exit":
		Game.leave_dungeon()
		return
	if mode == "next":
		Game.tower_next()
		return
	Game.dungeon_menu_requested.emit(dungeon_id)
