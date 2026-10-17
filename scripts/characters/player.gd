class_name Player
extends CharacterBody2D
## Top-down swordsman controller: 4-direction movement, run, attack, skills (keys 1-6) and NPC interaction.
## The sprite set follows the hero's level (GameData.LOOKS).

signal attacked

@export var walk_speed := 72.0
@export var run_speed := 118.0
@export var acceleration := 900.0
@export var friction := 1100.0

enum State { MOVE, ATTACK, HURT, DEAD, DASH }

const DASH_SPEED := 430.0
const LOOK_FRAMES := "res://resources/sprite_frames/swordsman_lvl%d.tres"

var state := State.MOVE
var facing := "down"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

var _focused: Node = null
var _invulnerable := 0.0
var _knockback := Vector2.ZERO
var _exhausted := false   # out of stamina: walk until it recovers a bit
var _dash_left := 0.0
var _dash_dir := Vector2.ZERO
var _dash_hit: Array = []
var _dash_dmg := 1
var _look := 0

const HITBOX_OFFSETS := {
	"down": Vector2(0, 2),
	"up": Vector2(0, -20),
	"left": Vector2(-14, -8),
	"right": Vector2(14, -8),
}


func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)
	attack_shape.disabled = true
	apply_look()
	Game.look_changed.connect(apply_look)
	_play("idle")


## Swaps the sprite set when the hero reaches a new look.
func apply_look() -> void:
	var tier := Game.look_tier()
	if tier == _look:
		return
	var sf := load(LOOK_FRAMES % tier) as SpriteFrames
	if sf == null:
		return
	var anim := sprite.animation
	_look = tier
	sprite.sprite_frames = sf
	if sf.has_animation(anim):
		sprite.play(anim)
	if is_inside_tree() and tier > 1:
		var fx := Node2D.new()
		fx.set_script(load("res://scripts/fx/slash_ring.gd"))
		fx.set("radius", 30.0)
		fx.position = global_position + Vector2(0, -12)
		get_parent().add_child.call_deferred(fx)


func _physics_process(delta: float) -> void:
	if _invulnerable > 0.0:
		_invulnerable -= delta
		sprite.visible = state == State.DEAD or int(_invulnerable * 20.0) % 2 == 0
		if _invulnerable <= 0.0:
			sprite.visible = true
	match state:
		State.MOVE:
			_move_state(delta)
		State.HURT:
			velocity = _knockback
			_knockback = _knockback.move_toward(Vector2.ZERO, 700 * delta)
			move_and_slide()
		State.ATTACK:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			move_and_slide()
		State.DEAD:
			velocity = Vector2.ZERO
		State.DASH:
			_dash_state(delta)
	# war cry: a warm glow while it lasts
	sprite.modulate = Color(1.25, 1.1, 0.8) if Game.buff_active() else Color.WHITE
	_update_focus()


func _unhandled_input(event: InputEvent) -> void:
	if Game.input_locked or state != State.MOVE:
		return
	if event.is_action_pressed("attack"):
		_start_attack()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("use_potion"):
		get_viewport().set_input_as_handled()
		Game.use_potion()
	elif event.is_action_pressed("interact") and _focused:
		get_viewport().set_input_as_handled()
		velocity = Vector2.ZERO
		_play("idle")
		_focused.interact(self)
	else:
		for i in GameData.SKILLS.size():
			if event.is_action_pressed("skill_%d" % (i + 1)):
				get_viewport().set_input_as_handled()
				cast_skill(GameData.SKILLS[i]["id"])
				return


func _move_state(delta: float) -> void:
	var input := Vector2.ZERO
	if not Game.input_locked:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var scene := get_tree().current_scene
	var tiring: bool = scene != null and scene.get("run_uses_stamina") == true
	if _exhausted and Game.stamina >= Game.max_stamina * 0.3:
		_exhausted = false
	var running := Input.is_action_pressed("run") and not Game.input_locked and input != Vector2.ZERO and not _exhausted
	if running and tiring:
		Game.set_stamina(Game.stamina - 22.0 * Game.run_cost_mult() * delta)
		if Game.stamina <= 0.0:
			_exhausted = true
	elif Game.stamina < Game.max_stamina:
		Game.set_stamina(Game.stamina + (14.0 * Game.stamina_regen_mult() if tiring else 60.0) * delta)
	if input != Vector2.ZERO:
		facing = _dir_name(input)
		velocity = velocity.move_toward(input * (run_speed if running else walk_speed) * Game.speed_mult(), acceleration * delta)
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
				Game.hit_monster(area, Game.attack(), false, self)


func is_dead() -> bool:
	return state == State.DEAD


# --- Skills -------------------------------------------------------------------------

