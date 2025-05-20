extends Control

#BISECTION METHOD GD
#iInputs
@onready var a_var_input: LineEdit = $Safe_container/Container_Box/Derivative_Container/A_var_input
@onready var b_var_input: LineEdit = $Safe_container/Container_Box/Derivative_Container/B_var_input
@onready var function_input: LineEdit = $Safe_container/Container_Box/Function_contaier/function_input

#grid
@onready var grid_container: GridContainer = $Safe_container/Container_Box/ScrollContainer/GridContainer


#sound effect files:
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


const DONE = preload("res://Assets/sfx/done.ogg")
const FAILED = preload("res://Assets/sfx/failed.ogg")

# Settings
const MAX_ITERATIONS: int = 100
const TOLERANCE: float = 0.0001
var iterations: Array = []  # To store iteration history

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_cal_pressed() -> void:
	# Validate inputs
	if not _validate_inputs():
		audio_stream_player.stream = FAILED
		audio_stream_player.play()
		return
	$Safe_container/Container_Box/Cal_button_container/cal.modulate = Color.GREEN
	await get_tree().create_timer(0.3).timeout
	$Safe_container/Container_Box/Cal_button_container/cal.modulate = Color.WHITE
	# Get input values
	var a: float = float(a_var_input.text)
	var b: float = float(b_var_input.text)
	var function: String = function_input.text.strip_edges()
	
	# Clear previous results
	iterations.clear()
	_clear_grid_container()
	
	# Run bisection method
	var root = bisection_method(function, a, b)
	
	# Display results
	update_table()
	
	if is_nan(root):
		print("Bisection method failed to converge")
		audio_stream_player.stream = FAILED
		audio_stream_player.play()
	else:
		audio_stream_player.stream = DONE
		audio_stream_player.play()
		print("Found root at: ", root)
		

func _validate_inputs() -> bool:
	# Check if all required fields are filled
	if a_var_input.text.is_empty() or b_var_input.text.is_empty() or function_input.text.is_empty():
		push_error("Please fill all fields")
		return false
	
	# Check if a and b are valid numbers
	if not a_var_input.text.is_valid_float() or not b_var_input.text.is_valid_float():
		push_error("a and b must be numbers")
		return false
	
	# Check if a < b
	var a = float(a_var_input.text)
	var b = float(b_var_input.text)
	if a >= b:
		push_error("a must be less than b")
		return false
	
	return true

func bisection_method(function: String, a: float, b: float) -> float:
	var fa = evaluate_function(function, a)
	var fb = evaluate_function(function, b)
	
	# Check if the interval contains a root
	if fa * fb >= 0:
		push_error("Function must have opposite signs at a and b")
		return NAN
	
	# Store initial values
	iterations.append({
		"iteration": 0,
		"a": a,
		"b": b,
		"c": (a + b) / 2.0,
		"f(a)": fa,
		"f(b)": fb,
		"f(c)": evaluate_function(function, (a + b) / 2.0),
		"error": b - a
	})
	
	for i in range(1, MAX_ITERATIONS + 1):
		var c = (a + b) / 2.0
		var fc = evaluate_function(function, c)
		var error = b - a
		
		# Store iteration data
		iterations.append({
			"iteration": i,
			"a": a,
			"b": b,
			"c": c,
			"f(a)": fa,
			"f(b)": fb,
			"f(c)": fc,
			"f(a)*f(c)": fa * fc,
			"f(b)*f(c)": fb * fc,
			"error": error
		})
		
		# Check for convergence
		if abs(fc) < TOLERANCE or error/2.0 < TOLERANCE:
			return c
		
		# Determine which subinterval to use
		if fc * fa < 0:
			b = c
			fb = fc
		else:
			a = c
			fa = fc
	
	# If we reach here, we didn't converge
	push_warning("Bisection method did not converge within maximum iterations")
	return (a + b) / 2.0

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
		push_error("Parse error: ", expression.get_error_text())
		return NAN
	
	var result = expression.execute([], null, false)
	if expression.has_execute_failed():
		push_error("Execution failed!")
		return NAN
	
	return result

func update_table():
	# Add headers
	add_row(["Iteration", "a", "f(a)", "b", "f(b)", "c", "f(c)", "f(a)*f(c)", "f(b)*f(c)", "Error (b - a)"])
	
	# Add data rows
	for iter_data in iterations:
		add_row([
			str(iter_data.iteration),
			"%.4f" % iter_data.a,
			"%.4f" % iter_data["f(a)"],
			"%.4f" % iter_data.b,
			"%.4f" % iter_data["f(b)"],
			"%.4f" % iter_data.c,
			"%.4f" % iter_data["f(c)"],
			"%.4f" % iter_data.get("f(a)*f(c)", 0),
			"%.4f" % iter_data.get("f(b)*f(c)", 0),
			"%.4f" % iter_data.error
		])

func add_row(values: Array):
	for value in values:
		var label = Label.new()
		label.text = str(value)
		label.custom_minimum_size = Vector2(80, 40)  # Adjusted for more columns
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid_container.add_child(label)

func _clear_grid_container():
	for child in grid_container.get_children():
		child.queue_free()
