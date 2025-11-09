# res://scripts/systems/level_data_loader.gd
extends Node
class_name LevelDataLoaderModule

# === VALIDATION RESULT ===
class ValidationResult:
	var valid: bool = true
	var reason: String = ""
	var warnings: Array[String] = []

	func _to_string() -> String:
		if valid:
			return "✓ Valid"
		return "✗ Invalid: %s" % reason

# === LEVEL DATA STRUCTURE ===
class LevelData:
	var level_number: int = 0
	var name: String = ""
	var type: String = "training"  # training, story, challenge
	var difficulty_stars: int = 1
	var arena_width: int = 40
	var arena_height: int = 30
	var player_start: Dictionary = {}  # {position: [x, y], direction: [x, y]}
	var objectives: Dictionary = {}  # {primary: "", secondary: [...]}
	var enemies: Array[Dictionary] = []
	var hazards: Array[Dictionary] = []
	var barriers: Array[Dictionary] = []
	var exit: Dictionary = {}  # {position: [x, y]}
	var tutorial_sequence: Array[Dictionary] = []
	var xp_reward: int = 0
	var unlocks_level: int = 0

	func _to_string() -> String:
		return "Level %d: %s" % [level_number, name]

# === STATE ===
var loaded_levels: Dictionary = {}  # {level_number: LevelData}
var current_level: LevelData = null

func _ready() -> void:
	"""Initialize Level Data Loader."""
	add_to_group("level_data_loader")
	print("LevelDataLoader initialized")

# === MAIN LOADING ===
func load_level(level_number: int) -> ValidationResult:
	"""Load level data from JSON file.

	Args:
		level_number: Level number to load

	Returns:
		ValidationResult with success status
	"""
	var file_path = "res://data/levels/level_%02d.json" % level_number
	var result = ValidationResult.new()

	# Check if already loaded
	if level_number in loaded_levels:
		current_level = loaded_levels[level_number]
		result.valid = true
		result.reason = "Loaded from cache"
		print("Level %d loaded from cache" % level_number)
		return result

	# Load JSON file
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		result.valid = false
		result.reason = "File not found: %s" % file_path
		push_error(result.reason)
		return result

	var json_string = file.get_as_text()
	var json = JSON.new()
	var parse_error = json.parse(json_string)

	if parse_error != OK:
		result.valid = false
		result.reason = "JSON parse error: %s" % json.get_error_message()
		push_error(result.reason)
		return result

	var data_dict = json.data
	if not data_dict:
		result.valid = false
		result.reason = "No data in JSON file"
		push_error(result.reason)
		return result

	# Parse level data
	var level_data = LevelData.new()
	_parse_level_data(level_data, data_dict)

	# Validate data
	result = _validate_level_data(level_data)
	if not result.valid:
		push_error("Level validation failed: %s" % result.reason)
		return result

	# Cache and set current
	loaded_levels[level_number] = level_data
	current_level = level_data

	print("Level %d loaded successfully: %s" % [level_number, level_data.name])
	if result.warnings.size() > 0:
		for warning in result.warnings:
			print("  Warning: %s" % warning)

	return result

func _parse_level_data(level_data: LevelData, data_dict: Dictionary) -> void:
	"""Parse JSON data into LevelData structure.

	Args:
		level_data: LevelData object to populate
		data_dict: Parsed JSON dictionary
	"""
	# Basic properties
	level_data.level_number = data_dict.get("level_number", 0)
	level_data.name = data_dict.get("name", "Unnamed Level")
	level_data.type = data_dict.get("type", "training")
	level_data.difficulty_stars = data_dict.get("difficulty_stars", 1)
	level_data.xp_reward = data_dict.get("xp_reward", 0)
	level_data.unlocks_level = data_dict.get("unlocks_level", 0)

	# Arena
	var arena = data_dict.get("arena", {})
	level_data.arena_width = arena.get("width_tiles", 40)
	level_data.arena_height = arena.get("height_tiles", 30)

	# Player start
	level_data.player_start = data_dict.get("player_start", {
		"position": [5, 15],
		"direction": [1, 0]
	})

	# Objectives
	level_data.objectives = data_dict.get("objectives", {
		"primary": "",
		"secondary": []
	})

	# Enemies
	var enemies = data_dict.get("enemies", [])
	for enemy_data in enemies:
		level_data.enemies.append(enemy_data as Dictionary)

	# Hazards
	var hazards = data_dict.get("hazards", [])
	for hazard_data in hazards:
		level_data.hazards.append(hazard_data as Dictionary)

	# Barriers
	var barriers = data_dict.get("barriers", [])
	for barrier_data in barriers:
		level_data.barriers.append(barrier_data as Dictionary)

	# Exit
	level_data.exit = data_dict.get("exit", {
		"position": [35, 15]
	})

	# Tutorial sequence
	var tutorial = data_dict.get("tutorial_sequence", [])
	for step in tutorial:
		level_data.tutorial_sequence.append(step as Dictionary)

