# res://scripts/ui/main_menu.gd
extends CanvasLayer
class_name MainMenu

# === LEVEL DATA ===
var levels = [
	{"number": 1, "name": "Shadow Slide Trial", "description": "Learn translation: moving without rotation."},
	{"number": 2, "name": "Mirrorwalk Trial", "description": "Learn reflection: pass through barriers."},
	{"number": 3, "name": "Pivot & Shadow Pivot Trial", "description": "Learn rotation: self and external pivots."},
	{"number": 4, "name": "Shadowshift Trial", "description": "Learn dilation: scale yourself up or down."},
]

var difficulties = ["Easy", "Normal", "Hard"]

# === STATE ===
var selected_level: int = 1
var selected_difficulty: int = 1  # 0=Easy, 1=Normal, 2=Hard

# === REFERENCES ===
var title_label: Label
var level_buttons: Array[Button] = []
var difficulty_buttons: Array[Button] = []
var description_label: Label
var start_button: Button

func _ready() -> void:
	"""Initialize main menu."""
	print("Main Menu loaded")
	print("Setting up UI...")
	_setup_ui()
	print("UI setup complete, updating selection...")
	_update_selection()
	print("Main Menu ready!")

# === UI SETUP ===
func _setup_ui() -> void:
	"""Create menu UI."""
	# Root panel
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Background color
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.1, 0.1, 0.15)
	root.add_child(bg)

	# Title
	title_label = Label.new()
	title_label.text = "SHADOW WARLOCK TRAINING"
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(0.5, 0.2, 0.8))
	title_label.anchor_left = 0.5
	title_label.anchor_top = 0.0
	title_label.anchor_right = 0.5
	title_label.anchor_bottom = 0.0
	title_label.offset_left = -300
	title_label.offset_top = 30
	title_label.offset_right = 300
	title_label.offset_bottom = 130
	root.add_child(title_label)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Select a training level and difficulty to begin"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color.GRAY)
	subtitle.anchor_left = 0.5
	subtitle.anchor_top = 0.0
	subtitle.anchor_right = 0.5
	subtitle.anchor_bottom = 0.0
	subtitle.offset_left = -250
	subtitle.offset_top = 120
	subtitle.offset_right = 250
	subtitle.offset_bottom = 145
	root.add_child(subtitle)

	# === LEVEL SELECTION ===
	var level_title = Label.new()
	level_title.text = "SELECT LEVEL"
	level_title.add_theme_font_size_override("font_size", 20)
	level_title.add_theme_color_override("font_color", Color.WHITE)
	level_title.anchor_left = 0.0
	level_title.anchor_top = 0.0
	level_title.offset_left = 50
	level_title.offset_top = 170
	root.add_child(level_title)

	# Level buttons container
	var level_container = VBoxContainer.new()
	level_container.anchor_left = 0.0
	level_container.anchor_top = 0.0
	level_container.offset_left = 50
	level_container.offset_top = 210
	level_container.custom_minimum_size = Vector2(250, 200)
	root.add_child(level_container)

	for level in levels:
		var button = Button.new()
		button.text = "Level %d: %s" % [level.number, level.name]
		button.custom_minimum_size = Vector2(250, 40)
		button.pressed.connect(_on_level_selected.bindv([level.number]))
		level_container.add_child(button)
		level_buttons.append(button)

	# === DIFFICULTY SELECTION ===
	var difficulty_title = Label.new()
	difficulty_title.text = "SELECT DIFFICULTY"
	difficulty_title.add_theme_font_size_override("font_size", 20)
	difficulty_title.add_theme_color_override("font_color", Color.WHITE)
	difficulty_title.anchor_left = 0.0
	difficulty_title.anchor_top = 0.0
	difficulty_title.offset_left = 350
	difficulty_title.offset_top = 170
	root.add_child(difficulty_title)

	# Difficulty buttons container
	var difficulty_container = HBoxContainer.new()
	difficulty_container.anchor_left = 0.0
	difficulty_container.anchor_top = 0.0
	difficulty_container.offset_left = 350
	difficulty_container.offset_top = 210
	root.add_child(difficulty_container)

	for i in range(difficulties.size()):
		var button = Button.new()
		button.text = difficulties[i]
		button.custom_minimum_size = Vector2(120, 40)
		button.pressed.connect(_on_difficulty_selected.bindv([i]))
		difficulty_container.add_child(button)
		difficulty_buttons.append(button)

	# === DESCRIPTION ===
	var desc_title = Label.new()
	desc_title.text = "LEVEL DESCRIPTION"
	desc_title.add_theme_font_size_override("font_size", 20)
	desc_title.add_theme_color_override("font_color", Color.WHITE)
	desc_title.anchor_left = 0.0
	desc_title.anchor_top = 0.0
	desc_title.offset_left = 50
	desc_title.offset_top = 440
	root.add_child(desc_title)

	description_label = Label.new()
	description_label.text = ""
	description_label.add_theme_font_size_override("font_size", 16)
	description_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	description_label.anchor_left = 0.0
	description_label.anchor_top = 0.0
	description_label.offset_left = 50
	description_label.offset_top = 480
	description_label.custom_minimum_size = Vector2(500, 100)
	root.add_child(description_label)

	# === START BUTTON ===
	start_button = Button.new()
	start_button.text = "START LEVEL"
	start_button.add_theme_font_size_override("font_size", 24)
	start_button.custom_minimum_size = Vector2(200, 60)
	start_button.anchor_left = 0.5
	start_button.anchor_top = 1.0
	start_button.anchor_right = 0.5
	start_button.anchor_bottom = 1.0
	start_button.offset_left = -100
	start_button.offset_top = -90
	start_button.offset_right = 100
	start_button.offset_bottom = -30
	start_button.pressed.connect(_on_start_pressed)
	root.add_child(start_button)

	# === INFO ===
	var info = Label.new()
	info.text = "MVP: 4 Training Levels | All Shadow Arts | Turn-Based Combat"
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color.DARK_GRAY)
	info.anchor_left = 0.0
	info.anchor_top = 1.0
	info.anchor_right = 0.0
	info.anchor_bottom = 1.0
	info.offset_left = 10
	info.offset_top = -25
	info.offset_right = 300
	info.offset_bottom = -10
	root.add_child(info)

