extends AnimatedSprite2D
## A one-shot animated effect (explosion, lightning strike, ring...): plays its "default" animation once
## and frees itself. `loops` > 1 repeats it (a barrier around the hero, for instance).

var loops := 1


static func spawn(parent: Node, frames_path: String, at: Vector2, scl := 1.0, tint := Color.WHITE, rot := 0.0, z := 5) -> AnimatedSprite2D:
	var fx := AnimatedSprite2D.new()
	fx.set_script(load("res://scripts/fx/anim_fx.gd"))
	fx.sprite_frames = load(frames_path)
	fx.position = at
	fx.scale = Vector2(scl, scl)
	fx.modulate = tint
	fx.rotation = rot
	fx.z_index = z
	parent.add_child(fx)
	return fx


func _ready() -> void:
	animation_finished.connect(_done)
	play(&"default")


func _done() -> void:
	loops -= 1
	if loops > 0:
		play(&"default")
		return
	queue_free()
