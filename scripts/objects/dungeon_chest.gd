extends Node2D
## The chest at the end of a dungeon: opens with E, pays out the rewards and shows the victory panel.

const SHEET := preload("res://assets/sprites/field/chests.png")

var rank := "C"
var secs := 0.0
var _opened := false
var _sprite: Sprite2D
var _t := 0.0


func _ready() -> void:
	add_to_group("chests")
	_sprite = Sprite2D.new()
	_sprite.texture = SHEET
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(9 * 32, 0, 32, 32)
	_sprite.offset = Vector2(0, -12)
	_sprite.scale = Vector2(1.4, 1.4)
	add_child(_sprite)
	var area := Area2D.new()
	area.name = "TalkArea"
	area.collision_layer = 8
	area.collision_mask = 0
	area.monitoring = false
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 22.0
	cs.shape = c
	area.add_child(cs)
	area.position = Vector2(0, -6)
	add_child(area)
	var prompt := Node2D.new()
	prompt.name = "Prompt"
	prompt.set_script(load("res://scripts/ui/talk_prompt.gd"))
	prompt.position = Vector2(0, -40)
	prompt.z_index = 10
	prompt.visible = false
	add_child(prompt)
	var beam := Node2D.new()
	beam.set_script(load("res://scripts/fx/loot_beam.gd"))
	beam.set("color", Color(1, 0.8, 0.3))
	add_child(beam)


func set_focused(value: bool) -> void:
	$Prompt.visible = value and not _opened


func interact(_player: Node) -> void:
	if _opened:
		return
	_opened = true
	$Prompt.visible = false
	$TalkArea.queue_free()
	var t := create_tween()
	for f in [1, 2, 3]:
		t.tween_callback(func(): _sprite.region_rect = Rect2(9 * 32, f * 32, 32, 32))
		t.tween_interval(0.12)
	await t.finished
	Game.sfx("chest", 0.0, 0.0)
	var got := Game.dungeon_rewards(rank, secs)
	Game.dungeon_victory_panel.emit(rank, secs, got)
