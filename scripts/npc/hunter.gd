extends CharacterBody2D
## Another hunter of the Guild out on the plain. Roles:
##  - "fighter": stays around a zone and fights the monsters there (they fight back).
##  - "traveler": walks between landmarks along the paths.
##  - "runner": the same, but running.
## Shows its name and level, chats, greets the hero and can be talked to (E).

enum State { IDLE, MOVE, CHASE, ATTACK, HURT, DOWN }

@export var hunter_name := "Cazador"
@export var level := 1
@export var tier := 1
@export var role := "fighter"
@export var line := ""

var state := State.IDLE
var home := Vector2.ZERO
var landmarks: Array = []
var hp := 30
var max_hp := 30
var _world: Node
var _path := PackedVector2Array()
var _facing := "down"
var _wait := 0.0
var _target: Node2D = null
var _cool := 0.0
var _hit_done := false
var _knock := Vector2.ZERO
var _stuck := 0.0
var _chatter := 0.0
var _greet_cd := 0.0
var _rank := "E"
var _rest := 0.0   # breather after each fight
var _repath := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bubble: Node2D = $Bubble
@onready var notifier: VisibleOnScreenNotifier2D = $OnScreen


func _ready() -> void:
	add_to_group("hunters")
	sprite.sprite_frames = load("res://resources/sprite_frames/swordsman_lvl%d.tres" % clampi(tier, 1, 9))
	sprite.animation_finished.connect(_on_anim_finished)
	max_hp = 20 + level * 4
	hp = max_hp
	for h in GameData.HUNTERS:
		if h["name"] == hunter_name:
			_rank = GameData.GUILD_RANKS[GameData.guild_rank_index(Game.npc_score(h))][1]
	_world = get_tree().get_first_node_in_group("world")
	_wait = randf_range(0.2, 2.0)
	_chatter = randf_range(6.0, 16.0)
	_play("idle")


func is_dead() -> bool:
	return state == State.DOWN


func speed() -> float:
	return 92.0 if role == "runner" else (40.0 if role == "traveler" else 54.0)


func _physics_process(delta: float) -> void:
	if Game.editing:
		return
	_cool -= delta
	_greet_cd -= delta
	_chatter -= delta
	match state:
		State.DOWN:
			return
		State.HURT:
			velocity = _knock
			_knock = _knock.move_toward(Vector2.ZERO, 600 * delta)
			move_and_slide()
			return
		State.ATTACK:
			velocity = Vector2.ZERO
			if not _hit_done and sprite.frame >= 3:
				_hit_done = true
				if _alive(_target) and _target.global_position.distance_to(global_position) < 44.0:
					var div := 70.0 if _is_event(_target) else randf_range(6.0, 8.0)
					var dmg := maxi(1, int(ceil(int(_target.get("max_hp")) / div)))
					_target.call("take_hit", dmg, self, false)
			return
		State.IDLE:
			velocity = Vector2.ZERO
			_play("idle")
			hp = mini(hp + 1, max_hp) if randf() < 0.05 else hp
			_wait -= delta
			_rest -= delta
			if _rest <= 0.0 and _look_for_prey():
				return
			if _wait <= 0.0:
				_decide()
		State.MOVE:
			if _look_for_prey():
				return
			_follow(delta)
		State.CHASE:
			_chase(delta)
	_social()


# --- decisions ---------------------------------------------------------------------------

func _decide() -> void:
	var dest := home
	if role == "fighter":
		dest = home + Vector2(randf_range(-80, 80), randf_range(-60, 60))
	elif not landmarks.is_empty():
		dest = landmarks.pick_random()
	if _world and _world.has_method("find_path"):
		_path = _world.call("find_path", global_position, dest)
	else:
		_path = PackedVector2Array([dest])
	state = State.MOVE
	_stuck = 0.0


func _look_for_prey() -> bool:
	# a colossus on the loose: every hunter on the map answers the call
	for e in get_tree().get_nodes_in_group("event_boss"):
		if _alive(e):
			if _target != e:
				_say(["¡Un colosal! ¡Vamos!", "¡Todos al colosal!", "¡Por el Gremio!"].pick_random())
			_target = e
			state = State.CHASE
			_path = PackedVector2Array()
			return true
	if role != "fighter":
		return false
	var best: Node2D = null
	var bd := 95.0
	for m in get_tree().get_nodes_in_group("monsters"):
		if not _alive(m) or m.get("boss") and level < 40:
			continue
		if (m as Node2D).global_position.distance_to(home) > 200.0:
			continue
		var d := (m as Node2D).global_position.distance_to(global_position)
		if d < bd:
			best = m
			bd = d
	if best:
		_target = best
		state = State.CHASE
		return true
	return false


static func _alive(n) -> bool:
	return n != null and is_instance_valid(n) and int(n.get("hp")) > 0


func _follow(delta: float) -> void:
	if _path.is_empty():
		state = State.IDLE
		_wait = randf_range(1.5, 5.0) if role != "runner" else randf_range(0.3, 1.5)
		return
	var to := _path[0] - global_position
	if to.length() < 4.0:
		_path.remove_at(0)
		return
	var before := global_position
	velocity = to.normalized() * speed()
	move_and_slide()
	_facing = _dir(to)
	_play("run" if role == "runner" else "walk")
	if before.distance_to(global_position) < speed() * delta * 0.25:
		_stuck += delta
		if _stuck > 0.8:
			state = State.IDLE
			_wait = 0.5
	else:
		_stuck = 0.0


