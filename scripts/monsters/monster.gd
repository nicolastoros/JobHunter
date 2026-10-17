class_name Monster
extends CharacterBody2D
## Field monster: wanders its territory, notices the player, chases, attacks, takes hits, dies and respawns.
## Animations expected in `frames`: idle_/walk_/attack_/hurt_/death_ + down/up/left/right (run_ optional).

enum State { IDLE, WANDER, CHASE, ATTACK, HURT, DEAD, RETURN }

@export var frames: SpriteFrames
@export var monster_name := "Limo"
@export var max_hp := 3
@export var damage := 1
@export var speed := 22.0
@export var chase_speed := 34.0
@export var aggro_radius := 72.0
@export var attack_range := 16.0
@export var attack_cooldown := 1.2
@export var territory := 96.0
@export var gold := 2
@export var boss := false
@export var sprite_offset_y := -18.0
@export var body_size := Vector2(12, 6)
@export var respawn_time := 45.0

var state := State.IDLE
var hp := 3
## Level chosen from the hero's level each time the monster (re)appears.
var monster_level := 1
var xp_reward := 1
var _base_hp := 3
var _base_damage := 1
var _base_gold := 2
var _last_hitter: Node2D = null
var _home := Vector2.ZERO
var _target := Vector2.ZERO
var _wait := 0.0
var _facing := "down"
var _cool := 0.0
var _hit_done := false
var _knock := Vector2.ZERO
var _bar_timer := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var hurt_shape: CollisionShape2D = $Hurtbox/CollisionShape2D


func _ready() -> void:
	add_to_group("monsters")
	_home = global_position
	_base_hp = max_hp
	_base_damage = damage
	_base_gold = gold
	_apply_level()
	sprite.sprite_frames = frames
	sprite.offset.y = sprite_offset_y
	(shape.shape as RectangleShape2D).size = body_size
	shape.position.y = -body_size.y / 2.0
	var hs := RectangleShape2D.new()
	hs.size = Vector2(body_size.x + 6, maxf(18.0, -sprite_offset_y * 1.3))
	hurt_shape.shape = hs
	hurt_shape.position.y = -hs.size.y / 2.0
	sprite.animation_finished.connect(_on_anim_finished)
	_wait = randf_range(0.5, 3.0)
	_play("idle")


func _physics_process(delta: float) -> void:
	if Game.editing:
		return
	_cool -= delta
	_bar_timer -= delta
	var player := _pick_target()
	match state:
		State.DEAD:
			return
		State.HURT:
			velocity = _knock
			_knock = _knock.move_toward(Vector2.ZERO, 600 * delta)
			move_and_slide()
			return
		State.ATTACK:
			velocity = Vector2.ZERO
			if not _hit_done and sprite.frame >= int(sprite.sprite_frames.get_frame_count(sprite.animation) * 0.45):
				_hit_done = true
				if player and player.global_position.distance_to(global_position) < attack_range + 10.0:
					player.take_damage(damage, global_position)
			return
	var to_player := (player.global_position - global_position) if player else Vector2.INF
	var dist := to_player.length() if player else INF
	var alive_player: bool = player != null and not player.is_dead()
	if alive_player and dist < aggro_radius and global_position.distance_to(_home) < territory * 2.5:
		if state != State.CHASE and boss and player.is_in_group("player"):
			Game.boss_engaged.emit(self)
		state = State.CHASE
	elif state == State.CHASE:
		state = State.RETURN
		_target = _home
	match state:
		State.CHASE:
			if dist < attack_range and _cool <= 0.0:
				_start_attack(to_player)
				return
			_move_toward(player.global_position, chase_speed, "run")
		State.RETURN:
			if _move_toward(_target, speed, "walk"):
				state = State.IDLE
				hp = max_hp
				_wait = randf_range(1.0, 3.0)
				if monster_level < Game.level - 1:
					_apply_level()
		State.WANDER:
			if _move_toward(_target, speed, "walk"):
				state = State.IDLE
				_wait = randf_range(1.5, 5.0)
		State.IDLE:
			velocity = Vector2.ZERO
			_play("idle")
			_wait -= delta
			if _wait <= 0.0:
				var a := randf() * TAU
				_target = _home + Vector2(cos(a), sin(a)) * randf_range(16.0, territory)
				state = State.WANDER


func _move_toward(p: Vector2, spd: float, anim: String) -> bool:
	var to := p - global_position
	if to.length() < 4.0:
		velocity = Vector2.ZERO
		return true
	velocity = to.normalized() * spd
	var before := global_position
	move_and_slide()
	_facing = _dir(to)
	_play(anim)
	if before.distance_to(global_position) < spd * get_physics_process_delta_time() * 0.2 and state != State.CHASE:
		return true   # blocked: give up on this target
	return false


