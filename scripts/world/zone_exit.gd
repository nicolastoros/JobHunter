extends Area2D
## Exit trigger. Changes level when target_scene is set, otherwise shows a message.

@export_file("*.tscn") var target_scene := ""
@export var message := ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	if target_scene != "":
		Game.change_scene(target_scene)
	elif message != "":
		Game.toast(message)
