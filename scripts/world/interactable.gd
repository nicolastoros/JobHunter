extends Node2D
## Generic interactable spot (quest board, signs...). Shows the "E" prompt and runs an action.

@export_enum("quest_board", "sign") var action := "quest_board"
@export_multiline var text := ""
@export var radius := 14.0


func _ready() -> void:
	var area := Area2D.new()
	area.collision_layer = 8
	area.collision_mask = 0
	area.monitoring = false
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	shape.shape = c
	area.add_child(shape)
	add_child(area)
	$Prompt.visible = false
	if action == "quest_board":
		var badge := Node2D.new()
		badge.set_script(load("res://scripts/ui/poi_badge.gd"))
		badge.set("kind", "board")
		badge.position = Vector2(0, -34)
		add_child(badge)


func set_focused(value: bool) -> void:
	$Prompt.visible = value


func interact(_player: Node) -> void:
	match action:
		"quest_board":
			Game.quest_board_requested.emit()
		"sign":
			Game.show_dialogue("Cartel", PackedStringArray([text]))