func _start_attack(to_player: Vector2) -> void:
	state = State.ATTACK
	_hit_done = false
	_cool = attack_cooldown
	_facing = _dir(to_player)
	_play("attack", true)


## Called by the hurtbox when the player's sword connects.
func take_hit(amount: int, source: Node2D, crit := false) -> void:
	if state == State.DEAD:
		return
	_last_hitter = source
	hp -= amount
	_bar_timer = 3.0
	if crit:
		Game.spawn_popup(global_position + Vector2(0, sprite_offset_y * 1.6), "%d!" % amount, Color(1, 0.82, 0.25))
	else:
		Game.spawn_popup(global_position + Vector2(0, sprite_offset_y * 1.6), str(amount), Color(1, 1, 1))
	var t := create_tween()
	sprite.modulate = Color(3, 3, 3)
	t.tween_property(sprite, "modulate", Color.WHITE, 0.18)
	if boss:
		Game.boss_engaged.emit(self)
	if hp <= 0:
		_die()
		return
	if not boss:
		state = State.HURT
		_knock = (global_position - source.global_position).normalized() * 140.0
		_play("hurt", true)


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	shape.set_deferred("disabled", true)
	hurt_shape.set_deferred("disabled", true)
	_play("death", true)
	if _last_hitter and is_instance_valid(_last_hitter) and _last_hitter.is_in_group("hunters"):
		Game.on_hunter_kill(String(_last_hitter.get("hunter_name")), self)
	else:
		Game.on_monster_killed(self)


func _on_anim_finished() -> void:
	match state:
		State.ATTACK:
			state = State.CHASE
		State.HURT:
			state = State.CHASE
		State.DEAD:
			var t := create_tween()
			t.tween_property(sprite, "modulate:a", 0.0, 0.8)
			t.tween_interval(respawn_time)
			t.tween_callback(_respawn)


## Monsters adapt to the hero: around the hero's level (bosses a little above).
func _apply_level() -> void:
	var lv := Game.level + (2 if boss else randi_range(-1, 1))
	monster_level = clampi(lv, 1, GameData.MAX_LEVEL)
	max_hp = maxi(1, int(round(_base_hp * GameData.mon_hp_mult(monster_level))))
	damage = maxi(1, int(round(_base_damage * GameData.mon_dmg_mult(monster_level))))
	gold = int(round(_base_gold * (1.0 + 0.1 * (monster_level - 1))))
	xp_reward = int(round((_base_hp * 2 + (30 if boss else 0)) * (1.0 + 0.25 * (monster_level - 1))))
	hp = max_hp


func _respawn() -> void:
	global_position = _home
	_last_hitter = null
	_apply_level()
	shape.set_deferred("disabled", false)
	hurt_shape.set_deferred("disabled", false)
	state = State.IDLE
	_wait = 2.0
	_play("idle")
	create_tween().tween_property(sprite, "modulate:a", 1.0, 0.6)


func _play(base: String, restart := false) -> void:
	var anim := "%s_%s" % [base, _facing]
	if frames == null:
		return
	if not frames.has_animation(anim):
		anim = "walk_%s" % _facing if base == "run" else "idle_%s" % _facing
		if not frames.has_animation(anim):
			return
	if sprite.animation != anim or restart:
		sprite.play(anim)
		if restart:
			sprite.frame = 0


static func _dir(v: Vector2) -> String:
	if absf(v.x) > absf(v.y):
		return "right" if v.x > 0.0 else "left"
	return "down" if v.y > 0.0 else "up"


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


## The hero if close, otherwise the nearest hunter of the Guild that wanders into its territory.
func _pick_target() -> Node2D:
	var p := _player()
	if p and not p.is_dead() and p.global_position.distance_to(global_position) < aggro_radius:
		return p
	var best: Node2D = null
	var bd := aggro_radius * 0.8
	for h in get_tree().get_nodes_in_group("hunters"):
		if h.call("is_dead"):
			continue
		var d := (h as Node2D).global_position.distance_to(global_position)
		if d < bd:
			best = h
			bd = d
	return best if best else p


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if boss or state == State.DEAD or _bar_timer <= 0.0 or hp >= max_hp:
		return
	var w := 18.0
	var y := sprite_offset_y * 2.0 - 4.0
	draw_rect(Rect2(-w / 2 - 1, y - 1, w + 2, 4), Color(0.1, 0.06, 0.05, 0.85))
	draw_rect(Rect2(-w / 2, y, w * float(hp) / max_hp, 2), Color(0.85, 0.2, 0.15))
	draw_string(ThemeDB.fallback_font, Vector2(-w / 2, y - 2), "Nv %d" % monster_level, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(1, 0.95, 0.85))
