# res://scripts/systems/difficulty_system.gd
extends Node

# === DIFFICULTY ENUM ===
enum Difficulty {
	EASY,
	NORMAL,
	HARD
}

# === DIFFICULTY SETTINGS ===
var current_difficulty: Difficulty = Difficulty.NORMAL
var difficulty_name: String = "normal"

# === EASY MODE ===
var easy_settings: Dictionary = {
	"telegraph_enabled": true,
	"telegraph_duration": 3.0,
	"timer_enabled": false,
	"action_time_limit": 60.0,
	"ghost_preview_enabled": true,
	"enemy_accuracy": 0.5,  # 50% chance to hit
	"player_damage_multiplier": 1.5,  # Player does 150% damage
	"enemy_damage_multiplier": 0.5,  # Enemies do 50% damage
}

# === NORMAL MODE ===
var normal_settings: Dictionary = {
	"telegraph_enabled": true,
	"telegraph_duration": 2.0,
	"timer_enabled": false,
	"action_time_limit": 60.0,
	"ghost_preview_enabled": true,
	"enemy_accuracy": 0.75,  # 75% chance to hit
	"player_damage_multiplier": 1.0,
	"enemy_damage_multiplier": 1.0,
}

# === HARD MODE ===
var hard_settings: Dictionary = {
	"telegraph_enabled": true,
	"telegraph_duration": 1.5,
	"timer_enabled": true,
	"action_time_limit": 30.0,
	"ghost_preview_enabled": false,
	"enemy_accuracy": 0.95,  # 95% chance to hit
	"player_damage_multiplier": 0.75,  # Player does 75% damage
	"enemy_damage_multiplier": 1.5,  # Enemies do 150% damage
}

# === SIGNALS ===
signal difficulty_changed(difficulty: String, settings: Dictionary)

func _ready() -> void:
	"""Initialize difficulty system."""
	add_to_group("difficulty_system")
	print("Difficulty System initialized")

# === DIFFICULTY MANAGEMENT ===
func set_difficulty(difficulty: Difficulty) -> void:
	"""
	Set game difficulty.

	Args:
		difficulty: Difficulty enum value
	"""
	current_difficulty = difficulty

	match difficulty:
		Difficulty.EASY:
			difficulty_name = "easy"
			_apply_settings(easy_settings)
		Difficulty.NORMAL:
			difficulty_name = "normal"
			_apply_settings(normal_settings)
		Difficulty.HARD:
			difficulty_name = "hard"
			_apply_settings(hard_settings)

	print("Difficulty set to: %s" % difficulty_name.to_upper())

func set_difficulty_by_name(difficulty_str: String) -> void:
	"""
	Set difficulty by string name.

	Args:
		difficulty_str: "easy", "normal", or "hard"
	"""
	match difficulty_str.to_lower():
		"easy":
			set_difficulty(Difficulty.EASY)
		"normal":
			set_difficulty(Difficulty.NORMAL)
		"hard":
			set_difficulty(Difficulty.HARD)
		_:
			print("Unknown difficulty: %s. Using normal" % difficulty_str)
			set_difficulty(Difficulty.NORMAL)

func _apply_settings(settings: Dictionary) -> void:
	"""
	Apply difficulty settings to game systems.

	Args:
		settings: Dictionary of difficulty settings
	"""
	# Apply to TurnManager
	if TurnManager:
		TurnManager.telegraph_enabled = settings.get("telegraph_enabled", true)
		TurnManager.telegraph_duration = settings.get("telegraph_duration", 2.0)
		TurnManager.timer_enabled = settings.get("timer_enabled", false)
		TurnManager.action_time_limit = settings.get("action_time_limit", 60.0)
		TurnManager.ghost_preview_enabled = settings.get("ghost_preview_enabled", true)

	# Store other settings for gameplay
	var gameplay_settings = {
		"enemy_accuracy": settings.get("enemy_accuracy", 0.75),
		"player_damage_multiplier": settings.get("player_damage_multiplier", 1.0),
		"enemy_damage_multiplier": settings.get("enemy_damage_multiplier", 1.0)
	}

	# Emit signal
	difficulty_changed.emit(difficulty_name, gameplay_settings)

