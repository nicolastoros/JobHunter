extends Node2D
## Your bed at home (E): rest to recover fully and save the game.


func _ready() -> void:
	var area := Area2D.new()
	area.name = "TalkArea"
	area.collision_layer = 8
	area.collision_mask = 0
	area.monitoring = false
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 14.0
	cs.shape = c
	area.add_child(cs)
	add_child(area)
	var prompt := Node2D.new()
	prompt.name = "Prompt"
	prompt.set_script(load("res://scripts/ui/talk_prompt.gd"))
	prompt.position = Vector2(0, -18)
	prompt.z_index = 10
	prompt.visible = false
	add_child(prompt)


func set_focused(value: bool) -> void:
	$Prompt.visible = value


func interact(_player: Node) -> void:
	Game.player_hp = Game.max_hp
	Game.mana = Game.max_mana
	Game.stamina = Game.max_stamina
	Game.stats_changed.emit()
	Game.show_dialogue("Tu casa", PackedStringArray(["Descansas un rato en tu cama. Te sientes como nuevo."]))
	Game.save_game()
