extends Node2D
## Companion bought at the stable. Follows the hero and fights: first the locked target (Tab),
## otherwise whatever is chasing the hero. Its bites count as the hero's (loot and experience).

var pet_id := "zorro"
var _def: Dictionary
var _sprite: AnimatedSprite2D
var _facing := "down"
var _target: Node2D = null
var _cool := 0.0
var _attacking := 0.0
var _side := 1.0
var _vel := Vector2.ZERO
var _moving := false
var _turn := 0.0   # time the movement has pointed another way (debounce for turning)
## Free roaming: the spot around the hero it is heading to, and when it picks another one.
var _offset := Vector2(-20, 4)
var _roam_left := 1.0
var _look_left := 2.0


func _ready() -> void:
	_def = GameData.PETS[pet_id]
	add_to_group("pets")
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = load(_def["frames"])
	_sprite.offset = Vector2(0, -12)
	_sprite.scale = Vector2.ONE * float(_def.get("scale", 1.0))
	add_child(_sprite)
	_side = [-1.0, 1.0].pick_random()
	_play("idle")


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


static func _alive(n) -> bool:
	return n != null and is_instance_valid(n) and int(n.get("hp")) > 0


func _pick_target(p: Node2D) -> Node2D:
	if _alive(Game.target) and Game.target.global_position.distance_to(p.global_position) < 170.0:
		return Game.target
	var best: Node2D = null
	var bd := 95.0
	for m in get_tree().get_nodes_in_group("monsters"):
		if not _alive(m):
			continue
		var d := (m as Node2D).global_position.distance_to(p.global_position)
		if d < bd and int(m.get("state")) in [2, 3]:   # chasing / attacking
			best = m
			bd = d
	return best


func _physics_process(delta: float) -> void:
	if Game.editing:
		return
	var p := _player()
	if p == null:
		return
	_cool -= delta
	_attacking -= delta
	if global_position.distance_to(p.global_position) > 280.0:
		global_position = p.global_position + Vector2(-16 * _side, 6)
		reset_physics_interpolation()
	_target = _pick_target(p)
	var goal: Vector2
	var spd := float(_def["speed"])
	if _target:
		goal = _target.global_position + Vector2(-12 if _target.global_position.x > global_position.x else 12, 2)
		if global_position.distance_to(_target.global_position) < 20.0:
			_facing = _dir(_target.global_position - global_position)
			if _cool <= 0.0:
				_cool = float(_def["rate"])
				_attacking = 0.35
				_play("attack", true)
				var dmg := maxi(1, int(round(Game.attack() * float(_def["power"]))))
				_target.call("take_hit", dmg, p, false)
			elif _attacking <= 0.0:
				_play("idle")
			return
	else:
		goal = p.global_position + _roam(p, delta)
	var to := goal - global_position
	var dist := to.length()
	var hero_vel: Vector2 = p.get("velocity") if _target == null else Vector2.ZERO
	# proportional follow + the hero's own velocity: keeps pace without overshooting
	var desired := to * 4.0 + hero_vel
	if dist < 3.0 and hero_vel.length() < 10.0:
		desired = Vector2.ZERO
	var cap := maxf(spd, hero_vel.length() * 1.2)
	if _target == null and hero_vel.length() < 10.0 and dist < 70.0:
		cap = spd * 0.45   # with the hero standing still it ambles around instead of dashing
	if desired.length() > cap:
		desired = desired.normalized() * cap
	_vel = _vel.move_toward(desired, 700.0 * delta)
	global_position += _vel * delta
	# turn only when the movement clearly points another way
	if _vel.length() > 12.0:
		var d := _dir(_vel)
		if d != _facing:
			_turn += delta
			if _turn > 0.06:
				_facing = d
				_turn = 0.0
		else:
			_turn = 0.0
	if _attacking <= 0.0:
		var sp := _vel.length()
		if sp < 6.0:
			# standing: now and then it looks around, or back at the hero
			_look_left -= delta
			if _look_left <= 0.0:
				_look_left = randf_range(1.5, 4.0)
				_facing = _dir(p.global_position - global_position) if randf() < 0.6 else ["down", "left", "right", "up"].pick_random()
			_play("idle")
		elif sp > 85.0 or (sp > 65.0 and _sprite.animation.begins_with("run")):
			_play("run")
		else:
			_play("walk")


## Where to be, relative to the hero. It keeps its own spot for a few seconds (sometimes left, sometimes
## right, behind, a little ahead when the hero rests...) and then picks another one. While the hero
## moves the spot is never in front of them, so it doesn't run across their path looking backwards.
func _roam(p: Node2D, delta: float) -> Vector2:
	var hv: Vector2 = p.get("velocity")
	var moving := hv.length() > 20.0
	_roam_left -= delta
	if _roam_left <= 0.0:
		if moving:
			var back := -hv.normalized()
			_offset = back.rotated(randf_range(-1.7, 1.7)) * randf_range(16.0, 30.0)
			_roam_left = randf_range(3.0, 6.0)
		else:
			_offset = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(14.0, 48.0)
			_offset.y *= 0.7
			_roam_left = randf_range(2.0, 5.0)
	if moving:
		var dir := hv.normalized()
		var ahead := _offset.dot(dir)
		if ahead > 2.0:
			_offset -= dir * ahead * 2.0   # mirror it behind the hero
		if _offset.length() > 32.0:
			_offset = _offset.normalized() * 30.0
	return _offset


func _play(base: String, restart := false) -> void:
	var a := "%s_%s" % [base, _facing]
	if not _sprite.sprite_frames.has_animation(a):
		a = "run_%s" % _facing
	if _sprite.animation != a or restart:
		_sprite.play(a)
		if restart:
			_sprite.frame = 0


static func _dir(v: Vector2) -> String:
	if absf(v.x) > absf(v.y):
		return "right" if v.x > 0.0 else "left"
	return "down" if v.y > 0.0 else "up"
