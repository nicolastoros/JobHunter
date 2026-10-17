extends Node2D
## Wild animal: grazes, wanders inside its area and runs away when the player gets close.

@export var frames: SpriteFrames
@export var wander_rect := Rect2(0, 0, 200, 100)
@export var walk_speed := 18.0
@export var flee_distance := 56.0

var _target := Vector2.ZERO
var _wait := 0.0
var _facing := "down"
var _fleeing := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# moves every rendered frame already, so physics interpolation would only add lag
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	sprite.sprite_frames = frames
	_wait = randf_range(0.5, 4.0)
	_play("idle")


func _process(delta: float) -> void:
	if Game.editing:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and player.global_position.distance_to(global_position) < flee_distance:
		var away := (global_position - player.global_position).normalized()
		_target = global_position + away * 64.0
		_target = _target.clamp(wander_rect.position, wander_rect.end)
		_fleeing = true
		_wait = 0.0
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			_target = Vector2(randf_range(wander_rect.position.x, wander_rect.end.x), randf_range(wander_rect.position.y, wander_rect.end.y))
			if global_position.distance_to(_target) > 90.0:
				_target = global_position + (_target - global_position).normalized() * 90.0
		return
	var to := _target - global_position
	if to.length() < 2.0:
		_fleeing = false
		_wait = randf_range(2.0, 7.0)
		_play("idle")
		return
	var spd := walk_speed * (3.2 if _fleeing else 1.0)
	global_position += to.normalized() * minf(spd * delta, to.length())
	_facing = _dir(to)
	_play("walk")
	sprite.speed_scale = 2.0 if _fleeing else 1.0


func _play(base: String) -> void:
	var anim := "%s_%s" % [base, _facing]
	if frames and frames.has_animation(anim) and sprite.animation != anim:
		sprite.play(anim)


static func _dir(v: Vector2) -> String:
	if absf(v.x) > absf(v.y):
		return "right" if v.x > 0.0 else "left"
	return "down" if v.y > 0.0 else "up"
