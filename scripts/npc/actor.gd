@tool
extends Node2D
## Animated character or object placed in the world (traders, fighters, sailors, boats...).
## Optional collision, dialogue and ambient speech bubbles.

@export var frames: SpriteFrames:
	set(v):
		frames = v
		_apply()
@export var sprite_offset := Vector2(0, -12):
	set(v):
		sprite_offset = v
		_apply()
@export var flip := false:
	set(v):
		flip = v
		_apply()
@export var collide := true
@export var npc_name := ""
@export_multiline var lines: PackedStringArray = []
@export var shouts: PackedStringArray = []
## Stall keepers answer nearby shoppers.
@export var seller := false
## Opens a service window instead of talking ("forge" = the blacksmith).
@export var opens := ""

var _shout_timer := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_apply()
	if Engine.is_editor_hint():
		return
	if seller:
		add_to_group("sellers")
	if not collide:
		$Body.queue_free()
	if lines.is_empty():
		$TalkArea.queue_free()
	$Prompt.visible = false
	var top := sprite_offset.y - _frame_h() * 0.5
	$Prompt.position.y = top + 2.0
	$Bubble.position.y = top - 1.0
	_shout_timer = randf_range(3.0, 15.0)


func _apply() -> void:
	var spr := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr == null:
		return
	spr.sprite_frames = frames
	spr.offset = sprite_offset
	spr.flip_h = flip
	if frames and frames.has_animation(&"default"):
		spr.play(&"default")
		var n := frames.get_frame_count(&"default")
		if n > 1 and not Engine.is_editor_hint():
			spr.frame = randi() % n


func _frame_h() -> float:
	if frames == null or frames.get_frame_count(&"default") == 0:
		return 32.0
	return frames.get_frame_texture(&"default", 0).get_height()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or shouts.is_empty() or Game.editing:
		return
	_shout_timer -= delta
	if _shout_timer <= 0.0:
		_shout_timer = randf_range(8.0, 20.0)
		if $OnScreen.is_on_screen():
			$Bubble.say(shouts[randi() % shouts.size()])


func set_focused(value: bool) -> void:
	$Prompt.visible = value


func interact(_player: Node) -> void:
	if opens == "forge":
		$Bubble.hide_now()
		Game.forge_requested.emit()
		return
	if opens == "stable":
		$Bubble.hide_now()
		Game.stable_requested.emit()
		return
	var special := Game.npc_override(npc_name)
	if not special.is_empty():
		$Bubble.hide_now()
		Game.show_dialogue(npc_name, special)
		return
	if lines.is_empty():
		return
	$Bubble.hide_now()
	Game.show_dialogue(npc_name, lines)


func react(text: String) -> void:
	if $OnScreen.is_on_screen():
		$Bubble.say(text, 2.4, true)
