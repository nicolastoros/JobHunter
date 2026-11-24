extends SceneTree
func _initialize() -> void:
	var game = root.get_node("Game")
	var seen := {}
	for m in ["desert.tscn", "forest.tscn", "field.tscn", "world.tscn"]:
		var lv := []
		for h in game.hunters_today(m):
			lv.append(h["level"]); seen[h["name"]] = int(seen.get(h["name"], 0)) + 1
		print(m, " ", lv)
	print("unique ", seen.values().max() == 1)
	quit()
