extends Node2D
## Interior room: places the player at the requested spawn and frames the camera on the room.

@export var title := ""
@export var room_size := Vector2i(320, 240)

@onready var player: Player = $Entities/Player


func _enter_tree() -> void:
	add_to_group("world")


func _ready() -> void:
	player.add_to_group("player")
	var spawn: Node2D = null
	if Game.pending_spawn != "":
		spawn = get_node_or_null("Spawns/" + Game.pending_spawn) as Node2D
	if spawn == null:
		spawn = get_node_or_null("Spawns/door") as Node2D
	if spawn:
		player.global_position = spawn.global_position
		player.facing = "up" if Game.pending_spawn != "stairs" else "down"
	Game.pending_spawn = ""
	Game.take_pending_position(player)
	player.reset_physics_interpolation()
	var vp := get_viewport().get_visible_rect().size
	var r := Rect2(Vector2.ZERO, Vector2(room_size))
	if r.size.x < vp.x:
		r = r.grow_individual((vp.x - r.size.x) / 2.0, 0, (vp.x - r.size.x) / 2.0, 0)
	if r.size.y < vp.y:
		r = r.grow_individual(0, (vp.y - r.size.y) / 2.0, 0, (vp.y - r.size.y) / 2.0)
	player.set_camera_limits(Rect2i(r))
	if title != "":
		Game.location_entered.emit(title)
