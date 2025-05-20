extends Control
#SECANT METHOF
@onready var function_input: LineEdit = $Safe_container/Container_Box/Function_contaier/function_input
@onready var xk_input: LineEdit = $Safe_container/Container_Box/Derivative_Container/Xk_input
@onready var xk_m_one_var_input: LineEdit = $Safe_container/Container_Box/Derivative_Container/xk_MOne_var_input
@onready var grid_container: GridContainer = $Safe_container/Container_Box/ScrollContainer/GridContainer

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
const DONE = preload("res://Assets/sfx/done.ogg")
const FAILED = preload("res://Assets/sfx/failed.ogg")

# Settings
const MAX_ITERATIONS: int = 100
const TOLERANCE: float = 0.0001
var iterations: Array = []  # To store iteration history

func _on_cal_pressed() -> void:
	# Validate inputs
	if not _validate_inputs():
		audio_stream_player.stream = FAILED
		audio_stream_player.play()
		return
	
	# Get input values
	var x_k_minus_1: float = float(xk_m_one_var_input.text)
	var x_k: float = float(xk_input.text)
	var function: String = function_input.text.strip_edges()
	
	# Clear previous results
	iterations.clear()
	_clear_grid_container()
	
	# Run Secant method
	var root = secant_method(function, x_k_minus_1, x_k)
	
	# Display results
	update_table()
	
	if is_nan(root):
		audio_stream_player.stream = FAILED
		audio_stream_player.play()
		print("Secant method failed to converge")
	else:
		print("Found root at: ", root)

func _validate_inputs() -> bool:
	# Check if all required fields are filled
	if xk_m_one_var_input.text.is_empty() or xk_input.text.is_empty() or function_input.text.is_empty():
		audio_stream_player.stream = FAILED
		audio_stream_player.play()
		push_error("Please fill all fields")
		return false
	
	# Check if inputs are valid numbers
	if not xk_m_one_var_input.text.is_valid_float() or not xk_input.text.is_valid_float():
		audio_stream_player.stream = FAILED
		audio_stream_player.play()
		push_error("Xk-1 and Xk must be numbers")
		return false
	
	# Check if initial points are different
	if float(xk_m_one_var_input.text) == float(xk_input.text):
		push_error("Initial points must be different")
		return false
	
	return true

func secant_method(function: String, x_k_minus_1: float, x_k: float) -> float:
	var f_k_minus_1 = evaluate_function(function, x_k_minus_1)
	var f_k = evaluate_function(function, x_k)
	
	# Store initial values
	iterations.append({
		"iteration": 0,
		"x_k_minus_1": x_k_minus_1,
		"f_k_minus_1": f_k_minus_1,
		"x_k": x_k,
		"f_k": f_k,
		"x_k_plus_1": NAN,
		"f_k_plus_1": NAN,
		"error": abs(x_k - x_k_minus_1)
	})
	
	for i in range(1, MAX_ITERATIONS + 1):
		# Secant formula
		var denominator = f_k - f_k_minus_1
		if abs(denominator) < TOLERANCE:
			push_error("Denominator too small - possible divergence")
			return NAN
			
		var x_k_plus_1 = x_k - (f_k * (x_k - x_k_minus_1)) / denominator
		var f_k_plus_1 = evaluate_function(function, x_k_plus_1)
		var error = abs(x_k_plus_1 - x_k)
		
		# Store iteration data
		iterations.append({
			"iteration": i,
			"x_k_minus_1": x_k_minus_1,
			"f_k_minus_1": f_k_minus_1,
			"x_k": x_k,
			"f_k": f_k,
			"x_k_plus_1": x_k_plus_1,
			"f_k_plus_1": f_k_plus_1,
			"error": error
		})
		
		# Check for convergence
		if abs(f_k_plus_1) < TOLERANCE or error < TOLERANCE:
			return x_k_plus_1
			
		# Update for next iteration
		x_k_minus_1 = x_k
		f_k_minus_1 = f_k
		x_k = x_k_plus_1
		f_k = f_k_plus_1
	
	push_warning("Secant method did not converge within maximum iterations")
	return iterations[-1]["x_k_plus_1"]  # Return last estimate

func evaluate_function(expr: String, x_value: float) -> float:
	# Replace "^" with "**" for exponentiation
	var modified_expr = expr.replace("^", "**")
	
	# Handle negative x values by adding parentheses
	var x_str = str(x_value)
	if x_value < 0:
		x_str = "(%s)" % x_str
	
	# Replace x with its value
	modified_expr = modified_expr.replace("x", x_str)
	
	# Evaluate using Godot's Expression class
	var expression = Expression.new()
	var error = expression.parse(modified_expr, [])
	if error != OK:
		audio_stream_player.stream = FAILED
		audio_stream_player.play()
		push_error("Parse error: ", expression.get_error_text())
		return NAN
	
	var result = expression.execute([], null, false)
	if expression.has_execute_failed():
		audio_stream_player.stream = FAILED
		audio_stream_player.play()
		push_error("Execution failed!")
		return NAN
	
	return result

func update_table():
	# Add headers
	add_row(["Iteration", "Xk-1", "f(Xk-1)", "Xk", "f(Xk)", "Xk+1", "f(Xk+1)", "Error"])
	
	# Add data rows
	for iter_data in iterations:
		add_row([
			str(iter_data.iteration),
			"%.4f" % iter_data.x_k_minus_1,
			"%.4f" % iter_data.f_k_minus_1,
			"%.4f" % iter_data.x_k,
			"%.4f" % iter_data.f_k,
			"%.4f" % iter_data.get("x_k_plus_1", NAN),
			"%.4f" % iter_data.get("f_k_plus_1", NAN),
			"%.4f" % iter_data.error
		])
	audio_stream_player.stream = DONE
	audio_stream_player.play()

func add_row(values: Array):
	for value in values:
		var label = Label.new()
		label.text = str(value)
		label.custom_minimum_size = Vector2(100, 40)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid_container.add_child(label)

func _clear_grid_container():
	for child in grid_container.get_children():
		child.queue_free()


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