func cast_skill(id: String) -> void:
	if state != State.MOVE or Game.input_locked:
		return
	if not Game.has_skill(id):
		Game.toast("Todavía no conoces esa habilidad. Apréndela en el menú de habilidades (K).")
		return
	var err := Game.try_cast(id)
	if err != "":
		Game.toast(err)
		return
	var v := Game.skill_values(id)
	match id:
		"giro":
			state = State.ATTACK
			_play("attack")
			_ring(float(v["radius"]))
			_hit_around(float(v["radius"]), int(v["dmg"]))
		"embestida":
			_dash_dir = {"down": Vector2.DOWN, "up": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT}[facing]
			var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
			if input != Vector2.ZERO:
				_dash_dir = input.normalized()
			_dash_left = float(v["time"])
			_dash_dmg = int(v["dmg"])
			_dash_hit.clear()
			state = State.DASH
			_play("run")
		"grito":
			Game.start_buff(float(v["time"]), int(v["bonus"]))
			Game.spawn_popup(global_position + Vector2(0, -36), "+%d de ataque" % v["bonus"], Color(1, 0.8, 0.4))
		"respiro":
			var h := maxi(1, int(round(Game.max_hp * float(v["heal"]))))
			Game.heal_player(h)
			Game.spawn_popup(global_position + Vector2(0, -36), "+%d" % h, Color(0.5, 1, 0.55))
		"onda":
			state = State.ATTACK
			_play("attack")
			_ring(float(v["radius"]))
			_ring(float(v["radius"]) * 0.6)
			_hit_around(float(v["radius"]), int(v["dmg"]), 220.0)
		"tajo":
			state = State.ATTACK
			_play("attack")
			var dir: Vector2 = {"down": Vector2.DOWN, "up": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT}[facing]
			var length := float(v["length"])
			var origin := global_position + Vector2(0, -10)
			var fx := Node2D.new()
			fx.set_script(load("res://scripts/fx/light_slash.gd"))
			fx.set("dir", dir)
			fx.set("length", length)
			fx.position = origin
			get_parent().add_child(fx)
			for m in get_tree().get_nodes_in_group("monsters"):
				var mon := m as Node2D
				if int(mon.get("hp")) <= 0:
					continue
				var rel := mon.global_position + Vector2(0, -8) - origin
				var along := rel.dot(dir)
				if along > -8.0 and along < length and absf(rel.cross(dir)) < 18.0:
					Game.hit_monster(mon, int(v["dmg"]), true, self)


func _ring(radius: float) -> void:
	var fx := Node2D.new()
	fx.set_script(load("res://scripts/fx/slash_ring.gd"))
	fx.set("radius", radius)
	fx.position = global_position + Vector2(0, -8)
	get_parent().add_child(fx)


func _hit_around(radius: float, dmg: int, push := 0.0) -> void:
	for m in get_tree().get_nodes_in_group("monsters"):
		var mon := m as Node2D
		if int(mon.get("hp")) > 0 and mon.global_position.distance_to(global_position) <= radius:
			Game.hit_monster(mon, dmg, true, self)
			if push > 0.0 and int(mon.get("hp")) > 0 and not mon.get("boss"):
				mon.set("_knock", (mon.global_position - global_position).normalized() * push)


func _dash_state(delta: float) -> void:
	_dash_left -= delta
	velocity = _dash_dir * DASH_SPEED
	move_and_slide()
	for m in get_tree().get_nodes_in_group("monsters"):
		var mon := m as Node2D
		if not mon in _dash_hit and int(mon.get("hp")) > 0 and mon.global_position.distance_to(global_position) < 22.0:
			_dash_hit.append(mon)
			Game.hit_monster(mon, _dash_dmg, true, self)
	if _dash_left <= 0.0:
		velocity = _dash_dir * walk_speed
		state = State.MOVE


## Called by monsters. `from` is the attacker position, used for knockback.
func take_damage(amount: int, from := Vector2.INF) -> void:
	if state == State.DEAD or state == State.DASH or _invulnerable > 0.0 or Game.editing:
		return
	if randf() < Game.dodge_chance():
		Game.spawn_popup(global_position + Vector2(0, -30), "Esquivas", Color(0.85, 0.9, 1))
		_invulnerable = 0.4
		return
	amount = Game.mitigate(amount)
	var shield := Game.tsum("mana_shield")
	if shield > 0.0:
		var paid := mini(int(round(amount * shield)), int(Game.mana))
		Game.mana -= paid
		amount = maxi(amount - paid, 0)
		if amount == 0:
			Game.spawn_popup(global_position + Vector2(0, -30), "Escudo", Color(0.6, 0.75, 1))
			_invulnerable = 0.5
			Game.stats_changed.emit()
			return
	Game.damage_player(amount)
	Game.spawn_popup(global_position + Vector2(0, -30), "-%d" % amount, Color(1, 0.35, 0.3))
	attack_shape.set_deferred("disabled", true)
	if Game.player_hp <= 0:
		_die()
		return
	state = State.HURT
	_invulnerable = 1.0
	if from != Vector2.INF:
		_knockback = (global_position - from).normalized() * 170.0
	_play("hurt")


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	_play("death")
	Game.input_locked = true
	await get_tree().create_timer(1.6).timeout
	Game.player_died()


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
