extends Node2D
## A projectile of the archer or the mage: flies straight from the hero and hits the first monster in
## its way. Kinds:
##  "arrow"    the archer's arrow (`pierce` = goes through everything in its path);
##  "fireball" the mage's fireball;
##  "drop"     an arrow falling from the sky (Lluvia de flechas): it hits where it lands.
## `radius` > 0 makes it burst on impact and hurt everything around (`burst` = the explosion to show).
## Walls stop it (the walk grid of the region); a fireball bursts against them too.

const ARROW_TEX := "res://assets/sprites/fx/classes/arrow_lvl%d.png"
const FIREBALL := "res://resources/sprite_frames/fx_fireball.tres"
const FX := preload("res://scripts/fx/anim_fx.gd")

var kind := "arrow"
var dir := Vector2.RIGHT
var speed := 380.0
var max_range := 230.0
var dmg := 1
var is_skill := false
var radius := 0.0
var pierce := false
var burst := ""          # SpriteFrames of the explosion ("" = none)
var burst_scale := 1.0
var big := 1.0           # size of the projectile
var tier := 1            # look tier of the archer (fancier arrows)
var tint := Color.WHITE
var source: Node2D
var burn := 0            # damage over time left on the monsters hit (fire)

var _travel := 0.0
var _hit: Array = []
var _world: Node


func _ready() -> void:
	_world = get_tree().get_first_node_in_group("world")
	z_index = 4
	dir = dir.normalized()
	if kind == "fireball":
		var a := AnimatedSprite2D.new()
		a.sprite_frames = load(FIREBALL)
		a.play(&"right")
		a.rotation = dir.angle()
		a.scale = Vector2(big, big)
		a.modulate = tint
		add_child(a)
		var glow := PointLight2D.new()
		glow.texture = _glow_tex()
		glow.color = Color(1.0, 0.55, 0.2)
		glow.energy = 0.7
		glow.texture_scale = 0.5 * big
		add_child(glow)
	else:
		var s := Sprite2D.new()
		s.texture = load(ARROW_TEX % clampi(tier, 1, 9))
		s.region_enabled = true
		s.region_rect = Rect2(75, 18, 10, 3)
		s.rotation = dir.angle()
		s.scale = Vector2(1.4 * big, 1.4 * big)
		s.modulate = tint
		add_child(s)
		if pierce:
			var trail := Line2D.new()
			trail.width = 2.0
			trail.default_color = Color(tint.r, tint.g, tint.b, 0.45)
			trail.points = PackedVector2Array([Vector2.ZERO, -dir * 22.0])
			add_child(trail)


static func _glow_tex() -> Texture2D:
	var g := GradientTexture2D.new()
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 0.5)
	var gr := Gradient.new()
	gr.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	g.gradient = gr
	g.width = 64
	g.height = 64
	return g


func _physics_process(delta: float) -> void:
	var step := speed * delta
	position += dir * step
	_travel += step
	if kind == "drop":
		if _travel >= max_range:
			_land()
		return
	# monsters in the way (their body is a little above their feet)
	for m in get_tree().get_nodes_in_group("monsters"):
		if m in _hit or int(m.get("hp")) <= 0:
			continue
		var body: Vector2 = (m as Node2D).global_position + Vector2(0, -8)
		var reach := 11.0 * maxf(1.0, float(m.get("sprite_scale")) if m.get("sprite_scale") != null else 1.0)
		if body.distance_to(global_position) <= reach:
			if radius > 0.0:
				_explode()
				return
			_strike(m)
			if not pierce:
				queue_free()
				return
	# walls: the grid of the region, under the projectile
	if _world and _world.has_method("is_walkable") and _travel > 14.0 and not _world.is_walkable(global_position + Vector2(0, 10)):
		if radius > 0.0:
			_explode()
		else:
			queue_free()
		return
	if _travel >= max_range:
		if radius > 0.0 and kind == "fireball":
			_explode()
		else:
			_fade()


func _strike(m: Node) -> void:
	_hit.append(m)
	Game.hit_monster(m, dmg, is_skill, source if is_instance_valid(source) else self)
	if burn > 0 and is_instance_valid(m) and m.has_method("apply_dot"):
		m.apply_dot("burn", burn, 2.0, Color(1, 0.5, 0.2))
	if kind == "arrow" and is_instance_valid(m) and m.has_method("spawn_spark"):
		m.spawn_spark()


func _explode() -> void:
	set_physics_process(false)
	if burst != "":
		FX.spawn(get_parent(), burst, global_position, burst_scale, Color.WHITE)
	Game.sfx("hit", 0.0, 0.1)
	Game.shake(2.0 + radius / 30.0, 0.15)
	for m in get_tree().get_nodes_in_group("monsters"):
		if int(m.get("hp")) > 0 and (m as Node2D).global_position.distance_to(global_position + Vector2(0, 8)) <= radius:
			_strike(m)
	queue_free()


func _land() -> void:
	set_physics_process(false)
	for m in get_tree().get_nodes_in_group("monsters"):
		if int(m.get("hp")) > 0 and (m as Node2D).global_position.distance_to(global_position + Vector2(0, 6)) <= 16.0:
			_strike(m)
	_fade()


func _fade() -> void:
	set_physics_process(false)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.15)
	t.tween_callback(queue_free)
