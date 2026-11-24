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
const PROJECTILE := preload("res://scripts/fx/projectile.gd")
const FX := preload("res://scripts/fx/anim_fx.gd")
const FX_PATH := "res://resources/sprite_frames/fx_%s.tres"
## How far the archer and the mage aim on their own when nothing is locked.
const RANGED_AIM := 240.0

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
var _look_class := ""
var _barrier := 0.0
var _barrier_fx: Node2D
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
	var aura := Node2D.new()
	aura.name = "Aura"
	aura.set_script(load("res://scripts/fx/hero_aura.gd"))
	add_child(aura)
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


## Swaps the sprite set when the hero reaches a new look (or changes class).
func apply_look() -> void:
	var tier := Game.look_tier()
	if tier == _look and Game.hero_class == _look_class:
		return
	var sf := load(String(Game.class_def()["frames"]) % tier) as SpriteFrames
	if sf == null:
		return
	var anim := sprite.animation
	_look = tier
	_look_class = Game.hero_class
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
	if _barrier > 0.0:
		_barrier -= delta
		if _barrier <= 0.0 and is_instance_valid(_barrier_fx):
			_barrier_fx.queue_free()
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
		var list := Game.class_skills()
		for i in list.size():
			if event.is_action_pressed("skill_%d" % (i + 1)):
				get_viewport().set_input_as_handled()
				cast_skill(list[i]["id"])
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
	if String(Game.class_def()["attack"]) != "melee":
		_ranged_attack()
		return
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


## The archer's arrow / the mage's fireball: turn toward the prey, draw (or conjure) and release.
func _ranged_attack() -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_moving_attack = input != Vector2.ZERO
	var dir := ranged_dir()
	facing = _dir_name(dir)
	state = State.ATTACK
	var mage := Game.hero_class == "mago"
	Game.sfx("skill" if mage else "swing", -8.0 if mage else -6.0, 0.15)
	_play("attack")
	attacked.emit()
	await get_tree().create_timer(0.2).timeout
	if state != State.ATTACK:
		return
	dir = ranged_dir()
	if mage:
		_shoot("fireball", dir, Game.attack(), false, {"radius": 16.0, "burst": FX_PATH % "fire_explosion", "burst_scale": 0.55, "speed": 230.0, "range": 210.0})
	else:
		_shoot("arrow", dir, maxi(1, int(round(Game.attack() * 0.9))), false, {"speed": 400.0, "range": 250.0})


## Where a shot goes: the locked prey, else the nearest monster roughly ahead, else straight ahead.
func ranged_dir() -> Vector2:
	var from := global_position + Vector2(0, -10)
	if is_instance_valid(Game.target) and Game.target.global_position.distance_to(global_position) <= RANGED_AIM + 40.0:
		return (Game.target.global_position + Vector2(0, -8) - from).normalized()
	var ahead: Vector2 = {"down": Vector2.DOWN, "up": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT}[facing]
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		ahead = input.normalized()
	var best: Node2D = null
	var bd := RANGED_AIM
	for m in get_tree().get_nodes_in_group("monsters"):
		var mon := m as Node2D
		if int(mon.get("hp")) <= 0:
			continue
		var rel := mon.global_position + Vector2(0, -8) - from
		var d := rel.length()
		if d < bd and rel.normalized().dot(ahead) > 0.55:
			best = mon
			bd = d
	if best:
		return (best.global_position + Vector2(0, -8) - from).normalized()
	return ahead


func _shoot(kind: String, dir: Vector2, dmg: int, is_skill: bool, opts := {}) -> Node2D:
	var p := Node2D.new()
	p.set_script(PROJECTILE)
	p.set("kind", kind)
	p.set("dir", dir)
	p.set("dmg", dmg)
	p.set("is_skill", is_skill)
	p.set("source", self)
	p.set("tier", _look)
	for k in opts:
		p.set("max_range" if k == "range" else String(k), opts[k])
	p.position = global_position + Vector2(0, -10) + dir * 8.0
	get_parent().add_child(p)
	return p


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
	if _class_skill(id, v):
		return
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


