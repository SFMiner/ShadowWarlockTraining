# res://scripts/systems/turn_manager.gd
extends Node

# === PHASE ENUM ===
enum Phase {
	IDLE,               # Initial state
	ENEMY_TELEGRAPH,    # Enemies show their moves
	PLAYER_ACTION,      # Player performs transformation
	ENEMY_RESOLUTION,   # Enemies execute moves
	LEVEL_COMPLETE,     # Player won
	LEVEL_FAILED        # Player hit (one-shot)
}

# === TURN STATE ===
var current_phase: Phase = Phase.IDLE
var turn_number: int = 0
var phase_time: float = 0.0

# === TIMING ===
var telegraph_duration: float = 2.0  # Time to show enemy moves
var action_time_limit: float = 30.0  # Hard mode only
var resolution_duration: float = 1.0  # Time for enemy execution

# === DIFFICULTY SETTINGS ===
var current_difficulty: String = "normal"  # easy, normal, hard
var telegraph_enabled: bool = true
var timer_enabled: bool = false
var ghost_preview_enabled: bool = true

# === REFERENCES ===
var player: Node2D = null
var level_manager: Node = null
var active_enemies: Array[Node] = []

# === ACTION QUEUE ===
var player_action: Node = null  # Player's submitted transformation (TransformationBase)
var enemy_actions: Array[Dictionary] = []  # Stores telegraphed actions: [{enemy, action_type, target_pos}, ...]
var player_action_submitted: Signal = Signal()  # Emitted when player submits action

# === SIGNALS ===
signal phase_changed(new_phase: Phase, phase_name: String)
signal turn_started(turn_number: int)
signal turn_completed(turn_number: int)
signal player_acted()
signal level_won()
signal level_lost()
signal timer_updated(remaining_time: float)
signal timer_warning(seconds_remaining: float)  # Emitted at 5 seconds
signal timer_expired()

func _ready() -> void:
	"""Initialize TurnManager."""
	add_to_group("turn_manager")
	print("TurnManager initialized")

	# Apply difficulty settings from GameManager
	_apply_difficulty_settings()

func _process(delta: float) -> void:
	"""Update turn phase timing."""
	if current_phase == Phase.PLAYER_ACTION and timer_enabled:
		phase_time -= delta
		timer_updated.emit(max(0.0, phase_time))

		# Warn at 5 seconds remaining
		if phase_time <= 5.0 and phase_time > 4.99:
			timer_warning.emit(phase_time)
			print("WARNING: Time limit in 5 seconds!")

		if phase_time <= 0.0:
			print("Time limit exceeded! Ending turn.")
			timer_expired.emit()
			end_player_action()

# === PHASE MANAGEMENT ===
func get_current_phase() -> Phase:
	"""
	Get the current turn phase.

	Returns:
		Current Phase enum value
	"""
	return current_phase

func get_phase_name(phase: Phase = current_phase) -> String:
	"""
	Get string name of a phase.

	Args:
		phase: Phase to get name for

	Returns:
		String name of phase
	"""
	match phase:
		Phase.IDLE:
			return "IDLE"
		Phase.ENEMY_TELEGRAPH:
			return "ENEMY_TELEGRAPH"
		Phase.PLAYER_ACTION:
			return "PLAYER_ACTION"
		Phase.ENEMY_RESOLUTION:
			return "ENEMY_RESOLUTION"
		Phase.LEVEL_COMPLETE:
			return "LEVEL_COMPLETE"
		Phase.LEVEL_FAILED:
			return "LEVEL_FAILED"
		_:
			return "UNKNOWN"

func _transition_to_phase(new_phase: Phase) -> void:
	"""
	Transition to a new phase.

	Args:
		new_phase: Target phase
	"""
	if current_phase == new_phase:
		return

	var old_phase = current_phase
	current_phase = new_phase
	phase_time = 0.0

	print("Phase transition: %s -> %s" % [get_phase_name(old_phase), get_phase_name(new_phase)])
	phase_changed.emit(new_phase, get_phase_name(new_phase))

