extends Control
#INTRO GD
var last_click_time := 0.0
var double_click := 0.3

func _ready() -> void:
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton):
		
		var current_time := Time.get_ticks_msec() / 1000.0
		if current_time - last_click_time <= double_click:
			_skip_to_menu()
		last_click_time = current_time

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	_skip_to_menu()

func _skip_to_menu() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
