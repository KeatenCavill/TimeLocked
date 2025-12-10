extends Area2D

	


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Character"):
		var main = get_tree().root.get_node("Main")
		if main and main.has_method("fade_to_black"):
			main.fade_to_black()
			