# === TURN CYCLE ===
func start_turn() -> void:
	"""
	Start a new turn.

	Turn sequence:
	1. Increment turn counter
	2. Enter ENEMY_TELEGRAPH phase
	3. Show enemy moves
	"""
	if current_phase != Phase.IDLE and current_phase != Phase.ENEMY_RESOLUTION:
		push_warning("Cannot start turn - not in idle state (current: %s)" % get_phase_name())
		return

	turn_number += 1
	print("\n========================================")
	print("TURN %d STARTED" % turn_number)
	print("========================================")
	turn_started.emit(turn_number)

	_transition_to_phase(Phase.ENEMY_TELEGRAPH)
	await _telegraph_phase()

func _telegraph_phase() -> void:
	"""
	Execute the enemy telegraph phase.

	Enemies show their moves for telegraph_duration.
	"""
	print("Telegraph phase: Enemies show moves")
	phase_time = telegraph_duration

	# Get current alive enemies
	active_enemies = get_tree().get_nodes_in_group("enemies")

	# Have each enemy calculate their next action
	enemy_actions.clear()
	for enemy in active_enemies:
		if enemy is Enemy and is_instance_valid(enemy):
			var action = enemy.calculate_next_action()
			enemy_actions.append({
				"enemy": enemy,
				"action_type": action.get("action_type", "idle"),
				"target_pos": action.get("target_pos", enemy.global_position),
				"params": action.get("extra_data", {})
			})
			print("  %s planned: %s" % [enemy.name, action.get("action_type", "idle")])

	# Show telegraph indicators if enabled
	if telegraph_enabled and TelegraphSystem:
		await TelegraphSystem.show_sequential_telegraphs(active_enemies)
	else:
		await get_tree().create_timer(telegraph_duration).timeout

	end_telegraph_phase()

func end_telegraph_phase() -> void:
	"""
	End telegraph phase and transition to player action.

	Sets up timer for action phase if difficulty is hard.
	"""
	print("Telegraph phase complete")
	_transition_to_phase(Phase.PLAYER_ACTION)

	# Start timer for hard mode
	if timer_enabled:
		phase_time = action_time_limit
		print("Action phase started. Time limit: %.1f seconds" % action_time_limit)
	else:
		print("Action phase started. No time limit")

	# TODO: Show action UI for player

func end_player_action() -> void:
	"""
	End player action phase and transition to enemy resolution.

	Called when player performs transformation or time limit expires.
	"""
	print("Player action phase complete")
	if player and player.has_signal("transformation_complete"):
		# Player has performed a transformation
		print("Player transformation detected")
	else:
		print("No player transformation performed")

	_transition_to_phase(Phase.ENEMY_RESOLUTION)
	await _resolution_phase()

func _resolution_phase() -> void:
	"""
	Execute the enemy resolution phase.

	Enemies execute their moves.
	"""
	print("Resolution phase: Enemies execute moves")
	phase_time = resolution_duration

	# Execute each enemy's action sequentially
	for action_data in enemy_actions:
		var enemy = action_data.get("enemy")
		if enemy and is_instance_valid(enemy) and enemy is Enemy:
			await enemy.execute_action(action_data)

	# Check collision and outcomes via CombatResolver
	if CombatResolver:
		# CombatResolver will handle collision detection and level win/lose conditions
		CombatResolver.check_victory_conditions()

	await get_tree().create_timer(0.5).timeout

	end_resolution_phase()

func end_resolution_phase() -> void:
	"""
	End resolution phase and check win/lose conditions.

	Transitions to next turn, level complete, or level failed.
	"""
	print("Resolution phase complete")

	# Check win/lose conditions
	var win_condition = _check_win_condition()
	var lose_condition = _check_lose_condition()

	if win_condition:
		print("LEVEL WON!")
		_transition_to_phase(Phase.LEVEL_COMPLETE)
		level_won.emit()
		return

	if lose_condition:
		print("LEVEL LOST!")
		_transition_to_phase(Phase.LEVEL_FAILED)
		level_lost.emit()
		return

	# Continue to next turn
	_transition_to_phase(Phase.IDLE)
	turn_completed.emit(turn_number)
	await get_tree().create_timer(0.5).timeout
	start_turn()

# === WIN/LOSE CONDITIONS ===
func _check_win_condition() -> bool:
	"""
	Check if player has won.

	Returns:
		true if win condition met, false otherwise
	"""
	# TODO: Implement level-specific win conditions
	# Generally: All objectives complete or all enemies defeated

	# Check if all enemies defeated
	if active_enemies.size() == 0:
		return true

	# Check level-specific objectives
	if level_manager:
		# TODO: Check level objectives
		pass

	return false