# === EVENT HANDLERS ===
func _on_level_selected(level_number: int) -> void:
	"""Handle level selection."""
	selected_level = level_number
	_update_selection()

func _on_difficulty_selected(difficulty_index: int) -> void:
	"""Handle difficulty selection."""
	selected_difficulty = difficulty_index
	_update_selection()

func _on_start_pressed() -> void:
	"""Start the selected level."""
	print("Starting Level %d on %s difficulty" % [selected_level, difficulties[selected_difficulty]])

	# Set difficulty
	if DifficultySystem:
		DifficultySystem.set_difficulty_by_name(difficulties[selected_difficulty].to_lower())

	# Load the level scene
	var level_scene_path = "res://scenes/levels/level_%02d.tscn" % selected_level
	get_tree().change_scene_to_file(level_scene_path)

# === UI UPDATE ===
func _update_selection() -> void:
	"""Update button styles based on selection."""
	# Update level buttons
	for i in range(level_buttons.size()):
		var button = level_buttons[i]
		if levels[i].number == selected_level:
			button.add_theme_color_override("font_color", Color.YELLOW)
			button.add_theme_color_override("font_hover_color", Color.WHITE)
		else:
			button.add_theme_color_override("font_color", Color.WHITE)
			button.add_theme_color_override("font_hover_color", Color.LIGHT_GRAY)

	# Update difficulty buttons
	for i in range(difficulty_buttons.size()):
		var button = difficulty_buttons[i]
		if i == selected_difficulty:
			button.add_theme_color_override("font_color", Color.YELLOW)
			button.add_theme_color_override("font_hover_color", Color.WHITE)
		else:
			button.add_theme_color_override("font_color", Color.WHITE)
			button.add_theme_color_override("font_hover_color", Color.LIGHT_GRAY)

	# Update description
	for level in levels:
		if level.number == selected_level:
			description_label.text = level.description
			break