## The archer's and the mage's skills. False if `id` is not one of theirs.
func _class_skill(id: String, v: Dictionary) -> bool:
	match id:
		"abanico":
			var dir := ranged_dir()
			facing = _dir_name(dir)
			state = State.ATTACK
			_play("attack")
			var n := int(v["arrows"])
			for i in n:
				var a := (i - (n - 1) / 2.0) * deg_to_rad(11.0)
				_shoot("arrow", dir.rotated(a), int(v["dmg"]), true, {"speed": 420.0, "range": 220.0})
		"salto":
			var away := -ranged_dir()
			facing = _dir_name(-away)
			_dash_dir = away
			_dash_left = float(v["time"])
			_dash_dmg = 0
			_dash_hit.clear()
			state = State.DASH
			_play("idle")
			FX.spawn(get_parent(), FX_PATH % "lightning_ring", global_position + Vector2(0, -6), 0.35, Color(0.7, 1.0, 0.6, 0.8))
		"ojo_halcon":
			Game.start_buff(float(v["time"]), int(v["bonus"]))
			Game.spawn_popup(global_position + Vector2(0, -36), "+%d de ataque" % v["bonus"], Color(0.7, 1, 0.5))
			FX.spawn(self, FX_PATH % "lightning_ring", Vector2(0, -12), 0.4, Color(0.6, 1.0, 0.5))
		"explosiva":
			var dir := ranged_dir()
			facing = _dir_name(dir)
			state = State.ATTACK
			_play("attack")
			_shoot("arrow", dir, int(v["dmg"]), true, {"radius": float(v["radius"]), "burst": FX_PATH % "explosion_small",
				"burst_scale": float(v["radius"]) / 26.0, "speed": 360.0, "range": 240.0, "tint": Color(1, 0.7, 0.4), "big": 1.2})
		"lluvia":
			state = State.ATTACK
			_play("attack")
			_arrow_rain(_skill_point(230.0, 90.0), float(v["radius"]), int(v["arrows"]), int(v["dmg"]))
		"perforante":
			var dir := ranged_dir()
			facing = _dir_name(dir)
			state = State.ATTACK
			_play("attack")
			_shoot("arrow", dir, int(v["dmg"]), true, {"pierce": true, "speed": 520.0, "range": float(v["length"]),
				"tint": Color(0.75, 0.95, 1.0), "big": 1.6})
			Game.shake(2.0, 0.12)
		"bola_fuego":
			var dir := ranged_dir()
			facing = _dir_name(dir)
			state = State.ATTACK
			_play("attack")
			_shoot("fireball", dir, int(v["dmg"]), true, {"radius": float(v["radius"]), "burst": FX_PATH % "fire_explosion",
				"burst_scale": float(v["radius"]) / 28.0, "speed": 250.0, "range": 230.0, "big": 1.7, "burn": maxi(1, int(v["dmg"]) / 4)})
		"parpadeo":
			var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
			if dir == Vector2.ZERO:
				dir = {"down": Vector2.DOWN, "up": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT}[facing]
			dir = dir.normalized()
			var to := global_position + dir * float(v["dist"])
			var w := get_tree().get_first_node_in_group("world")
			var steps := 0
			while w and w.has_method("is_walkable") and not w.is_walkable(to) and steps < 14:
				to -= dir * 8.0
				steps += 1
			FX.spawn(get_parent(), FX_PATH % "lightning_ring", global_position + Vector2(0, -8), 0.4, Color(0.75, 0.55, 1.0))
			global_position = to
			reset_physics_interpolation()
			FX.spawn(get_parent(), FX_PATH % "lightning_ring", global_position + Vector2(0, -8), 0.4, Color(0.75, 0.55, 1.0))
			_invulnerable = maxf(_invulnerable, 0.35)
		"barrera":
			var h := maxi(1, int(round(Game.max_hp * float(v["heal"]))))
			Game.heal_player(h)
			Game.spawn_popup(global_position + Vector2(0, -36), "+%d" % h, Color(0.5, 1, 0.55))
			_barrier = float(v["shield"])
			if is_instance_valid(_barrier_fx):
				_barrier_fx.queue_free()
			_barrier_fx = FX.spawn(self, FX_PATH % "lightning_ring", Vector2(0, -12), 0.42, Color(0.55, 0.85, 1.0, 0.85))
			_barrier_fx.set("loops", 99)
		"rayo":
			state = State.ATTACK
			_play("attack")
			_chain_lightning(int(v["dmg"]), int(v["chains"]))
		"nova":
			state = State.ATTACK
			_play("attack")
			var r := float(v["radius"])
			FX.spawn(get_parent(), FX_PATH % "lightning_ring", global_position + Vector2(0, -6), r / 52.0, Color(0.6, 0.9, 1.0))
			_ring(r)
			for m in get_tree().get_nodes_in_group("monsters"):
				var mon := m as Node2D
				if int(mon.get("hp")) > 0 and mon.global_position.distance_to(global_position) <= r:
					Game.hit_monster(mon, int(v["dmg"]), true, self)
					if is_instance_valid(mon) and mon.has_method("stun"):
						mon.stun(float(v["stun"]))
						mon.modulate = Color(0.6, 0.85, 1.0)
						mon.create_tween().tween_property(mon, "modulate", Color.WHITE, float(v["stun"]))
		"meteoro":
			state = State.ATTACK
			_play("attack")
			_meteor(_skill_point(240.0, 100.0), float(v["radius"]), int(v["dmg"]))
		_:
			return false
	return true


