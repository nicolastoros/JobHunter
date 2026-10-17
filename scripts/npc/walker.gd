extends CharacterBody2D
## Townsperson. Plans walkable routes with the world's A* grid (respecting walls, stalls, houses...)
## and lives a small routine according to its mode:
##   stroller: walks between landmarks, pausing a few seconds.
##   loiterer: stays put for long stretches (chatting, looking around) and only moves now and then.
##   guard:    patrols slowly between landmarks and greets the player.
## With `brain` it may also go home (enter the door), go shopping and chat with neighbours.

enum State { IDLE, MOVING, ACTIVITY, CHAT, HIDDEN, TALK }

const CONVERSATIONS := [
	["¿Viste el pedido urgente del Gremio?", "Sí. Nadie quiere ir al norte.", "No me extraña."],
	["Buenos días.", "Buenos días. ¿Vas al mercado?", "Como cada mañana."],
	["Dicen que llegó un barco con especias.", "Entonces el pan de Rosa volverá a tener canela."],
	["¿Cómo sigue tu madre?", "Mejor, gracias. Ezra le dio un tónico.", "Me alegro."],
	["Mi hijo quiere ser cazador.", "¿Y lo vas a dejar?", "Primero que entrene en el cuartel."],
	["¿Escuchaste al bardo anoche?", "Sí. Toda la plaza lo escuchaba."],
	["Las liebres se comieron mis repollos.", "Deja un pedido en el Gremio.", "Ya lo hice."],
	["Hace calor.", "Vamos a la fuente un rato."],
	["¿Has ido a la llanura?", "Solo hasta el camino. Más allá hay monstruos."],
]
const SHOP_LINES := ["¿Cuánto cuesta esto?", "Me llevo dos.", "¿Está fresco?", "¿Me haces un descuento?", "Esto se ve bien."]
const SELLER_LINES := ["Gracias, vuelve pronto.", "Buena elección.", "Es de lo mejor que tengo.", "Te lo dejo a buen precio."]
const GREETINGS := ["Hola.", "Buen día.", "Suerte en tu viaje.", "¿Eres nuevo por aquí?"]
const GUARD_GREETINGS := ["Buen día, cazador.", "No te metas en problemas.", "Ten cuidado en la llanura."]

@export var frames: SpriteFrames
@export var sprite_offset_y := -13.0
@export var npc_name := "Vecino"
@export var lines: PackedStringArray = []
@export var start_node := 0
@export var speed := 26.0
@export var tint := Color.WHITE
@export var brain := false
@export var guard := false
@export_enum("stroller", "loiterer", "guard") var mode := "stroller"

var state := State.IDLE
var _world: Node
var _path := PackedVector2Array()
var _goal_kind := ""
var _facing := "down"
var _wait := 0.0
var _bubble_timer := 0.0
var _chat_cooldown := 0.0
var _greet_cooldown := 0.0
var _stuck := 0.0
var _home := Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bubble: SpeechBubble = $Bubble
@onready var prompt: Node2D = $Prompt
@onready var notifier: VisibleOnScreenNotifier2D = $OnScreen
@onready var body_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("walkers")
	collision_mask = 1
	sprite.sprite_frames = frames
	sprite.offset.y = sprite_offset_y
	sprite.modulate = tint
	prompt.visible = false
	bubble.position.y = sprite_offset_y - 14.0
	prompt.position.y = sprite_offset_y - 12.0
	_home = global_position
	_bubble_timer = randf_range(3.0, 16.0)
	_chat_cooldown = randf_range(5.0, 20.0)
	speed *= randf_range(0.85, 1.12) * (0.75 if mode == "guard" else 1.0)
	_facing = ["down", "left", "right", "down"].pick_random()
	_wait = randf_range(0.5, 3.0) if mode == "stroller" else randf_range(4.0, 25.0)
	_play("idle")
	Game.dialogue_finished.connect(_on_dialogue_finished)


