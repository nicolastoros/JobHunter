extends Node2D
## Rune stone (teleport). Asleep (grey) until you touch it with E; awake, it glows and from it you can
## travel to every other awake stone in Valdoria.

const SHEET := preload("res://assets/sprites/objects/runes.png")
const CELL := 64

@export var stone_id := ""

var _def: Dictionary
var _sprite: AnimatedSprite2D
var _awake := false
var _t := 0.0


func _ready() -> void:
	add_to_group("waystones")
	add_to_group("poi")
	set_meta("poi_kind", "waystone")
	for w in GameData.WAYSTONES:
		if w["id"] == stone_id:
			_def = w
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _frames(int(_def.get("rune", 3)))
	_sprite.offset = Vector2(0, -27)
	add_child(_sprite)
	move_child(_sprite, 0)
	_set_awake(Game.is_waystone_unlocked(stone_id), false)


## The rune's twelve frames (two rows of five designs per frame in the pack's sheet).
static func _frames(rune: int) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.add_animation("on")
	sf.set_animation_speed("on", 8.0)
	sf.add_animation("off")
	var col := rune % 5
	var set_ := rune / 5
	for f in 12:
		var a := AtlasTexture.new()
		a.atlas = SHEET
		a.region = Rect2(col * CELL, (f * 2 + set_) * CELL, CELL, CELL)
		sf.add_frame("on", a)
		if f == 0:
			sf.add_frame("off", a)
	sf.remove_animation("default")
	return sf


func _set_awake(on: bool, fx: bool) -> void:
	_awake = on
	_sprite.play("on" if on else "off")
	_sprite.modulate = Color.WHITE if on else Color(0.45, 0.45, 0.5)
	if fx:
		var t := create_tween()
		_sprite.modulate = Color(3, 3, 3)
		t.tween_property(_sprite, "modulate", Color.WHITE, 0.6)
		_sprite.scale = Vector2(1.3, 1.3)
		t.parallel().tween_property(_sprite, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	# a circle of light on the ground while the stone is awake
	if not _awake:
		return
	var pulse := 0.5 + 0.5 * sin(_t * 2.5)
	var c := Color(0.55, 0.8, 1.0, 0.18 + 0.12 * pulse)
	draw_set_transform(Vector2(0, 1), 0.0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 16.0 + 2.0 * pulse, c)
	draw_arc(Vector2.ZERO, 18.0 + 2.0 * pulse, 0.0, TAU, 28, Color(0.75, 0.9, 1.0, 0.45 + 0.2 * pulse), 1.0)


func set_focused(value: bool) -> void:
	$Prompt.visible = value


func interact(_player: Node) -> void:
	if not _awake:
		Game.unlock_waystone(stone_id)
		_set_awake(true, true)
		return
	Game.waystone_menu_requested.emit(stone_id)