## The locked prey's spot if it is close enough, else the nearest monster, else a point ahead.
func _skill_point(max_dist: float, ahead: float) -> Vector2:
	if is_instance_valid(Game.target) and Game.target.global_position.distance_to(global_position) <= max_dist:
		return Game.target.global_position
	var near: Node2D = null
	for m in get_tree().get_nodes_in_group("monsters"):
		var mon := m as Node2D
		if int(mon.get("hp")) > 0 and mon.global_position.distance_to(global_position) <= max_dist * 0.8 and (near == null or mon.global_position.distance_to(global_position) < near.global_position.distance_to(global_position)):
			near = mon
	if near:
		return near.global_position
	return global_position + aim_dir() * ahead


func _arrow_rain(center: Vector2, radius: float, n: int, dmg: int) -> void:
	var mark := Node2D.new()
	mark.set_script(load("res://scripts/fx/slash_ring.gd"))
	mark.set("radius", radius)
	mark.position = center
	get_parent().add_child(mark)
	var fall := Vector2(0.18, 1.0).normalized()
	for i in n:
		var p := center + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * radius
		# most arrows rain on the monsters caught in the circle
		if randf() < 0.65:
			var inside: Array = []
			for m in get_tree().get_nodes_in_group("monsters"):
				if int(m.get("hp")) > 0 and (m as Node2D).global_position.distance_to(center) <= radius + 12.0:
					inside.append(m)
			if not inside.is_empty():
				p = (inside.pick_random() as Node2D).global_position + Vector2(randf_range(-6, 6), randf_range(-4, 4))
		var a := Node2D.new()
		a.set_script(PROJECTILE)
		a.set("kind", "drop")
		a.set("dir", fall)
		a.set("dmg", dmg)
		a.set("is_skill", true)
		a.set("source", self)
		a.set("tier", _look)
		a.set("speed", 520.0)
		a.set("max_range", 90.0)
		a.position = p - fall * 90.0
		get_parent().add_child(a)
		await get_tree().create_timer(0.06).timeout
		if not is_inside_tree():
			return


