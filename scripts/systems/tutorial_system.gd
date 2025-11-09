# res://scripts/systems/tutorial_system.gd
extends Node

# === TUTORIAL STEP ===
class TutorialStep:
	var step_number: int = 0
	var text: String = ""
	var wait_for_input: bool = false
	var required_action: String = ""  # e.g., "shadow_slide", "shadow_slide_blocked"
	var mastery_count: int = 0  # How many times to perform action
	var mastery_progress: int = 0  # Current count

	func _to_string() -> String:
		return "Step %d: %s" % [step_number, text]

# === STATE ===
var tutorial_active: bool = false
var current_step: int = 0
var total_steps: int = 0
var tutorial_steps: Array[TutorialStep] = []
var is_step_completed: bool = false

# === REFERENCES ===
var player: Node2D = null
var ui_container: CanvasLayer = null

# === SIGNALS ===
signal tutorial_started()
signal step_shown(step: TutorialStep)
signal step_completed(step: TutorialStep)
signal tutorial_completed()
signal action_progress(action: String, current: int, required: int)

func _ready() -> void:
	"""Initialize Tutorial System."""
	add_to_group("tutorial_system")
	print("TutorialSystem initialized")

# === TUTORIAL INITIALIZATION ===
func start_tutorial(steps_data: Array[Dictionary]) -> void:
	"""Start tutorial with given steps.

	Args:
		steps_data: Array of step dictionaries from level data
	"""
	if tutorial_active:
		push_warning("Tutorial already active")
		return

	print("Tutorial starting with %d steps" % steps_data.size())

	# Parse step data
	tutorial_steps.clear()
	for step_data in steps_data:
		var step = TutorialStep.new()
		step.step_number = step_data.get("step", 0)
		step.text = step_data.get("text", "")
		step.wait_for_input = step_data.get("wait_for_input", false)
		step.required_action = step_data.get("required_action", "")
		step.mastery_count = step_data.get("mastery_count", 0)
		tutorial_steps.append(step)

	total_steps = tutorial_steps.size()
	tutorial_active = true
	current_step = 0

	# Get player reference
	player = get_tree().get_first_child_in_group("player")

	# Create UI container
	_setup_ui()

	tutorial_started.emit()

	# Show first step
	await show_current_step()

# === STEP DISPLAY ===
func show_current_step() -> void:
	"""Show the current tutorial step."""
	if current_step >= tutorial_steps.size():
		_complete_tutorial()
		return

	var step = tutorial_steps[current_step]
	print("Tutorial Step %d: %s" % [step.step_number, step.text])

	is_step_completed = false
	step.mastery_progress = 0

	_display_step_message(step)
	step_shown.emit(step)

	# Wait for completion
	await _wait_for_step_completion(step)

	step_completed.emit(step)
	current_step += 1

	# Show next step with delay
	await get_tree().create_timer(0.5).timeout
	await show_current_step()

func _wait_for_step_completion(step: TutorialStep) -> void:
	"""Wait for player to complete step requirements.

	Args:
		step: TutorialStep to wait for
	"""
	if step.wait_for_input:
		# Wait for any input
		await _wait_for_input()
		return

	if step.required_action == "":
		# No specific action required, just show message
		return

	# Wait for action to be performed required number of times
	while step.mastery_progress < step.mastery_count:
		await get_tree().process_frame

func _wait_for_input() -> void:
	"""Wait for player input (any key/click)."""
	var input_received = false

	while not input_received:
		if Input.is_action_just_pressed("ui_accept"):
			input_received = true
		await get_tree().process_frame

# === UI DISPLAY ===
func _setup_ui() -> void:
	"""Setup tutorial UI."""
	if ui_container:
		ui_container.queue_free()

	ui_container = CanvasLayer.new()
	ui_container.name = "TutorialUI"
	ui_container.layer = 100
	add_child(ui_container)

func _display_step_message(step: TutorialStep) -> void:
	"""Display tutorial step message.

	Args:
		step: Step to display
	"""
	if not ui_container:
		return

	# Clear previous message
	for child in ui_container.get_children():
		child.queue_free()

	# Create message panel
	var panel = PanelContainer.new()
	panel.name = "TutorialPanel"

	# Create theme with dark background
	var theme = Theme.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color.BLACK
	style.set_border_enabled_all(true)
	style.set_border_color_all(Color.WHITE)
	theme.set_stylebox("panel", "PanelContainer", style)

	panel.theme = theme
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_top = -150
	panel.offset_bottom = -50
	panel.offset_left = 50
	panel.offset_right = -50

	# Create label for message
	var label = Label.new()
	label.text = step.text
	label.custom_minimum_size = Vector2(500, 100)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)

	panel.add_child(label)
	ui_container.add_child(panel)

	# Add action progress if needed
	if step.required_action != "" and step.mastery_count > 0:
		var progress_label = Label.new()
		progress_label.text = "Progress: 0/%d" % step.mastery_count
		progress_label.add_theme_font_size_override("font_size", 12)
		progress_label.add_theme_color_override("font_color", Color.YELLOW)
		progress_label.anchor_left = 0.5
		progress_label.anchor_top = 1.0
		progress_label.anchor_right = 0.5
		progress_label.anchor_bottom = 1.0
		progress_label.offset_top = -40
		progress_label.name = "ProgressLabel"

		ui_container.add_child(progress_label)

	# Add input prompt
	if step.wait_for_input:
		var prompt = Label.new()
		prompt.text = "[Press any key to continue]"
		prompt.add_theme_font_size_override("font_size", 12)
		prompt.add_theme_color_override("font_color", Color.GRAY)
		prompt.anchor_left = 1.0
		prompt.anchor_top = 1.0
		prompt.anchor_right = 1.0
		prompt.anchor_bottom = 1.0
		prompt.offset_top = -30
		prompt.offset_right = -20

		ui_container.add_child(prompt)