func _is_event(n) -> bool:
	return n != null and is_instance_valid(n) and n.get("event_boss") == true


func _chase(delta: float) -> void:
	var event := _is_event(_target)
	if not _alive(_target) or (not event and global_position.distance_to(home) > 260.0):
		if _target and not _alive(_target) and randf() < 0.6:
			_say(GameData.HUNTER_CHATTER.slice(0, 4).pick_random())
		_target = null
		state = State.IDLE
		_wait = randf_range(3.0, 7.0)
		_rest = _wait
		return
	var to := _target.global_position - global_position
	_facing = _dir(to)
	var reach := 34.0 if event else 22.0
	if event and to.length() >= reach:
		# long way to the colossus: follow a real path
		_repath -= delta
		if _path.is_empty() or _repath <= 0.0:
			_repath = 1.5
			if _world and _world.has_method("find_path"):
				_path = _world.call("find_path", global_position, _target.global_position)
		if not _path.is_empty():
			var step := _path[0] - global_position
			if step.length() < 5.0:
				_path.remove_at(0)
			else:
				velocity = step.normalized() * 80.0
				move_and_slide()
				_facing = _dir(step)
				_play("run")
			return
	if to.length() < reach:
		velocity = Vector2.ZERO
		if _cool <= 0.0:
			state = State.ATTACK
			_hit_done = false
			_cool = randf_range(1.3, 1.9)
			_play("attack", true)
		else:
			_play("idle")
		return
	var before := global_position
	velocity = to.normalized() * 70.0
	move_and_slide()
	_play("run")
	if before.distance_to(global_position) < 70.0 * delta * 0.2:
		_stuck += delta
		if _stuck > 1.2:
			_target = null
			state = State.IDLE
	else:
		_stuck = 0.0


## Monsters hit back.
func take_damage(amount: int, from := Vector2.INF) -> void:
	if state == State.DOWN:
		return
	hp -= amount
	if hp <= 0:
		_retreat()
		return
	state = State.HURT
	if from != Vector2.INF:
		_knock = (global_position - from).normalized() * 120.0
	_play("hurt", true)
	if hp < max_hp * 0.3 and randf() < 0.5:
		_say("¡Necesito una poción!")
		hp += max_hp / 2


func _retreat() -> void:
	state = State.DOWN
	velocity = Vector2.ZERO
	_say("¡Me retiro!")
	$CollisionShape2D.set_deferred("disabled", true)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 1.2)
	t.tween_interval(25.0)
	t.tween_callback(func():
		global_position = home
		reset_physics_interpolation()
		hp = max_hp
		$CollisionShape2D.set_deferred("disabled", false)
		state = State.IDLE
		_wait = 1.0)
	t.tween_property(self, "modulate:a", 1.0, 0.8)


func _on_anim_finished() -> void:
	if state == State.ATTACK:
		state = State.CHASE
	elif state == State.HURT:
		state = State.CHASE if _alive(_target) else State.IDLE


# --- social -----------------------------------------------------------------------------------

func _social() -> void:
	if _chatter <= 0.0:
		_chatter = randf_range(10.0, 25.0)
		if state != State.CHASE:
			_say(GameData.HUNTER_CHATTER.pick_random())
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p and _greet_cd <= 0.0 and p.global_position.distance_to(global_position) < 40.0:
		_greet_cd = 30.0
		_say(["¡Buena caza!", "Hola, colega.", "¿Vienes del Gremio?", "Suerte ahí fuera."].pick_random())


func _say(text: String) -> void:
	if notifier.is_on_screen():
		bubble.call("say", text, 2.4)


func set_focused(value: bool) -> void:
	$Prompt.visible = value


func interact(player: Node) -> void:
	_facing = _dir((player as Node2D).global_position - global_position)
	_play("idle")
	var place := 0
	var r := Game.ranking()
	for i in r.size():
		if r[i]["name"] == hunter_name:
			place = i + 1
	Game.show_dialogue("%s · Nv %d · rango %s" % [hunter_name, level, _rank],
		PackedStringArray([line if line != "" else "Buena caza.", "Voy en el puesto %d del ranking del Gremio." % place]))


func _play(base: String, restart := false) -> void:
	var anim := "%s_%s" % [base, _facing]
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim) and (sprite.animation != anim or restart):
		sprite.play(anim)


static func _dir(v: Vector2) -> String:
	if absf(v.x) > absf(v.y):
		return "right" if v.x > 0.0 else "left"
	return "down" if v.y > 0.0 else "up"


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if state == State.DOWN or not notifier.is_on_screen():
		return
	var f := ThemeDB.fallback_font
	var txt := "%s  Nv %d" % [hunter_name, level]
	var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
	var pos := Vector2(-w / 2.0, -30)
	draw_string_outline(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, 3, Color(0.08, 0.05, 0.03, 0.9))
	draw_string(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.75, 0.9, 1.0))
	if hp < max_hp:
		draw_rect(Rect2(-9, -28, 18, 2), Color(0.1, 0.06, 0.05, 0.85))
		draw_rect(Rect2(-9, -28, 18.0 * hp / max_hp, 2), Color(0.35, 0.85, 0.35))
