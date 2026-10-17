extends Control
## Talent tree view: three branches side by side, five tiers each. Nodes are buttons with the
## talent icon and its rank; lines join each node to the ones it requires.

signal node_selected(id: String)

const NODE := 24.0
const BRANCH_W := 95.0
const TIER_Y := 31.0
const TOP := 14.0

var selected := ""
var _buttons := {}
var _ranks := {}


func _ready() -> void:
	custom_minimum_size = Vector2(BRANCH_W * 3, TOP + TIER_Y * 4 + NODE + 4)
	for n in GameData.TALENT_TREE:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.position = node_pos(n) - Vector2(NODE, NODE) / 2.0
		b.size = Vector2(NODE, NODE)
		b.tooltip_text = n["name"]
		var ic := TextureRect.new()
		ic.texture = load(GameData.TI + n["id"] + ".png")
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.position = Vector2(2, 2)
		ic.size = Vector2(NODE - 4, NODE - 4)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.name = "Icon"
		b.add_child(ic)
		var r := Label.new()
		r.add_theme_font_size_override("font_size", 6)
		r.add_theme_color_override("font_color", Color(1, 0.96, 0.85))
		r.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.04))
		r.add_theme_constant_override("outline_size", 3)
		r.position = Vector2(NODE - 12, NODE - 9)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.name = "Rank"
		b.add_child(r)
		var id: String = n["id"]
		b.pressed.connect(func():
			selected = id
			refresh()
			node_selected.emit(id))
		add_child(b)
		_buttons[id] = b
	refresh()


func node_pos(n: Dictionary) -> Vector2:
	return Vector2(int(n["branch"]) * BRANCH_W + 22.0 + int(n["col"]) * 28.0, TOP + 12.0 + int(n["tier"]) * TIER_Y)


func _box(bg: Color, border: Color, width := 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.anti_aliasing = false
	return s


func refresh() -> void:
	for n in GameData.TALENT_TREE:
		var id: String = n["id"]
		var b: Button = _buttons[id]
		var rank := Game.talent_rank(id)
		var mx := int(n["max"])
		var why := Game.talent_block_reason(id)
		var bc: Color = GameData.BRANCHES[int(n["branch"])]["color"]
		var bg := Color(0.3, 0.22, 0.16)
		var border := Color(0.45, 0.36, 0.28)
		var icon_mod := Color(0.45, 0.45, 0.45, 0.85)
		if rank >= mx:
			bg = bc.darkened(0.35); border = Color(1, 0.85, 0.4); icon_mod = Color.WHITE
		elif rank > 0:
			bg = bc.darkened(0.5); border = bc.lightened(0.35); icon_mod = Color.WHITE
		elif why == "" or why == "No tienes puntos de talento.":
			bg = Color(0.36, 0.28, 0.2); border = Color(0.9, 0.78, 0.45); icon_mod = Color(0.9, 0.9, 0.9)
		var st := _box(bg, border, 2 if id == selected else 1)
		if id == selected:
			st.border_color = Color(1, 1, 0.8)
		for k in ["normal", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(k, st)
		b.add_theme_stylebox_override("hover", _box(bg.lightened(0.12), border.lightened(0.2), 2))
		(b.get_node("Icon") as TextureRect).modulate = icon_mod
		(b.get_node("Rank") as Label).text = "%d/%d" % [rank, mx] if rank > 0 else ""
		_ranks[id] = rank
	queue_redraw()


func _draw() -> void:
	# branch columns and titles
	for i in GameData.BRANCHES.size():
		var br: Dictionary = GameData.BRANCHES[i]
		var c: Color = br["color"]
		draw_rect(Rect2(i * BRANCH_W + 3, 0, BRANCH_W - 6, size.y), Color(c.r, c.g, c.b, 0.1))
		draw_rect(Rect2(i * BRANCH_W + 3, 0, BRANCH_W - 6, 11), Color(c.r, c.g, c.b, 0.55))
		var f := get_theme_default_font()
		var title: String = br["name"]
		var tw := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		draw_string(f, Vector2(i * BRANCH_W + (BRANCH_W - tw) / 2.0, 8.5), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 0.96, 0.88))
		# tier unlock marks
		for t in range(1, 5):
			var need: int = GameData.TIER_POINTS[t]
			var open := Game.branch_points(i) >= need
			var y := TOP + 12.0 + t * TIER_Y
			draw_string(f, Vector2(i * BRANCH_W + 5, y + 3), str(need), HORIZONTAL_ALIGNMENT_LEFT, -1, 6,
				Color(0.35, 0.6, 0.25) if open else Color(0.55, 0.45, 0.38, 0.8))
	# links
	for n in GameData.TALENT_TREE:
		for r in n["req"]:
			var p := GameData.talent_node(r)
			var a := node_pos(p)
			var b := node_pos(n)
			var on: bool = int(_ranks.get(r, 0)) > 0
			var c: Color = GameData.BRANCHES[int(n["branch"])]["color"]
			var col := c.lightened(0.2) if on else Color(0.5, 0.42, 0.35, 0.55)
			var mid := Vector2(b.x, a.y + (b.y - a.y) * 0.5)
			draw_polyline(PackedVector2Array([a, Vector2(a.x, mid.y), Vector2(b.x, mid.y), b]), col, 2.0 if on else 1.0)
