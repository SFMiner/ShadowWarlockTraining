# res://scripts/systems/level_conditions.gd
extends Node

# === WIN CONDITION TYPES ===
enum WinConditionType {
	DEFEAT_ALL_ENEMIES,      # Eliminate all enemies
	REACH_OBJECTIVE,         # Reach a location
	SURVIVE_TURNS,           # Survive N turns
	PROTECT_OBJECTIVE,       # Protect an NPC/object
	COLLECT_ITEMS            # Collect specific items
}

# === LOSE CONDITION TYPES ===
enum LoseConditionType {
	PLAYER_HEALTH_ZERO,      # Player health reaches 0 (default)
	OBJECTIVE_DESTROYED,     # Protected objective destroyed
	TIMEOUT,                 # Time limit exceeded
	PLAYER_TRAPPED,          # Player in inescapable situation
	ENEMIES_REACH_EXIT       # Enemies escape the arena
}

# === WIN CONDITIONS ===
var win_conditions: Array[Dictionary] = []
var completed_objectives: Array[String] = []

# === LOSE CONDITIONS ===
var lose_conditions: Array[Dictionary] = []
var triggered_failures: Array[String] = []

# === STATE ===
var level_won: bool = false
var level_lost: bool = false
var win_reason: String = ""
var lose_reason: String = ""

# === SIGNALS ===
signal objective_completed(objective_name: String)
signal objective_failed(reason: String)
signal level_won_signal(reason: String)
signal level_lost_signal(reason: String)

func _ready() -> void:
	"""Initialize level conditions."""
	add_to_group("level_conditions")
	print("Level Conditions system initialized")

# === WIN CONDITION SETUP ===
func add_win_condition(condition_type: WinConditionType, params: Dictionary) -> void:
	"""
	Add a win condition for the level.

	Args:
		condition_type: Type of win condition
		params: Condition parameters
	"""
	var condition = {
		"type": condition_type,
		"params": params,
		"completed": false
	}
	win_conditions.append(condition)

	match condition_type:
		WinConditionType.DEFEAT_ALL_ENEMIES:
			print("Win condition: Defeat all enemies")
		WinConditionType.REACH_OBJECTIVE:
			print("Win condition: Reach objective at %s" % params.get("target_position", "unknown"))
		WinConditionType.SURVIVE_TURNS:
			print("Win condition: Survive %d turns" % params.get("turns_required", 0))
		WinConditionType.PROTECT_OBJECTIVE:
			print("Win condition: Protect objective: %s" % params.get("objective_name", "unknown"))
		WinConditionType.COLLECT_ITEMS:
			print("Win condition: Collect items: %s" % params.get("items", []))

func add_default_win_condition() -> void:
	"""Add default win condition: defeat all enemies."""
	add_win_condition(WinConditionType.DEFEAT_ALL_ENEMIES, {})

# === LOSE CONDITION SETUP ===
func add_lose_condition(condition_type: LoseConditionType, params: Dictionary) -> void:
	"""
	Add a lose condition for the level.

	Args:
		condition_type: Type of lose condition
		params: Condition parameters
	"""
	var condition = {
		"type": condition_type,
		"params": params,
		"triggered": false
	}
	lose_conditions.append(condition)

	match condition_type:
		LoseConditionType.PLAYER_HEALTH_ZERO:
			print("Lose condition: Player health reaches 0")
		LoseConditionType.OBJECTIVE_DESTROYED:
			print("Lose condition: Protected objective destroyed")
		LoseConditionType.TIMEOUT:
			print("Lose condition: Timeout after %d seconds" % params.get("timeout_seconds", 0))
		LoseConditionType.PLAYER_TRAPPED:
			print("Lose condition: Player trapped")
		LoseConditionType.ENEMIES_REACH_EXIT:
			print("Lose condition: Enemies reach exit")

func add_default_lose_condition() -> void:
	"""Add default lose condition: player health reaches 0."""
	add_lose_condition(LoseConditionType.PLAYER_HEALTH_ZERO, {})

