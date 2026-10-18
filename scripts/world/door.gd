extends Area2D
## Doorway: walking into it in the given direction (or pressing E) moves the player to another scene.

@export_file("*.tscn") var target_scene := ""
## Spawn marker in the target scene. Empty = go back to the remembered exterior door.
@export var target_spawn := ""
## Marker in THIS scene to return to later (set on exterior doors).
@export var return_marker := ""
## Direction the player must push to go through: "up", "down", "left", "right".
@export var direction := "up"
@export var label := ""
## The building's painted door, animated when the hero walks in (set by the world generator).
@export var leaf_texture: Texture2D
@export var leaf_region := Rect2()
@export var door_rect := Rect2()
@export var leaf_flip := false

var _inside := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	body_entered.connect(func(b): if b is Player: _inside = true)
	body_exited.connect(func(b): if b is Player: _inside = false)


func _physics_process(_delta: float) -> void:
	if not _inside or Game.input_locked:
		return
	if Input.is_action_pressed("move_" + direction):
		_go()


func _go() -> void:
	_inside = false
	if leaf_texture and target_scene.contains("/interiors/") and not get_tree().current_scene.scene_file_path.contains("/interiors/"):
		await _open_door()
	var spawn := target_spawn
	if spawn == "":
		spawn = Game.return_spawn
	var scene := target_scene
	if scene == "":
		scene = Game.FIRST_LEVEL
	Game.travel(scene, spawn, return_marker)


## The door swings open and the hero steps into the doorway before the scene changes.
func _open_door() -> void:
	Game.input_locked = true
	var fx := Node2D.new()
	fx.set_script(load("res://scripts/fx/door_open.gd"))
	fx.set("texture", leaf_texture)
	fx.set("region", leaf_region)
	fx.set("flip", leaf_flip)
	fx.position = Vector2(door_rect.position.x, door_rect.end.y)
	var parent := get_tree().current_scene.get_node_or_null("Entities")
	if parent == null:
		parent = get_tree().current_scene
	parent.add_child(fx)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	await get_tree().create_timer(0.2).timeout
	if player:
		# the hero stays in front of the dark doorway while stepping in
		player.z_index = 2
		player.set("velocity", Vector2.ZERO)
		var sp := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if sp and sp.sprite_frames.has_animation(&"walk_up"):
			sp.play(&"walk_up")
		var t := player.create_tween()
		t.tween_property(player, "global_position:y", player.global_position.y - 8.0, 0.3)
	await get_tree().create_timer(0.3).timeout
