extends Node2D
## Treasure chest on the plain. Opens once per save (E) and hands out equipment, gold and potions.
## `tier` (0-4) picks the chest look and how good the loot is.

const COLUMNS := [0, 2, 3, 4, 9]   # chest styles in chests.png (32x32 cells, 4 opening frames per column)

@export var chest_id := ""
@export var tier := 0

@onready var sprite: Sprite2D = $Sprite2D

var _opened := false


func _ready() -> void:
	add_to_group("chests")
	_opened = Game.is_chest_opened(chest_id)
	_set_frame(3 if _opened else 0)
	if _opened:
		$TalkArea.queue_free()


func _set_frame(f: int) -> void:
	sprite.region_rect = Rect2(COLUMNS[clampi(tier, 0, 4)] * 32, f * 32, 32, 32)


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
		t.tween_callback(_set_frame.bind(f))
		t.tween_interval(0.12)
	t.tween_callback(func(): Game.open_chest(chest_id, tier, global_position + Vector2(0, -26)))