func update_action_progress(action: String, current: int, required: int) -> void:
	"""Update tutorial action progress display.

	Args:
		action: Action type being performed
		current: Current progress count
		required: Required count for completion
	"""
	if not tutorial_active or current_step >= tutorial_steps.size():
		return

	var step = tutorial_steps[current_step]
	if step.required_action == action:
		step.mastery_progress = current
		action_progress.emit(action, current, required)

		# Update UI
		var progress_label = ui_container.get_node_or_null("ProgressLabel")
		if progress_label:
			progress_label.text = "Progress: %d/%d" % [current, required]

# === TRACKING ===
func report_action(action_type: String) -> void:
	"""Report that player performed an action.

	Args:
		action_type: Type of action performed
	"""
	if not tutorial_active or current_step >= tutorial_steps.size():
		return

	var step = tutorial_steps[current_step]
	if step.required_action == action_type:
		step.mastery_progress += 1
		print("Tutorial action: %s (%d/%d)" % [action_type, step.mastery_progress, step.mastery_count])

		# Update UI
		update_action_progress(action_type, step.mastery_progress, step.mastery_count)

func report_blocked_action(action_type: String) -> void:
	"""Report that player attempted blocked action (e.g., Shadow Slide blocked by barrier).

	Args:
		action_type: Type of action blocked
	"""
	if not tutorial_active or current_step >= tutorial_steps.size():
		return

	var step = tutorial_steps[current_step]
	if step.required_action == action_type + "_blocked":
		step.mastery_progress += 1
		print("Tutorial blocked action: %s (%d/%d)" % [action_type, step.mastery_progress, step.mastery_count])
		update_action_progress(step.required_action, step.mastery_progress, step.mastery_count)

# === COMPLETION ===
func _complete_tutorial() -> void:
	"""Complete tutorial sequence."""
	print("Tutorial completed!")
	tutorial_active = false

	# Clear UI
	if ui_container:
		ui_container.queue_free()

	tutorial_completed.emit()

func skip_tutorial() -> void:
	"""Skip remaining tutorial steps."""
	print("Tutorial skipped")
	tutorial_active = false

	if ui_container:
		ui_container.queue_free()

	tutorial_completed.emit()

# === UTILITY ===
func is_tutorial_active() -> bool:
	"""Check if tutorial is currently active.

	Returns:
		true if active
	"""
	return tutorial_active

func get_current_step_number() -> int:
	"""Get current step number.

	Returns:
		Current step number
	"""
	return current_step + 1

func get_total_steps() -> int:
	"""Get total number of steps.

	Returns:
		Total steps
	"""
	return total_steps

func get_step_progress() -> String:
	"""Get human-readable progress.

	Returns:
		Progress string (e.g., "2/5")
	"""
	return "%d/%d" % [current_step + 1, total_steps]

func highlight_area(position: Vector2, radius: float, duration: float = 2.0) -> void:
	"""Highlight an area on screen.

	Args:
		position: World position to highlight
		radius: Highlight radius
		duration: How long to show highlight
	"""
	if not ui_container:
		return

	# Create highlight using a Control node with a drawn circle
	var highlight = Control.new()
	highlight.custom_minimum_size = Vector2(radius * 2, radius * 2)
	highlight.position = position - Vector2(radius, radius)

	# Use a simple colored panel as highlight
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 0.0, 0.3)  # Semi-transparent yellow
	style.set_border_enabled_all(true)
	style.set_border_color_all(Color.YELLOW)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2

	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(radius * 2, radius * 2)

	highlight.add_child(panel)
	ui_container.add_child(highlight)

	await get_tree().create_timer(duration).timeout
	highlight.queue_free()

# === CLEANUP ===
func clear_tutorial() -> void:
	"""Clear all tutorial data."""
	tutorial_active = false
	tutorial_steps.clear()
	current_step = 0
	total_steps = 0

	if ui_container:
		ui_container.queue_free()

	print("Tutorial cleared")