func _physics_process(delta: float) -> void:
	if Game.editing:
		return
	if _world == null:
		_world = get_tree().get_first_node_in_group("world")
		if _world == null or not _world.has_method("find_path"):
			_world = null
			return
	_chat_cooldown -= delta
	_greet_cooldown -= delta
	_update_bubble(delta)
	match state:
		State.TALK, State.CHAT, State.HIDDEN:
			velocity = Vector2.ZERO
			return
		State.IDLE, State.ACTIVITY:
			velocity = Vector2.ZERO
			if brain:
				_try_chat()
			_try_greet()
			_wait -= delta
			if _wait <= 0.0:
				if state == State.ACTIVITY:
					state = State.IDLE
				_decide()
			elif mode == "loiterer" and randf() < delta * 0.15:
				_facing = ["down", "left", "right", "up"].pick_random()
				_play("idle")
			return
		State.MOVING:
			_move(delta)


# --- decisions ----------------------------------------------------------------

func _decide() -> void:
	if brain and randf() < 0.45:
		var r := randf()
		if r < 0.45:
			var home: Variant = _world.random_point_near("home_points", global_position, 380.0)
			if home != null and _travel(home, "home"):
				return
		else:
			var shop: Variant = _world.random_point_near("shop_points", global_position, 480.0)
			if shop != null and _travel(shop, "shop"):
				return
	var dest: Vector2
	match mode:
		"loiterer":
			# short stroll around their usual spot
			dest = _home + Vector2(randf_range(-56, 56), randf_range(-40, 40))
			if not _world.is_walkable(dest):
				dest = _world.node_position(_world.nearest_node(_home))
		"guard":
			dest = _world.node_position(_neighbor_landmark(2))
		_:
			dest = _world.node_position(_neighbor_landmark(1)) + Vector2(randf_range(-10, 10), randf_range(-8, 8))
	if not _travel(dest, "wander"):
		_wait = 2.0


func _neighbor_landmark(depth: int) -> int:
	var n: int = _world.nearest_node(global_position)
	for i in depth:
		var nb: PackedInt32Array = _world.neighbors(n)
		if nb.is_empty():
			break
		n = nb[randi() % nb.size()]
	return n


func _travel(dest: Vector2, kind: String) -> bool:
	var p: PackedVector2Array = _world.find_path(global_position, dest)
	if p.is_empty():
		return false
	if p.size() > 1:
		p.remove_at(0)
	_path = p
	_goal_kind = kind
	state = State.MOVING
	_stuck = 0.0
	return true


func _move(delta: float) -> void:
	if _path.is_empty():
		_arrive()
		return
	var target := _path[0]
	var to := target - global_position
	if to.length() < 3.0:
		_path.remove_at(0)
		return
	var player := _player()
	if player and player.global_position.distance_to(global_position + to.normalized() * 10.0) < 11.0:
		velocity = Vector2.ZERO
		_play("idle")
		return
	var before := global_position
	velocity = to.normalized() * speed
	move_and_slide()
	_facing = _dir(to)
	_play("walk")
	if before.distance_to(global_position) < speed * delta * 0.3:
		_stuck += delta
		if _stuck > 0.8:
			_stuck = 0.0
			state = State.IDLE
			_wait = randf_range(0.5, 1.5)
	else:
		_stuck = 0.0


func _arrive() -> void:
	velocity = Vector2.ZERO
	match _goal_kind:
		"home":
			_enter_home()
			return
		"shop":
			state = State.ACTIVITY
			_facing = "up"
			_play("idle")
			_wait = randf_range(5.0, 8.0)
			_say(SHOP_LINES.pick_random())
			_seller_reply()
			return
	state = State.IDLE
	_play("idle")
	match mode:
		"loiterer":
			_wait = randf_range(15.0, 45.0)
		"guard":
			_wait = randf_range(4.0, 10.0)
		_:
			_wait = randf_range(1.5, 7.0) if randf() < 0.7 else randf_range(8.0, 16.0)
	if randf() < 0.5:
		_facing = ["down", "left", "right"].pick_random()
		_play("idle")


# --- routines -----------------------------------------------------------------

func _enter_home() -> void:
	state = State.HIDDEN
	_facing = "up"
	_play("walk")
	bubble.hide_now()
	var t := create_tween()
	t.tween_property(self, "global_position", global_position + Vector2(0, -6), 0.35)
	t.parallel().tween_property(sprite, "modulate:a", 0.0, 0.35)
	t.tween_callback(func(): body_shape.set_deferred("disabled", true); visible = false)
	t.tween_interval(randf_range(12.0, 35.0))
	t.tween_callback(_leave_home)