func _chain_lightning(dmg: int, chains: int) -> void:
	var first: Node2D = null
	if is_instance_valid(Game.target) and int(Game.target.get("hp")) > 0 and Game.target.global_position.distance_to(global_position) <= 240.0:
		first = Game.target
	else:
		var bd := 220.0
		for m in get_tree().get_nodes_in_group("monsters"):
			var mon := m as Node2D
			var d := mon.global_position.distance_to(global_position)
			if int(mon.get("hp")) > 0 and d < bd:
				first = mon
				bd = d
	if first == null:
		FX.spawn(get_parent(), FX_PATH % "lightning_strike", global_position + aim_dir() * 70.0 + Vector2(0, -56), 0.5)
		return
	var hit: Array = [first]
	var cur := first
	var power := float(dmg)
	FX.spawn(get_parent(), FX_PATH % "lightning_strike", cur.global_position + Vector2(0, -56), 0.5)
	Game.hit_monster(cur, int(power), true, self)
	Game.shake(3.0, 0.15)
	for i in chains:
		await get_tree().create_timer(0.09).timeout
		if not is_instance_valid(cur) or not is_inside_tree():
			return
		var nxt: Node2D = null
		var bd := 100.0
		for m in get_tree().get_nodes_in_group("monsters"):
			var mon := m as Node2D
			if mon in hit or int(mon.get("hp")) <= 0:
				continue
			var d := mon.global_position.distance_to(cur.global_position)
			if d < bd:
				nxt = mon
				bd = d
		if nxt == null:
			return
		var a := cur.global_position + Vector2(0, -10)
		var b := nxt.global_position + Vector2(0, -10)
		var bolt := FX.spawn(get_parent(), FX_PATH % "lightning_bolt", (a + b) / 2.0, 1.0, Color.WHITE, (b - a).angle())
		bolt.scale = Vector2(a.distance_to(b) / 200.0, 0.45)
		power *= 0.85
		Game.hit_monster(nxt, maxi(1, int(power)), true, self)
		hit.append(nxt)
		cur = nxt


func _meteor(at: Vector2, radius: float, dmg: int) -> void:
	var mark := Node2D.new()
	mark.set_script(load("res://scripts/fx/slash_ring.gd"))
	mark.set("radius", radius)
	mark.position = at
	get_parent().add_child(mark)
	var ball := AnimatedSprite2D.new()
	ball.sprite_frames = load("res://resources/sprite_frames/fx_fireball.tres")
	ball.play(&"right")
	ball.position = at + Vector2(-60, -150)
	ball.rotation = Vector2(60, 150).angle()
	ball.scale = Vector2(2.4, 2.4)
	ball.z_index = 6
	get_parent().add_child(ball)
	var t := ball.create_tween()
	t.tween_property(ball, "position", at + Vector2(0, -8), 0.5).set_ease(Tween.EASE_IN)
	t.tween_callback(ball.queue_free)
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	FX.spawn(get_parent(), FX_PATH % "explosion_big", at + Vector2(0, -20), radius / 30.0)
	Game.sfx("hit", 2.0, 0.0)
	Game.shake(6.0, 0.35)
	for m in get_tree().get_nodes_in_group("monsters"):
		var mon := m as Node2D
		if int(mon.get("hp")) > 0 and mon.global_position.distance_to(at) <= radius:
			Game.hit_monster(mon, dmg, true, self)
			if is_instance_valid(mon) and mon.has_method("apply_dot"):
				mon.apply_dot("burn", maxi(1, dmg / 3), 3.0, Color(1, 0.5, 0.2))


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
		if _dash_dmg > 0 and not mon in _dash_hit and int(mon.get("hp")) > 0 and mon.global_position.distance_to(global_position) < 22.0:
			_dash_hit.append(mon)
			Game.hit_monster(mon, _dash_dmg, true, self)
	if _dash_left <= 0.0:
		velocity = _dash_dir * walk_speed
		state = State.MOVE


## Called by monsters. `from` is the attacker position, used for knockback.
func take_damage(amount: int, from := Vector2.INF) -> void:
	if state == State.DEAD or state == State.DASH or _invulnerable > 0.0 or Game.editing:
		return
	if _barrier > 0.0:
		Game.spawn_popup(global_position + Vector2(0, -30), "Barrera", Color(0.6, 0.85, 1))
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
