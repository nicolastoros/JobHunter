extends Area2D
## Forwards sword hits to the owning monster.


func take_hit(amount: int, source: Node2D, crit := false) -> void:
	get_parent().take_hit(amount, source, crit)
