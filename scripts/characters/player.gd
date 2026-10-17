class_name Player
extends CharacterBody2D
## Top-down swordsman controller: 4-direction movement, run, attack and NPC interaction.

signal attacked

@export var walk_speed := 72.0
@export var run_speed := 118.0
@export var acceleration := 900.0
@export var friction := 1100.0
@export var attack_damage := 1

enum State { MOVE, ATTACK, HURT, DEAD }

var state := State.MOVE
var facing := "down"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

var _focused: Node = null

const HITBOX_OFFSETS := {
	"down": Vector2(0, 2),
	"up": Vector2(0, -20),
	"left": Vector2(-14, -8),
	"right": Vector2(14, -8),
}


func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)
	attack_shape.disabled = true
	_play("idle")


func _physics_process(delta: float) -> void:
	match state:
		State.MOVE:
			_move_state(delta)
		State.ATTACK, State.HURT:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			move_and_slide()
		State.DEAD:
			velocity = Vector2.ZERO
	_update_focus()


func _unhandled_input(event: InputEvent) -> void:
	if Game.input_locked or state != State.MOVE:
		return
	if event.is_action_pressed("attack"):
		_start_attack()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and _focused:
		get_viewport().set_input_as_handled()
		velocity = Vector2.ZERO
		_play("idle")
		_focused.interact(self)


func _move_state(delta: float) -> void:
	var input := Vector2.ZERO
	if not Game.input_locked:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var running := Input.is_action_pressed("run") and not Game.input_locked
	if input != Vector2.ZERO:
		facing = _dir_name(input)
		velocity = velocity.move_toward(input * (run_speed if running else walk_speed), acceleration * delta)
		_play("run" if running else "walk")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		_play("idle")
	move_and_slide()


func _start_attack() -> void:
	state = State.ATTACK
	attack_hitbox.position = HITBOX_OFFSETS[facing]
	attack_shape.disabled = false
	_play("attack")
	attacked.emit()
	# Damage everything already overlapping the swing a few frames in.
	await get_tree().create_timer(0.18).timeout
	if state == State.ATTACK:
		for area in attack_hitbox.get_overlapping_areas():
			if area.has_method("take_hit"):
				area.take_hit(attack_damage, self)


func take_damage(_amount: int) -> void:
	if state == State.DEAD:
		return
	state = State.HURT
	_play("hurt")


func _on_animation_finished() -> void:
	if state == State.ATTACK or state == State.HURT:
		attack_shape.disabled = true
		state = State.MOVE
		_play("idle")


func _play(base: String) -> void:
	var anim := "%s_%s" % [base, facing]
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


static func _dir_name(v: Vector2) -> String:
	if absf(v.x) > absf(v.y):
		return "right" if v.x > 0.0 else "left"
	return "down" if v.y > 0.0 else "up"


# --- Interaction --------------------------------------------------------------

func _update_focus() -> void:
	var best: Node = null
	var best_dist := INF
	if state == State.MOVE and not Game.input_locked:
		for area in interaction_area.get_overlapping_areas():
			var target := area.get_parent()
			if target and target.has_method("interact"):
				var d := global_position.distance_squared_to(area.global_position)
				if d < best_dist:
					best_dist = d
					best = target
	if best != _focused:
		if _focused and is_instance_valid(_focused) and _focused.has_method("set_focused"):
			_focused.set_focused(false)
		_focused = best
		if _focused and _focused.has_method("set_focused"):
			_focused.set_focused(true)


func set_camera_limits(rect: Rect2i) -> void:
	camera.limit_left = rect.position.x
	camera.limit_top = rect.position.y
	camera.limit_right = rect.end.x
	camera.limit_bottom = rect.end.y
	camera.reset_smoothing()
