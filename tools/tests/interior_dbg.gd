extends SceneTree
## Captures every interior with collision (blue), door areas (red) and spawn markers (green) drawn on top.
var out := ""
class Overlay extends Node2D:
	var scene: Node
	func _draw() -> void:
		for cs in scene.find_children("*", "CollisionShape2D", true, false):
			var s := cs as CollisionShape2D
			if s.shape is RectangleShape2D:
				var sz: Vector2 = (s.shape as RectangleShape2D).size
				var area: bool = s.get_parent() is Area2D
				var col := Color(1, 0.1, 0.1, 0.45) if area else Color(0.1, 0.4, 1, 0.35)
				if area and s.get_parent().get_parent() != scene:
					continue
				draw_rect(Rect2(s.global_position - sz / 2.0, sz), col)
		for m in scene.find_children("*", "Marker2D", true, false):
			draw_circle((m as Node2D).global_position, 4, Color(0, 1, 0.3))
func _initialize() -> void:
	out = OS.get_environment("CAPTURE_DIR")
	_run.call_deferred()
func _run() -> void:
	for name in ["home", "house_red", "port_house", "guild_1f"]:
		change_scene_to_file("res://scenes/interiors/%s.tscn" % name)
		await create_timer(0.8).timeout
		var hud = current_scene.get_node_or_null("HUD")
		if hud: hud.visible = false
		var p = current_scene.get_node("Entities/Player")
		p.visible = false
		var o := Overlay.new()
		o.scene = current_scene
		o.z_index = 100
		current_scene.add_child(o)
		var cam: Camera2D = p.get_node("Camera2D")
		cam.limit_left = -10000; cam.limit_top = -10000; cam.limit_right = 10000; cam.limit_bottom = 10000
		var rs: Vector2 = Vector2(current_scene.get("room_size"))
		p.global_position = rs / 2.0
		cam.position = Vector2.ZERO
		cam.reset_smoothing()
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("int_%s.png" % name))
	quit()
