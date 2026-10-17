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
	var spawn := target_spawn
	if spawn == "":
		spawn = Game.return_spawn
	var scene := target_scene
	if scene == "":
		scene = Game.FIRST_LEVEL
	Game.travel(scene, spawn, return_marker)
