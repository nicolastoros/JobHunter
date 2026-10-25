class_name Player
extends CharacterBody2D
## Top-down swordsman controller: 4-direction movement, run, attack (also while walking or running),
## skills (keys 1-6), target lock (Tab / mouse wheel), riding the mount (H) and NPC interaction.
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
var _moving_attack := false
var _mount: AnimatedSprite2D
const TARGET_RANGE := 230.0
const TARGET_KEEP := 330.0
const RIDER_LIFT := 9.0

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
	_mount = AnimatedSprite2D.new()
	_mount.sprite_frames = load(GameData.MOUNT["frames"])
	_mount.offset = Vector2(0, -12)
	_mount.visible = false
	add_child(_mount)
	move_child(_mount, sprite.get_index())
	if not _outdoors():
		Game.mounted = false
	Game.target = null
	var marker := Node2D.new()
	marker.set_script(load("res://scripts/fx/target_marker.gd"))
	get_parent().add_child.call_deferred(marker)
	_play("idle")


func _outdoors() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.get("walkmask_path") != null


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
			if _moving_attack:
				# keep moving while swinging; the facing stays on the swing
				var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
				var spd := (run_speed * 0.85 if Input.is_action_pressed("run") else walk_speed) * Game.speed_mult()
				velocity = velocity.move_toward(input * spd, acceleration * delta)
			else:
				velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			move_and_slide()
		State.DEAD:
			velocity = Vector2.ZERO
		State.DASH:
			_dash_state(delta)
	# war cry: a warm glow while it lasts
	sprite.modulate = Color(1.25, 1.1, 0.8) if Game.buff_active() else Color.WHITE
	_update_mount()
	_check_target()
	_update_focus()


func _unhandled_input(event: InputEvent) -> void:
	if Game.input_locked:
		return
	if event.is_action_pressed("target"):
		get_viewport().set_input_as_handled()
		if is_instance_valid(Game.target):
			_set_target(null)
		else:
			_cycle_target(1)
		return
	if event.is_action_pressed("target_next") or event.is_action_pressed("target_prev"):
		get_viewport().set_input_as_handled()
		_cycle_target(1 if event.is_action_pressed("target_next") else -1)
		return
	if state != State.MOVE:
		return
	if event.is_action_pressed("mount"):
		get_viewport().set_input_as_handled()
		_toggle_mount()
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
	if Game.mounted:
		running = false
	var speed := (run_speed if running else walk_speed) * Game.speed_mult()
	if Game.mounted:
		speed = walk_speed * float(GameData.MOUNT["speed"]) * (1.35 if Input.is_action_pressed("run") else 1.0)
	if input != Vector2.ZERO:
		facing = _dir_name(input)
		velocity = velocity.move_toward(input * speed, acceleration * delta)
		_play("idle" if Game.mounted else ("run" if running else "walk"))
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		_play("idle")
	move_and_slide()


func _start_attack() -> void:
	if Game.mounted:
		_toggle_mount()
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_moving_attack = input != Vector2.ZERO
	if not _moving_attack and is_instance_valid(Game.target) and Game.target.global_position.distance_to(global_position) < 90.0:
		facing = _dir_name(Game.target.global_position - global_position)
	state = State.ATTACK
	Game.sfx("swing", -5.0, 0.12)
	attack_hitbox.position = HITBOX_OFFSETS[facing]
	attack_shape.disabled = false
	if _moving_attack:
		_play("run_attack" if Input.is_action_pressed("run") else "walk_attack")
	else:
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


# --- Mount -------------------------------------------------------------------------------------

func _toggle_mount() -> void:
	if Game.mounted:
		Game.mounted = false
	elif not Game.has_mount:
		Game.tip("no_mount", "Aún no tienes montura. En el establo de las Granjas del Este venden ciervos de monta.")
		return
	elif not _outdoors():
		Game.toast("Aquí dentro no puedes montar.")
		return
	else:
		Game.mounted = true
		Game.tip("mounted", "Montado: más rápido y sin gastar estamina. Atacar te hace desmontar.")
	_update_mount()


func _update_mount() -> void:
	var on := Game.mounted and state != State.DEAD
	_mount.visible = on
	sprite.offset.y = -14.0 - (RIDER_LIFT if on else 0.0)
	if on:
		var anim := "idle"
		if velocity.length() > 10.0:
			anim = "run" if velocity.length() > walk_speed * 1.6 else "walk"
		var a := "%s_%s" % [anim, facing]
		if _mount.animation != a:
			_mount.play(a)


# --- Target lock ---------------------------------------------------------------------------------

func _candidates() -> Array:
	var out: Array = []
	for m in get_tree().get_nodes_in_group("monsters"):
		var mon := m as Node2D
		if int(mon.get("hp")) > 0 and mon.global_position.distance_to(global_position) <= TARGET_RANGE:
			out.append(mon)
	out.sort_custom(func(a, b): return a.global_position.distance_to(global_position) < b.global_position.distance_to(global_position))
	return out


func _cycle_target(step: int) -> void:
	var list := _candidates()
	if list.is_empty():
		_set_target(null)
		Game.tip("no_target", "No hay presas cerca para fijar.")
		return
	var i := list.find(Game.target) if is_instance_valid(Game.target) else -1
	if i == -1:
		_set_target(list[0])
	else:
		_set_target(list[posmod(i + step, list.size())])


func _set_target(t: Node2D) -> void:
	Game.target = t
	Game.target_changed.emit()


func _check_target() -> void:
	var t := Game.target
	if t == null:
		return
	if not is_instance_valid(t) or int(t.get("hp")) <= 0 or t.global_position.distance_to(global_position) > TARGET_KEEP:
		_set_target(null)


## Direction toward the target if there is one close enough, else the facing.
func aim_dir(max_dist := 160.0) -> Vector2:
	if is_instance_valid(Game.target) and Game.target.global_position.distance_to(global_position) <= max_dist:
		return (Game.target.global_position - global_position).normalized()
	return {"down": Vector2.DOWN, "up": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT}[facing]


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
	Game.sfx("skill", -2.0, 0.08)
	if Game.mounted:
		_toggle_mount()
	if is_instance_valid(Game.target) and id in ["tajo", "embestida"]:
		facing = _dir_name(aim_dir())
	var v := Game.skill_values(id)
	match id:
		"giro":
			state = State.ATTACK
			_play("attack")
			_ring(float(v["radius"]))
			_hit_around(float(v["radius"]), int(v["dmg"]))
		"embestida":
			_dash_dir = aim_dir()
			var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
			if input != Vector2.ZERO and not is_instance_valid(Game.target):
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
			var dir: Vector2 = aim_dir(200.0)
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
	Game.sfx("hurt", -1.0, 0.1)
	Game.shake(3.5 if amount < Game.max_hp * 0.2 else 6.0, 0.22)
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
	Game.sfx("player_die", 0.0, 0.0)
	_play("death")
	Game.input_locked = true
	await get_tree().create_timer(1.6).timeout
	Game.player_died()


func _on_animation_finished() -> void:
	_moving_attack = false
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
