@tool
extends NPCBase
## Citizen that strolls around a rectangle of the map, pausing now and then.

@export var wander_rect := Rect2(0, 0, 64, 64)
@export var walk_speed := 26.0

var _target := Vector2.ZERO
var _walking := false
var _facing := "down"
var _stuck_time := 0.0
var _talking := false

@onready var _timer: Timer = $WanderTimer


func _default_animation() -> StringName:
	return &"idle_down"


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	_timer.timeout.connect(_pick_target)
	Game.dialogue_finished.connect(func(): _talking = false)
	_timer.start(randf_range(0.5, 3.0))


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _walking or _talking:
		velocity = Vector2.ZERO
		return
	var to_target := _target - global_position
	if to_target.length() < 3.0:
		_stop()
		return
	velocity = to_target.normalized() * walk_speed
	_facing = Player._dir_name(velocity)
	var before := global_position
	move_and_slide()
	# Blocked by a stall or the player: give up and choose another spot later.
	if before.distance_to(global_position) < walk_speed * delta * 0.25:
		_stuck_time += delta
		if _stuck_time > 0.6:
			_stop()
	else:
		_stuck_time = 0.0
	sprite.play("walk_" + _facing)


func _pick_target() -> void:
	_target = Vector2(
		randf_range(wander_rect.position.x, wander_rect.end.x),
		randf_range(wander_rect.position.y, wander_rect.end.y))
	_walking = true
	_stuck_time = 0.0


func _stop() -> void:
	_walking = false
	sprite.play("idle_" + _facing)
	_timer.start(randf_range(1.5, 4.5))


func interact(player: Node) -> void:
	_talking = true
	_walking = false
	var d := (player as Node2D).global_position - global_position
	_facing = Player._dir_name(d)
	sprite.play("idle_" + _facing)
	_timer.start(randf_range(2.0, 4.0))
	super(player)
