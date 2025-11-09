# res://scripts/autoload/level_manager.gd
extends Node

# === LEVEL DATA ===
var current_level: int = 1
var level_data: Dictionary = {
	1: {
		"name": "Shadow Slide Trial",
		"type": "training",
		"xp_reward": 100,
		"scene_path": "res://scenes/levels/training/level_01.tscn"
	},
	2: {
		"name": "Mirrorwalk Trial",
		"type": "training",
		"xp_reward": 100,
		"scene_path": "res://scenes/levels/training/level_02.tscn"
	},
	3: {
		"name": "Pivot & Shadow Pivot Trial",
		"type": "training",
		"xp_reward": 100,
		"scene_path": "res://scenes/levels/training/level_03.tscn"
	},
	4: {
		"name": "Shadowshift Trial",
		"type": "training",
		"xp_reward": 100,
		"scene_path": "res://scenes/levels/training/level_04.tscn"
	},
	# Levels 5-10 placeholder (Tactical and Boss phases)
}

# === SIGNALS ===
signal level_loaded(level_number: int)
signal level_transition_started()
signal level_transition_complete()

# === LEVEL LOADING ===
func load_level(level_number: int) -> void:
	"""
	Load a level by number.

	Args:
		level_number: The level to load (1-10)
	"""
	if not level_data.has(level_number):
		push_error("LevelManager: Level %d not found in level_data" % level_number)
		return

	current_level = level_number
	var data: Dictionary = level_data[level_number]
	var scene_path: String = data.get("scene_path", "")

	if scene_path.is_empty():
		push_error("LevelManager: Level %d has no scene_path" % level_number)
		return

	_load_scene(scene_path)

func _load_scene(scene_path: String) -> void:
	"""
	Load a scene by path.

	Args:
		scene_path: Path to the scene to load
	"""
	if not ResourceLoader.exists(scene_path):
		push_error("LevelManager: Scene not found at %s" % scene_path)
		return

	level_transition_started.emit()

	# Load the scene
	var scene = load(scene_path)
	if scene == null:
		push_error("LevelManager: Failed to load scene %s" % scene_path)
		return

	# Get the current scene and free it
	var current_scene = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
	if current_scene:
		current_scene.queue_free()

	# Instantiate and add the new scene
	var instance = scene.instantiate()
	get_tree().root.add_child(instance)

	level_loaded.emit(current_level)
	level_transition_complete.emit()

func transition_to_level(level_number: int) -> void:
	"""
	Transition to a new level with fade effect.

	Args:
		level_number: The level to transition to
	"""
	if is_level_unlocked(level_number):
		load_level(level_number)
	else:
		push_error("LevelManager: Level %d is not unlocked" % level_number)

# === LEVEL DATA RETRIEVAL ===
func get_level_data(level_number: int) -> Dictionary:
	"""
	Get data for a specific level.

	Args:
		level_number: The level number

	Returns:
		Dictionary with level data, or empty dict if not found
	"""
	if level_data.has(level_number):
		return level_data[level_number].duplicate()
	else:
		return {}

func get_current_level() -> int:
	"""
	Get the current level number.

	Returns:
		Current level number
	"""
	return current_level

# === LEVEL UNLOCK LOGIC ===
func is_level_unlocked(level_number: int) -> bool:
	"""
	Check if a level is unlocked based on completed levels.

	Args:
		level_number: The level to check

	Returns:
		true if level is unlocked, false otherwise
	"""
	# Level 1 is always unlocked
	if level_number == 1:
		return true

	# Level is unlocked if previous level is complete
	if (level_number - 1) in GameManager.levels_complete:
		return true

	return false

func get_unlocked_levels() -> Array[int]:
	"""
	Get an array of all unlocked levels.

	Returns:
		Array of unlocked level numbers
	"""
	var unlocked: Array[int] = []
	for level_num in level_data.keys():
		if is_level_unlocked(level_num):
			unlocked.append(level_num)
	return unlocked

# === LEVEL COMPLETION ===
func mark_level_complete(level_number: int, xp_reward: int = 0) -> void:
	"""
	Mark a level as complete and award XP.

	Args:
		level_number: The completed level
		xp_reward: XP to award (uses level data if not specified)
	"""
	if xp_reward == 0:
		var data: Dictionary = get_level_data(level_number)
		xp_reward = data.get("xp_reward", 100)

	GameManager.complete_level(level_number, xp_reward)

# === UTILITY ===
func get_level_name(level_number: int) -> String:
	"""
	Get the name of a level.

	Args:
		level_number: The level number

	Returns:
		Level name string
	"""
	var data: Dictionary = get_level_data(level_number)
	return data.get("name", "Unknown Level")

func get_level_type(level_number: int) -> String:
	"""
	Get the type of a level (training, tactical, boss).

	Args:
		level_number: The level number

	Returns:
		Level type string
	"""
	var data: Dictionary = get_level_data(level_number)
	return data.get("type", "unknown")