func _check_lose_condition() -> bool:
	"""
	Check if player has lost.

	Returns:
		true if lose condition met, false otherwise
	"""
	# Player dies on one hit
	if player and player.has_meta("health"):
		if player.health <= 0:
			return true

	# TODO: Implement other lose conditions (time limit, objectives, etc.)

	return false

# === DIFFICULTY SETTINGS ===
func _apply_difficulty_settings() -> void:
	"""Apply difficulty settings from GameManager."""
	current_difficulty = GameManager.get_meta("difficulty", "normal") if GameManager.has_meta("difficulty") else "normal"

	match current_difficulty:
		"easy":
			telegraph_enabled = true
			timer_enabled = false
			ghost_preview_enabled = true
			telegraph_duration = 3.0

		"normal":
			telegraph_enabled = true
			timer_enabled = false
			ghost_preview_enabled = true
			telegraph_duration = 2.0

		"hard":
			telegraph_enabled = true
			timer_enabled = true
			ghost_preview_enabled = false
			telegraph_duration = 1.5
			action_time_limit = 30.0

	print("Difficulty: %s" % current_difficulty)
	print("Telegraph: %s, Timer: %s, Preview: %s" % [telegraph_enabled, timer_enabled, ghost_preview_enabled])

func set_difficulty(difficulty: String) -> void:
	"""
	Set game difficulty.

	Args:
		difficulty: "easy", "normal", or "hard"
	"""
	current_difficulty = difficulty
	_apply_difficulty_settings()

# === ENEMY MANAGEMENT ===
func register_enemy(enemy: Node2D) -> void:
	"""
	Register an enemy with turn manager.

	Args:
		enemy: Enemy node to register
	"""
	if enemy not in active_enemies:
		active_enemies.append(enemy)
		print("Enemy registered: %s" % enemy.name)

func unregister_enemy(enemy: Node2D) -> void:
	"""
	Unregister an enemy (defeat).

	Args:
		enemy: Enemy node to unregister
	"""
	if enemy in active_enemies:
		active_enemies.erase(enemy)
		print("Enemy defeated: %s" % enemy.name)

		# Check if level is won
		if _check_win_condition():
			print("All enemies defeated!")
			end_resolution_phase()

# === PLAYER REFERENCE ===
func set_player(p_player: Node2D) -> void:
	"""
	Set the player reference.

	Args:
		p_player: Player node
	"""
	player = p_player
	if player:
		print("Player registered: %s" % player.name)

# === ACTION QUEUE MANAGEMENT ===
func submit_player_action(action: Node) -> void:
	"""
	Submit the player's transformation action.

	Args:
		action: TransformationBase node containing the transformation
	"""
	if current_phase != Phase.PLAYER_ACTION:
		push_warning("Player action submitted outside PLAYER_ACTION phase")
		return

	player_action = action
	print("Player action submitted: %s" % (action.transformation_type if action.has_meta("transformation_type") else "unknown"))
	player_acted.emit()
	player_action_submitted.emit()

func queue_enemy_action(enemy: Node2D, action_type: String, params: Dictionary) -> void:
	"""
	Queue an enemy's telegraphed action.

	Args:
		enemy: Enemy node
		action_type: Type of action (move, attack, etc.)
		params: Action parameters
	"""
	var action_data = {
		"enemy": enemy,
		"action_type": action_type,
		"params": params
	}
	enemy_actions.append(action_data)
	print("Enemy action queued: %s (%s)" % [enemy.name, action_type])

func clear_action_queue() -> void:
	"""Clear all queued actions."""
	player_action = null
	enemy_actions.clear()
	print("Action queue cleared")

func get_enemy_actions() -> Array[Dictionary]:
	"""
	Get all queued enemy actions.

	Returns:
		Array of enemy action dictionaries
	"""
	return enemy_actions

func get_player_action() -> Node:
	"""
	Get the submitted player action.

	Returns:
		TransformationBase node or null
	"""
	return player_action

# === UTILITY ===
func get_turn_info() -> Dictionary:
	"""
	Get current turn information.

	Returns:
		Dictionary with turn details
	"""
	return {
		"turn_number": turn_number,
		"phase": get_phase_name(),
		"enemies_remaining": active_enemies.size(),
		"time_limit_enabled": timer_enabled,
		"time_remaining": max(0.0, phase_time) if current_phase == Phase.PLAYER_ACTION else 0.0
	}
