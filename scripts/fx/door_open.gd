extends Node2D
## A building's own painted door swinging open onto a dark doorway (used when the hero walks in).
## The leaf is cut from the building sprite, so the animation always matches the art.

var texture: Texture2D
var region := Rect2()
var flip := false
var duration := 0.35

var _leaf: Texture2D
var _hole: Texture2D
var _t := 0.0


func _ready() -> void:
	z_index = 1
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var src := texture.get_image()
	if src.is_compressed():
		src.decompress()
	var img := src.get_region(Rect2i(region))
	if flip:
		img.flip_x()
	var leaf := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	var hole := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	var h := img.get_height()
	for y in h:
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			# wood of the leaf: warm and not too bright (stone, plaster and frames stay as they are)
			if c.a > 0.5 and c.r > c.b + 0.08 and c.r < 0.8:
				leaf.set_pixel(x, y, c)
				var k := float(y) / h
				hole.set_pixel(x, y, Color(0.06, 0.04, 0.03).lerp(Color(0.16, 0.11, 0.07), k * k))
	_leaf = ImageTexture.create_from_image(leaf)
	_hole = ImageTexture.create_from_image(hole)


func _process(delta: float) -> void:
	_t = minf(_t + delta / duration, 1.0)
	queue_redraw()


func _draw() -> void:
	if _leaf == null:
		return
	var w := region.size.x
	var h := region.size.y
	draw_texture(_hole, Vector2(0, -h))
	# the leaf turns on its hinge: it narrows and darkens as it swings inward
	var k := cos(_t * PI * 0.45)
	var lw := maxf(w * k, 1.0)
	var x := w - lw if flip else 0.0
	draw_texture_rect(_leaf, Rect2(x, -h, lw, h), false, Color(1, 1, 1).darkened(0.45 * _t))
