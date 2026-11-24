extends Node
## The story's cast (the Four Winds, Darío, the hooded stranger...): puts each one where the story says
## they are right now in this region (GameData.STORY_CAST), and moves them on as the story advances:
## they fade in when they arrive and fade out when they leave. Added by the world and interior scripts.

const ACTOR := preload("res://scenes/npc/actor.tscn")

var _here := {}   # cast id -> actor node


func _ready() -> void:
	Game.objective_changed.connect(_sync)
	_sync.call_deferred()


## Where `id` stands in `map` at story step `step` (in pixels), or INF if they are not there.
static func spot_of(id: String, map: String, step: int) -> Vector2:
	for s in GameData.STORY_CAST[id]["spots"]:
		if step >= int(s[0]) and step <= int(s[1]) and String(s[2]) == map:
			return (s[3] as Vector2) * 16.0
	return Vector2.INF


static func lines_of(id: String, step: int) -> PackedStringArray:
	var out := PackedStringArray()
	for l in GameData.STORY_CAST[id]["lines"]:
		if step >= int(l[0]):
			out = PackedStringArray(l[1])
	return out


func _sync() -> void:
	var scene := get_parent()
	var ents := scene.get_node_or_null("Entities")
	if ents == null:
		return
	var map := Game.map_file()
	var step := Game.story_step if Game.tutorial_step >= 4 else 0
	for id in GameData.STORY_CAST:
		var c: Dictionary = GameData.STORY_CAST[id]
		var at := spot_of(id, map, step)
		var cur: Node2D = _here.get(id)
		if cur != null and not is_instance_valid(cur):
			cur = null
		if at == Vector2.INF:
			if cur:
				_leave(cur)
			_here.erase(id)
			continue
		var lines := lines_of(id, step)
		if cur:
			cur.set("lines", lines)
			continue
		var a := ACTOR.instantiate()
		a.set("frames", load(String(c["frames"])))
		a.set("sprite_offset", c["offset"])
		a.set("npc_name", String(c["name"]))
		a.set("lines", lines)
		a.set("collide", false)
		a.position = _free_spot(scene, at)
		a.name = "Cast_" + id
		ents.add_child(a)
		_here[id] = a
		a.modulate.a = 0.0
		a.create_tween().tween_property(a, "modulate:a", 1.0, 0.6)


func _leave(a: Node2D) -> void:
	# let them finish what they are saying first
	await get_tree().process_frame
	while is_instance_valid(a) and Game.input_locked:
		await get_tree().create_timer(0.2).timeout
	if not is_instance_valid(a):
		return
	var t := a.create_tween()
	t.tween_property(a, "modulate", Color(0.7, 0.5, 1.0, 0.0), 0.8)
	t.tween_callback(a.queue_free)


## Outdoors, step off any wall or tree the spot may fall on.
func _free_spot(scene: Node, at: Vector2) -> Vector2:
	if not scene.has_method("is_walkable") or scene.call("is_walkable", at):
		return at
	for r in [16.0, 32.0, 64.0]:
		var free: Vector2 = scene.call("_walkable_in", Rect2(at - Vector2(r, r), Vector2(r, r) * 2.0))
		if free != Vector2.INF:
			return free
	return at
