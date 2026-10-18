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


func _ready() -> void:
	_def = GameData.PETS[pet_id]
	add_to_group("pets")
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = load(_def["frames"])
	_sprite.offset = Vector2(0, -12)
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
		goal = p.global_position + Vector2(-18 * _side, 8)
		var pv: Vector2 = p.get("velocity")
		spd = maxf(spd, pv.length() * 1.05)
	var to := goal - global_position
	if to.length() < 4.0:
		if _attacking <= 0.0:
			_play("idle")
		return
	global_position += to.normalized() * minf(spd * delta, to.length())
	_facing = _dir(to)
	if _attacking <= 0.0:
		_play("run" if spd > 80.0 or to.length() > 40.0 else "walk")


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