# === VALIDATION ===
func _validate_level_data(level_data: LevelData) -> ValidationResult:
	"""Validate level data against schema.

	Args:
		level_data: LevelData to validate

	Returns:
		ValidationResult with any errors/warnings
	"""
	var result = ValidationResult.new()

	# Required fields
	if level_data.level_number <= 0:
		result.valid = false
		result.reason = "Invalid level_number: %d" % level_data.level_number
		return result

	if level_data.name == "":
		result.valid = false
		result.reason = "Level name is empty"
		return result

	# Arena validation
	if level_data.arena_width <= 0 or level_data.arena_height <= 0:
		result.valid = false
		result.reason = "Invalid arena dimensions: %dx%d" % [level_data.arena_width, level_data.arena_height]
		return result

	# Player start validation
	if not _validate_position(level_data.player_start.get("position", [])):
		result.valid = false
		result.reason = "Invalid player start position"
		return result

	# Exit validation
	if not _validate_position(level_data.exit.get("position", [])):
		result.valid = false
		result.reason = "Invalid exit position"
		return result

	# Enemies validation
	for enemy in level_data.enemies:
		if not _validate_position(enemy.get("position", [])):
			result.warnings.append("Invalid enemy position: %s" % str(enemy.get("position")))
		if enemy.get("type", "") == "":
			result.warnings.append("Enemy missing type field")

	# Hazards validation
	for hazard in level_data.hazards:
		if not _validate_position(hazard.get("position", [])):
			result.warnings.append("Invalid hazard position")

	# Barriers validation
	for barrier in level_data.barriers:
		if not _validate_position(barrier.get("start", [])) or not _validate_position(barrier.get("end", [])):
			result.warnings.append("Invalid barrier positions")

	result.valid = true
	return result

func _validate_position(position: Array) -> bool:
	"""Validate that position is [x, y] array.

	Args:
		position: Position array to validate

	Returns:
		true if valid
	"""
	if position.size() != 2:
		return false
	if not (position[0] is int or position[0] is float) or not (position[1] is int or position[1] is float):
		return false
	return true

# === DATA ACCESS ===
func get_current_level() -> LevelData:
	"""Get currently loaded level data.

	Returns:
		Current LevelData or null
	"""
	return current_level

func get_player_start_position() -> Vector2i:
	"""Get player starting position as tile coordinates.

	Returns:
		Player start position
	"""
	if not current_level:
		return Vector2i.ZERO
	var pos = current_level.player_start.get("position", [0, 0])
	return Vector2i(int(pos[0]), int(pos[1]))

func get_player_start_direction() -> Vector2:
	"""Get player starting direction.

	Returns:
		Player start direction (normalized)
	"""
	if not current_level:
		return Vector2.RIGHT
	var dir = current_level.player_start.get("direction", [1, 0])
	return Vector2(float(dir[0]), float(dir[1])).normalized()

func get_enemies() -> Array[Dictionary]:
	"""Get all enemy spawn data.

	Returns:
		Array of enemy dictionaries
	"""
	if not current_level:
		return []
	return current_level.enemies

func get_hazards() -> Array[Dictionary]:
	"""Get all hazard data.

	Returns:
		Array of hazard dictionaries
	"""
	if not current_level:
		return []
	return current_level.hazards

func get_barriers() -> Array[Dictionary]:
	"""Get all barrier data.

	Returns:
		Array of barrier dictionaries
	"""
	if not current_level:
		return []
	return current_level.barriers

func get_exit_position() -> Vector2i:
	"""Get exit position as tile coordinates.

	Returns:
		Exit position
	"""
	if not current_level:
		return Vector2i.ZERO
	var pos = current_level.exit.get("position", [35, 15])
	return Vector2i(int(pos[0]), int(pos[1]))

func get_tutorial_sequence() -> Array[Dictionary]:
	"""Get tutorial steps.

	Returns:
		Array of tutorial step dictionaries
	"""
	if not current_level:
		return []
	return current_level.tutorial_sequence

func get_xp_reward() -> int:
	"""Get XP reward for completing level.

	Returns:
		XP amount
	"""
	if not current_level:
		return 0
	return current_level.xp_reward

func get_unlocks_level() -> int:
	"""Get next level unlocked by completing this one.

	Returns:
		Next level number
	"""
	if not current_level:
		return 0
	return current_level.unlocks_level

# === UTILITY ===
func get_level_info() -> String:
	"""Get human-readable level information.

	Returns:
		Formatted level info string
	"""
	if not current_level:
		return "No level loaded"

	var info = "Level %d: %s\n" % [current_level.level_number, current_level.name]
	info += "  Type: %s\n" % current_level.type
	info += "  Difficulty: %s/5 stars\n" % str(current_level.difficulty_stars)
	info += "  Arena: %dx%d tiles\n" % [current_level.arena_width, current_level.arena_height]
	info += "  Enemies: %d\n" % current_level.enemies.size()
	info += "  Hazards: %d\n" % current_level.hazards.size()
	info += "  Barriers: %d\n" % current_level.barriers.size()
	info += "  XP Reward: %d\n" % current_level.xp_reward
	info += "  Unlocks: Level %d" % current_level.unlocks_level

	return info

func clear_cache() -> void:
	"""Clear all cached level data."""
	loaded_levels.clear()
	current_level = null
	print("Level data cache cleared")
