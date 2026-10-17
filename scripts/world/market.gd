extends Node2D
## Market hub level: sets camera bounds and announces the location.

@export var map_size := Vector2i(48, 36)
@export var location_name := "Mercado de Valdoria"

@onready var ground: TileMapLayer = $Ground
@onready var player: Player = $Entities/Player


func _ready() -> void:
	var tile := ground.tile_set.tile_size
	player.set_camera_limits(Rect2i(Vector2i.ZERO, map_size * tile))
	Game.location_entered.emit(location_name)
