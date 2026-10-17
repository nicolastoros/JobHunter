extends Node2D
## World-space overlay of the map editor: grid, hover cell, brush preview, placement ghost and selection.

var editor: Node

const GRID_COLOR := Color(1, 1, 1, 0.09)
const GRID_MAJOR := Color(1, 1, 1, 0.18)
const SEL_COLOR := Color(0.35, 0.85, 1.0, 0.95)
const FOOT_COLOR := Color(0.2, 1.0, 0.6, 0.8)


func _ready() -> void:
	z_index = 4000
	z_as_relative = false


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if editor == null:
		return
	var view: Rect2 = editor.visible_world_rect()
	var zoom: float = editor.cam.zoom.x
	var lw := 1.0 / zoom
	if editor.show_grid:
		var x0 := int(floor(view.position.x / 16.0))
		var x1 := int(ceil(view.end.x / 16.0))
		var y0 := int(floor(view.position.y / 16.0))
		var y1 := int(ceil(view.end.y / 16.0))
		for x in range(x0, x1 + 1):
			draw_line(Vector2(x * 16, view.position.y), Vector2(x * 16, view.end.y), GRID_MAJOR if x % 8 == 0 else GRID_COLOR, lw)
		for y in range(y0, y1 + 1):
			draw_line(Vector2(view.position.x, y * 16), Vector2(view.end.x, y * 16), GRID_MAJOR if y % 8 == 0 else GRID_COLOR, lw)
	var m: Vector2 = get_global_mouse_position()
	var tool: String = editor.tool
	if editor.mouse_over_world:
		if tool in ["paint", "terrain", "erase"]:
			var c := Vector2i(floor(m.x / 16.0), floor(m.y / 16.0))
			var col := Color(1, 0.85, 0.3, 0.9) if tool != "erase" else Color(1, 0.35, 0.3, 0.9)
			if tool == "paint":
				# preview the whole stamp block a click here would paint
				var ps: Vector2i = editor.paint_size
				var o: Vector2i = editor.stamp_origin_for(c) if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else c
				if editor.paint_texture:
					draw_texture_rect_region(editor.paint_texture, Rect2(Vector2(o) * 16, Vector2(ps) * 16),
						Rect2(Vector2(editor.paint_coords) * 16, Vector2(ps) * 16), Color(1, 1, 1, 0.65))
				draw_rect(Rect2(Vector2(o) * 16, Vector2(ps) * 16), col, false, 2.0 * lw)
			else:
				var size: int = editor.brush_size
				var off := (size - 1) / 2
				draw_rect(Rect2(Vector2(c - Vector2i(off, off)) * 16, Vector2(size, size) * 16), col, false, 2.0 * lw)
		elif tool == "object" and editor.place_item:
			editor.draw_ghost(self, editor.snapped_mouse())
	var sel: Node2D = editor.selected
	if sel and is_instance_valid(sel) and sel.is_inside_tree():
		var r: Rect2 = editor.node_rect(sel)
		draw_rect(r.grow(1.0), SEL_COLOR, false, 2.0 * lw)
		draw_circle(sel.global_position, 2.5 * lw * 2.0, SEL_COLOR)
		for cs in sel.find_children("*", "CollisionShape2D", false, false):
			var s := cs as CollisionShape2D
			if s.shape is RectangleShape2D:
				var sz: Vector2 = (s.shape as RectangleShape2D).size
				draw_rect(Rect2(s.global_position - sz / 2.0, sz), FOOT_COLOR, false, 1.5 * lw)
	var hov: Node2D = editor.hovered
	if hov and hov != sel and is_instance_valid(hov) and tool == "select":
		draw_rect(editor.node_rect(hov), Color(1, 1, 1, 0.45), false, 1.0 * lw)