# === CONDITION CHECKING ===
func check_win_conditions(game_state: Dictionary) -> bool:
	"""
	Check if any win condition is met.

	Args:
		game_state: Current game state (enemies, player, objectives, etc.)

	Returns:
		true if any win condition is met
	"""
	for condition in win_conditions:
		if condition["completed"]:
			continue

		var condition_met = false

		match condition["type"]:
			WinConditionType.DEFEAT_ALL_ENEMIES:
				condition_met = game_state.get("active_enemies", []).size() == 0

			WinConditionType.REACH_OBJECTIVE:
				var target_pos = condition["params"].get("target_position", Vector2.ZERO)
				var player = game_state.get("player", null)
				if player:
					condition_met = player.global_position.distance_to(target_pos) < 30.0

			WinConditionType.SURVIVE_TURNS:
				var required_turns = condition["params"].get("turns_required", 0)
				var current_turn = game_state.get("turn_number", 0)
				condition_met = current_turn >= required_turns

			WinConditionType.PROTECT_OBJECTIVE:
				var objective_name = condition["params"].get("objective_name", "")
				var protected_objects = game_state.get("protected_objects", [])
				condition_met = objective_name in protected_objects

			WinConditionType.COLLECT_ITEMS:
				var required_items = condition["params"].get("items", [])
				var collected_items = game_state.get("collected_items", [])
				condition_met = collected_items.size() >= required_items.size()

		if condition_met and not condition["completed"]:
			condition["completed"] = true
			completed_objectives.append(str(condition["type"]))
			_mark_win()
			return true

	return false

func check_lose_conditions(game_state: Dictionary) -> bool:
	"""
	Check if any lose condition is triggered.

	Args:
		game_state: Current game state

	Returns:
		true if any lose condition is triggered
	"""
	for condition in lose_conditions:
		if condition["triggered"]:
			continue

		var condition_triggered = false

		match condition["type"]:
			LoseConditionType.PLAYER_HEALTH_ZERO:
				var player = game_state.get("player", null)
				if player and player.has_meta("health"):
					condition_triggered = player.health <= 0

			LoseConditionType.OBJECTIVE_DESTROYED:
				var objective_name = condition["params"].get("objective_name", "")
				var protected_objects = game_state.get("protected_objects", [])
				condition_triggered = objective_name not in protected_objects

			LoseConditionType.TIMEOUT:
				var timeout = condition["params"].get("timeout_seconds", 0)
				var elapsed = game_state.get("elapsed_time", 0)
				condition_triggered = elapsed > timeout

			LoseConditionType.PLAYER_TRAPPED:
				var player = game_state.get("player", null)
				var valid_moves = game_state.get("player_valid_moves", 0)
				condition_triggered = player and valid_moves == 0

			LoseConditionType.ENEMIES_REACH_EXIT:
				var enemies_at_exit = game_state.get("enemies_at_exit", 0)
				condition_triggered = enemies_at_exit > 0

		if condition_triggered and not condition["triggered"]:
			condition["triggered"] = true
			triggered_failures.append(str(condition["type"]))
			_mark_loss(str(condition["type"]))
			return true

	return false

# === STATUS UPDATES ===
func _mark_win() -> void:
	"""Mark level as won."""
	level_won = true
	win_reason = "Objective completed"
	print("LEVEL WON: %s" % win_reason)
	level_won_signal.emit(win_reason)

func _mark_loss(reason: String) -> void:
	"""Mark level as lost."""
	level_lost = true
	lose_reason = reason
	print("LEVEL LOST: %s" % lose_reason)
	level_lost_signal.emit(lose_reason)

# === OBJECTIVE TRACKING ===
func complete_objective(objective_name: String) -> void:
	"""
	Mark an objective as completed.

	Args:
		objective_name: Name of completed objective
	"""
	if objective_name not in completed_objectives:
		completed_objectives.append(objective_name)
		objective_completed.emit(objective_name)
		print("Objective completed: %s" % objective_name)

func fail_objective(objective_name: String) -> void:
	"""
	Mark an objective as failed.

	Args:
		objective_name: Name of failed objective
	"""
	objective_failed.emit(objective_name)
	print("Objective failed: %s" % objective_name)

# === LEVEL STATE ===
func get_level_status() -> Dictionary:
	"""
	Get overall level status.

	Returns:
		Dictionary with level status info
	"""
	return {
		"won": level_won,
		"lost": level_lost,
		"win_reason": win_reason,
		"lose_reason": lose_reason,
		"completed_objectives": completed_objectives,
		"failed_conditions": triggered_failures,
		"win_conditions_total": win_conditions.size(),
		"win_conditions_met": win_conditions.filter(func(c): return c["completed"]).size(),
		"lose_conditions_active": lose_conditions.filter(func(c): return c["triggered"]).size()
	}

func reset_conditions() -> void:
	"""Reset all conditions for new attempt."""
	level_won = false
	level_lost = false
	win_reason = ""
	lose_reason = ""
	completed_objectives.clear()
	triggered_failures.clear()

	for condition in win_conditions:
		condition["completed"] = false
	for condition in lose_conditions:
		condition["triggered"] = false

	print("Level conditions reset")
