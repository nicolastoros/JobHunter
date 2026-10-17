@tool
class_name NPCBase
extends CharacterBody2D
## Shared NPC behaviour: animated sprite setup, talk prompt and dialogue.

@export var frames: SpriteFrames:
	set(value):
		frames = value
		_apply_visuals()
@export var sprite_offset_y := -12.0:
	set(value):
		sprite_offset_y = value
		_apply_visuals()
@export var npc_name := "Aldeano"
@export_multiline var lines: PackedStringArray = []

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var prompt: Node2D = $Prompt


func _ready() -> void:
	_apply_visuals()
	if Engine.is_editor_hint():
		return
	prompt.visible = false
	prompt.position.y = sprite_offset_y - _frame_height() * 0.5 - 4.0


func _apply_visuals() -> void:
	var spr := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr == null:
		return
	spr.sprite_frames = frames
	spr.offset = Vector2(0, sprite_offset_y)
	if frames and frames.has_animation(_default_animation()):
		spr.play(_default_animation())
		var count := frames.get_frame_count(_default_animation())
		if count > 1:
			spr.frame = randi() % count


func _default_animation() -> StringName:
	return &"default"


func _frame_height() -> float:
	if frames == null or not frames.has_animation(sprite.animation):
		return 32.0
	return frames.get_frame_texture(sprite.animation, 0).get_height()


func set_focused(value: bool) -> void:
	prompt.visible = value


func interact(_player: Node) -> void:
	if lines.is_empty():
		return
	Game.show_dialogue(npc_name, lines)
