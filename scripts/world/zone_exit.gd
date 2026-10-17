extends Area2D
## Exit trigger at the edge of a map. Travels to target_scene (placing the player at target_spawn),
## or just shows a message when no target is set.

@export_file("*.tscn") var target_scene := ""
@export var target_spawn := ""
@export var message := ""

var _cooldown := 1.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_cooldown -= delta


func _on_body_entered(body: Node2D) -> void:
	if not body is Player or _cooldown > 0.0 or Game.editing:
		return
	if target_scene != "":
		Game.travel(target_scene, target_spawn)
	elif message != "":
		Game.toast(message)