func _leave_home() -> void:
	visible = true
	body_shape.set_deferred("disabled", false)
	_facing = "down"
	_play("walk")
	var t := create_tween()
	t.tween_property(sprite, "modulate:a", tint.a, 0.35)
	t.parallel().tween_property(self, "global_position", global_position + Vector2(0, 8), 0.35)
	t.tween_callback(func(): state = State.IDLE; _wait = randf_range(1.0, 4.0); _play("idle"))


func _seller_reply() -> void:
	await get_tree().create_timer(3.2).timeout
	var best: Node = null
	var best_d := 60.0
	for a in get_tree().get_nodes_in_group("sellers"):
		var d := (a as Node2D).global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = a
	if best:
		best.react(SELLER_LINES.pick_random())


# --- chatting -----------------------------------------------------------------

func is_free_for_chat() -> bool:
	return brain and visible and state == State.IDLE and _chat_cooldown <= 0.0


func _try_chat() -> void:
	if not is_free_for_chat():
		return
	_chat_cooldown = 1.0
	for other in get_tree().get_nodes_in_group("walkers"):
		if other == self or not other.is_free_for_chat():
			continue
		if (other as Node2D).global_position.distance_to(global_position) < 40.0 and randf() < 0.5:
			var convo: Array = CONVERSATIONS.pick_random()
			start_chat(other, convo, true)
			other.start_chat(self, convo, false)
			return


func start_chat(partner: Node, convo: Array, first: bool) -> void:
	state = State.CHAT
	_chat_cooldown = randf_range(35.0, 70.0)
	_facing = _dir((partner as Node2D).global_position - global_position)
	_play("idle")
	for i in convo.size():
		if (i % 2 == 0) == first:
			get_tree().create_timer(0.4 + i * 2.6).timeout.connect(func(): if state == State.CHAT: _say(convo[i], 2.2))
	get_tree().create_timer(0.8 + convo.size() * 2.6).timeout.connect(_end_chat)


func _end_chat() -> void:
	if state == State.CHAT:
		state = State.IDLE
		_wait = randf_range(1.0, 3.0)


func _try_greet() -> void:
	if _greet_cooldown > 0.0:
		return
	var p := _player()
	if p and p.global_position.distance_to(global_position) < 34.0:
		_greet_cooldown = randf_range(30.0, 60.0)
		if randf() < 0.5:
			_facing = _dir(p.global_position - global_position)
			_play("idle")
			_say((GUARD_GREETINGS if mode == "guard" else GREETINGS).pick_random())


# --- bubbles & talking --------------------------------------------------------

func _say(text: String, duration := 2.6) -> void:
	if notifier.is_on_screen():
		bubble.say(text, duration)


func _update_bubble(delta: float) -> void:
	if lines.is_empty() or state in [State.CHAT, State.HIDDEN, State.TALK]:
		return
	_bubble_timer -= delta
	if _bubble_timer <= 0.0:
		_bubble_timer = randf_range(10.0, 24.0)
		if notifier.is_on_screen():
			bubble.say(lines[randi() % lines.size()])


func _play(base: String) -> void:
	var anim := "%s_%s" % [base, _facing]
	if frames and frames.has_animation(anim) and sprite.animation != anim:
		sprite.play(anim)


static func _dir(v: Vector2) -> String:
	if absf(v.x) > absf(v.y):
		return "right" if v.x > 0.0 else "left"
	return "down" if v.y > 0.0 else "up"


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


func set_focused(value: bool) -> void:
	prompt.visible = value


func interact(player: Node) -> void:
	if lines.is_empty() or state == State.HIDDEN:
		return
	state = State.TALK
	velocity = Vector2.ZERO
	bubble.hide_now()
	_facing = _dir((player as Node2D).global_position - global_position)
	_play("idle")
	Game.show_dialogue(npc_name, PackedStringArray([lines[randi() % lines.size()]]))


func _on_dialogue_finished() -> void:
	if state == State.TALK:
		state = State.IDLE
		_wait = randf_range(1.0, 3.0)
