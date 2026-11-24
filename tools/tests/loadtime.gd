extends SceneTree
func _initialize() -> void:
	for p in ["res://scenes/world/world.tscn", "res://scenes/world/field.tscn", "res://scenes/world/forest.tscn", "res://scenes/world/desert.tscn", "res://scenes/world/aurelia.tscn"]:
		var t := Time.get_ticks_msec()
		var r = load(p)
		var t2 := Time.get_ticks_msec()
		var inst = r.instantiate()
		print(p.get_file(), " load ", t2 - t, " ms, instantiate ", Time.get_ticks_msec() - t2, " ms")
		inst.free()
	quit()
