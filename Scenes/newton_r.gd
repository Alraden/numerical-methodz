class_name NewtonRaphsonCalculator extends Control
#NEWTON GD
@onready var grid_container: GridContainer = $Safe_container/Container_Box/ScrollContainer/GridContainer
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


const DONE = preload("res://Assets/sfx/done.ogg")
const FAILED = preload("res://Assets/sfx/failed.ogg")

# Output variables
var f_OFX_Value: float
var der_F_OFX_Value: float
var NewX: float
var iterations: Array = []

# Input variables
var initial_g: float
var f_OFX: String
var der_F_OFX: String

const MAX_ITERATIONS: int = 100
const TOLERANCE: float = 0.0001

func _on_cal_pressed() -> void:
	# Validate input
	if not _validate_input():
		return
	
	initial_g = float($Safe_container/Container_Box/Initial_guess_Cotainer/Ini_g_input.text)
	f_OFX = $Safe_container/Container_Box/Function_contaier/function_input.text.strip_edges()
	der_F_OFX = $Safe_container/Container_Box/Derivative_Container/Der_Input.text.strip_edges()
	
	# Run Newton-Raphson
	var result = newton_raphson(initial_g)
	update_table()

func _validate_input() -> bool:
	if not grid_container:
		audio_stream_player.stream = FAILED
		audio_stream_player.play()
		push_error("GridContainer not found!")
		return false
	
	# Check if function expressions contain only valid characters
	var valid_chars = "0123456789x+-*^/(). "
	var function_text = $Safe_container/Container_Box/Function_contaier/function_input.text.strip_edges()
	var derivative_text = $Safe_container/Container_Box/Derivative_Container/Der_Input.text.strip_edges()
	
	for c in function_text:
		if not valid_chars.contains(c):
			audio_stream_player.stream = FAILED
			audio_stream_player.play()
			push_error("Function contains invalid character: " + c)
			return false
			
	for c in derivative_text:
		if not valid_chars.contains(c):
			audio_stream_player.stream = FAILED
			audio_stream_player.play()
			push_error("Derivative contains invalid character: " + c)
			return false
			
	return true

func newton_raphson(initial_guess: float) -> float:
	var x: float = initial_guess
	iterations.clear()
	
	for i in range(MAX_ITERATIONS):
		var fx = evaluate_expression(f_OFX, x)
		var dfx = evaluate_expression(der_F_OFX, x)
		
		# Check for NaN or infinity
		if is_nan(fx) or is_inf(fx) or is_nan(dfx) or is_inf(dfx):
			push_error("Function evaluation resulted in invalid number")
			iterations.append({"x": x, "f(x)": fx, "f'(x)": dfx, "new_x": x})
			return NAN
			
		if abs(dfx) < TOLERANCE:
			print("Derivative too small - possible divergence")
			iterations.append({"x": x, "f(x)": fx, "f'(x)": dfx, "new_x": x})
			return x
			
		var new_x = x - (fx / dfx)
		iterations.append({"x": x, "f(x)": fx, "f'(x)": dfx, "new_x": new_x})
		
		if abs(new_x - x) < TOLERANCE:
			return new_x
			
		x = new_x
	
	push_warning("Maximum iterations reached without convergence")
	return x

func evaluate_expression(expr: String, x_value: float) -> float:
	
	var modified_expr = expr.replace("^", "**")
	print(modified_expr)
	
	# Handle negative x values by adding parentheses
	var x_str = str(x_value)
	if x_value < 0:
		x_str = "(%s)" % x_str
	
	# Replace "x" with the value
	modified_expr = modified_expr.replace("x", x_str)
	
	print("Evaluating: ", modified_expr)  # Debug
	
	var expression = Expression.new()
	var error = expression.parse(modified_expr, [])
	if error != OK:
		audio_stream_player.stream = FAILED
		audio_stream_player.play()
		push_error("Parse error: ", expression.get_error_text())
		return 0.0
	
	var result = expression.execute([], null, false)
	if expression.has_execute_failed():
		audio_stream_player.stream = FAILED
		audio_stream_player.play()
		push_error("Execution failed!")
		return 0.0
	
	return result
	
func update_table():
	# Clear previous results
	for child in grid_container.get_children():
		child.queue_free()
	
	# Add headers
	add_row(["Iteration", "x", "f(x)", "f'(x)", "New x"])
	
	# Add data rows
	for i in range(iterations.size()):
		var iter_data = iterations[i]
		add_row([
			str(i + 1),  # Integer (no formatting needed)
			"%.4f" % iter_data.x,  # x (float)
			"%.4f" % iter_data["f(x)"],  # f(x) (float)
			"%.4f" % iter_data["f'(x)"],  # f'(x) (float)
			"%.4f" % iter_data.new_x  # New x (float)
		])
	audio_stream_player.stream = DONE
	audio_stream_player.play()

func add_row(values: Array):
	for value in values:
		var label = Label.new()
		label.text = str(value)
		
		# Set minimum size constraints
		label.custom_minimum_size = Vector2(125, 50)  # Min width=125, Min height=50
		
		# Optional: Improve text alignment and appearance
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		grid_container.add_child(label)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