# === SETTING ACCESSORS ===
func get_telegraph_enabled() -> bool:
	"""Get if telegraph phase is enabled."""
	match current_difficulty:
		Difficulty.EASY:
			return easy_settings["telegraph_enabled"]
		Difficulty.NORMAL:
			return normal_settings["telegraph_enabled"]
		Difficulty.HARD:
			return hard_settings["telegraph_enabled"]
	return true

func get_telegraph_duration() -> float:
	"""Get telegraph phase duration in seconds."""
	match current_difficulty:
		Difficulty.EASY:
			return easy_settings["telegraph_duration"]
		Difficulty.NORMAL:
			return normal_settings["telegraph_duration"]
		Difficulty.HARD:
			return hard_settings["telegraph_duration"]
	return 2.0

func get_timer_enabled() -> bool:
	"""Get if action timer is enabled."""
	match current_difficulty:
		Difficulty.EASY:
			return easy_settings["timer_enabled"]
		Difficulty.NORMAL:
			return normal_settings["timer_enabled"]
		Difficulty.HARD:
			return hard_settings["timer_enabled"]
	return false

func get_action_time_limit() -> float:
	"""Get action phase time limit in seconds."""
	match current_difficulty:
		Difficulty.EASY:
			return easy_settings["action_time_limit"]
		Difficulty.NORMAL:
			return normal_settings["action_time_limit"]
		Difficulty.HARD:
			return hard_settings["action_time_limit"]
	return 60.0

func get_ghost_preview_enabled() -> bool:
	"""Get if ghost previews are enabled."""
	match current_difficulty:
		Difficulty.EASY:
			return easy_settings["ghost_preview_enabled"]
		Difficulty.NORMAL:
			return normal_settings["ghost_preview_enabled"]
		Difficulty.HARD:
			return hard_settings["ghost_preview_enabled"]
	return true

func get_enemy_accuracy() -> float:
	"""Get enemy hit accuracy (0.0-1.0)."""
	match current_difficulty:
		Difficulty.EASY:
			return easy_settings["enemy_accuracy"]
		Difficulty.NORMAL:
			return normal_settings["enemy_accuracy"]
		Difficulty.HARD:
			return hard_settings["enemy_accuracy"]
	return 0.75

func get_player_damage_multiplier() -> float:
	"""Get damage multiplier for player attacks."""
	match current_difficulty:
		Difficulty.EASY:
			return easy_settings["player_damage_multiplier"]
		Difficulty.NORMAL:
			return normal_settings["player_damage_multiplier"]
		Difficulty.HARD:
			return hard_settings["player_damage_multiplier"]
	return 1.0

func get_enemy_damage_multiplier() -> float:
	"""Get damage multiplier for enemy attacks."""
	match current_difficulty:
		Difficulty.EASY:
			return easy_settings["enemy_damage_multiplier"]
		Difficulty.NORMAL:
			return normal_settings["enemy_damage_multiplier"]
		Difficulty.HARD:
			return hard_settings["enemy_damage_multiplier"]
	return 1.0

# === UTILITY ===
func get_difficulty_info() -> Dictionary:
	"""Get information about current difficulty."""
	return {
		"difficulty": difficulty_name,
		"telegraph_enabled": get_telegraph_enabled(),
		"telegraph_duration": get_telegraph_duration(),
		"timer_enabled": get_timer_enabled(),
		"action_time_limit": get_action_time_limit(),
		"ghost_preview_enabled": get_ghost_preview_enabled(),
		"enemy_accuracy": get_enemy_accuracy(),
		"player_damage_multiplier": get_player_damage_multiplier(),
		"enemy_damage_multiplier": get_enemy_damage_multiplier()
	}
