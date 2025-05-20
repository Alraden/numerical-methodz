extends Control
#MAIN_MENU GD

func _on_newton_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/newton_r.tscn")


func _on_bisect_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Bisectiontscn.tscn")


func _on_secant_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/secant_method.tscn")


func _on_false_pressed() -> void:
	pass # Replace with function body.


func _on_fixed_pressed() -> void:
	pass # Replace with function body.


func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/option.tscn")
