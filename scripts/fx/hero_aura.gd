extends Node2D
## The hero's aura: sparks of the weapon's element at +8 / +10, and the Seals worn orbiting around
## (a star for SOS, a moon for SOM, a sun for SOSUN).

var _t := 0.0
var _check := 0.0
var _elem := Color.TRANSPARENT
var _level := 0
var _seals: Array[int] = []


func _process(delta: float) -> void:
	_t += delta
	_check -= delta
	if _check <= 0.0:
		_check = 0.5
		_refresh()
	if _level > 0 or not _seals.is_empty():
		queue_redraw()


func _refresh() -> void:
	_level = 0
	_seals.clear()
	var w := String(Game.equipped.get("weapon", ""))
	if w != "":
		var plus := Game.eq_plus(w)
		if plus >= 8:
			_level = 2 if plus >= 10 else 1
			_elem = GameData.FORGE_EFFECTS[GameData.weapon_family(Game.eq_base(w))]["color"]
	for slot in Game.equipped:
		var r := Game.eq_rarity(String(Game.equipped[slot]))
		if r >= 4:
			_seals.append(r)
	if _level == 0 and _seals.is_empty():
		queue_redraw()


func _draw() -> void:
	if _level > 0:
		var n := 4 if _level == 1 else 8
		for i in n:
			var k := fmod(_t * 0.7 + i / float(n), 1.0)
			var x := sin(i * 2.3 + _t * 1.7) * 9.0
			var y := -4.0 - k * 26.0
			draw_rect(Rect2(x - 1, y - 1, 2, 2), Color(_elem.lightened(0.3), 1.0 - k))
		if _level == 2:
			draw_set_transform(Vector2(0, 1), 0.0, Vector2(1, 0.4))
			draw_arc(Vector2.ZERO, 11.0 + sin(_t * 4.0), 0.0, TAU, 24, Color(_elem, 0.5), 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in _seals.size():
		var a := _t * 1.6 + i * TAU / maxf(1, _seals.size())
		var p := Vector2(cos(a) * 13.0, -14.0 + sin(a) * 5.0)
		var col: Color = GameData.RARITY_COLORS[_seals[i]]
		match _seals[i]:
			4:
				var pts := PackedVector2Array()
				for j in 10:
					var b := -PI / 2.0 + j * TAU / 10.0
					pts.append(p + Vector2(cos(b), sin(b)) * (3.0 if j % 2 == 0 else 1.3))
				draw_colored_polygon(pts, col)
			5:
				draw_circle(p, 2.6, col)
				draw_circle(p + Vector2(1.2, -0.6), 2.1, Color(0, 0, 0, 0.0))
				draw_arc(p, 2.6, 0.6, 3.6, 8, col.lightened(0.4), 1.0)
			6:
				draw_circle(p, 2.2, col)
				for j in 6:
					var b := _t * 2.0 + j * TAU / 6.0
					draw_line(p + Vector2(cos(b), sin(b)) * 2.8, p + Vector2(cos(b), sin(b)) * 4.2, col, 1.0)
