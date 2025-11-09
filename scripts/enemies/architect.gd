# res://scripts/enemies/architect.gd
extends Enemy
class_name Architect

# === ARCHITECT BOSS PARAMETERS ===
@export var phase_2_threshold: int = 4  # Health at which to enter phase 2
@export var phase_3_threshold: int = 2  # Health at which to enter phase 3
@export var summon_cooldown: int = 3    # Turns before next summon
@export var multi_target_range: float = 150.0
@export var pattern_attack_damage: int = 2

var is_phase_2: bool = false
var is_phase_3: bool = false
var turns_since_summon: int = 0
var current_pattern: String = "basic"

func _ready() -> void:
	enemy_type = "architect"
	health = 6
	max_health = 6
	patrol_speed = 0.0  # Boss is stationary
	super._ready()

# === PHASE TRANSITIONS ===
func check_phase_transition() -> void:
	"""Check if boss should transition to next phase."""
	if not is_phase_3 and health <= phase_3_threshold:
		enter_phase_3()
	elif not is_phase_2 and health <= phase_2_threshold:
		enter_phase_2()

func enter_phase_2() -> void:
	"""Transition to phase 2: More aggressive attacks."""
	is_phase_2 = true
	print("%s enters Phase 2! Attacks intensify!" % name)
	modulate = Color(1.0, 0.8, 0.8)  # Slight red tint
	change_state(State.TELEGRAPHING)

func enter_phase_3() -> void:
	"""Transition to phase 3: Desperate final phase."""
	is_phase_3 = true
	print("%s enters Phase 3! CRITICAL STATE!" % name)
	modulate = Color(1.0, 0.5, 0.5)  # Strong red tint
	change_state(State.TELEGRAPHING)

# === AI LOGIC ===
func calculate_next_action() -> Dictionary:
	"""Architect AI: Complex attack pattern selection based on phase.

	Returns:
		Dictionary with action_type, target_pos, and extra_data
	"""
	change_state(State.TELEGRAPHING)
	check_phase_transition()

	var player = get_tree().get_first_child_in_group("player")
	if not player:
		return idle_action()

	# Select action based on phase and cooldowns
	if turns_since_summon >= summon_cooldown:
		return summon_minions_action()

	if is_phase_3:
		return select_phase_3_action(player)
	elif is_phase_2:
		return select_phase_2_action(player)
	else:
		return select_phase_1_action(player)

func select_phase_1_action(player: Node2D) -> Dictionary:
	"""Phase 1: Basic attacks."""
	var rand = randf()
	if rand < 0.6:
		return basic_strike_action(player.global_position)
	else:
		return area_attack_action(player.global_position)

func select_phase_2_action(player: Node2D) -> Dictionary:
	"""Phase 2: More aggressive multi-hit patterns."""
	var rand = randf()
	if rand < 0.4:
		return multi_strike_action(player.global_position)
	elif rand < 0.7:
		return area_attack_action(player.global_position)
	else:
		return summon_minions_action()

func select_phase_3_action(player: Node2D) -> Dictionary:
	"""Phase 3: Desperate final attacks."""
	var rand = randf()
	if rand < 0.5:
		return multi_strike_action(player.global_position)
	else:
		return ultimate_attack_action(player.global_position)

# === ACTION DEFINITIONS ===
func idle_action() -> Dictionary:
	"""Return an idle action."""
	var action = {
		"action_type": "idle",
		"target_pos": global_position,
		"extra_data": {}
	}
	action_planned.emit(action)
	telegraph_data = action
	return action

func basic_strike_action(target_pos: Vector2) -> Dictionary:
	"""Single target strike."""
	current_pattern = "basic"
	var action = {
		"action_type": "attack",
		"target_pos": target_pos,
		"extra_data": {
			"damage": 1,
			"pattern": "basic"
		}
	}
	action_planned.emit(action)
	telegraph_data = action
	return action

func multi_strike_action(target_pos: Vector2) -> Dictionary:
	"""Multiple strikes in sequence."""
	current_pattern = "multi"
	var action = {
		"action_type": "multi_attack",
		"target_pos": target_pos,
		"extra_data": {
			"damage": 1,
			"strike_count": 3 if is_phase_3 else 2,
			"pattern": "multi"
		}
	}
	action_planned.emit(action)
	telegraph_data = action
	return action

func area_attack_action(target_pos: Vector2) -> Dictionary:
	"""Area-of-effect attack."""
	current_pattern = "area"
	var action = {
		"action_type": "area_attack",
		"target_pos": target_pos,
		"extra_data": {
			"damage": 1,
			"radius": multi_target_range,
			"pattern": "area"
		}
	}
	action_planned.emit(action)
	telegraph_data = action
	return action

func ultimate_attack_action(target_pos: Vector2) -> Dictionary:
	"""Ultimate attack (phase 3 only)."""
	current_pattern = "ultimate"
	var action = {
		"action_type": "ultimate",
		"target_pos": target_pos,
		"extra_data": {
			"damage": pattern_attack_damage,
			"radius": multi_target_range * 1.5,
			"pattern": "ultimate"
		}
	}
	action_planned.emit(action)
	telegraph_data = action
	return action

func summon_minions_action() -> Dictionary:
	"""Summon minions to assist."""
	var action = {
		"action_type": "summon",
		"target_pos": global_position,
		"extra_data": {
			"minion_count": 2 if not is_phase_2 else 3,
			"minion_type": "summon"
		}
	}
	action_planned.emit(action)
	telegraph_data = action
	turns_since_summon = 0
	return action

# === EXECUTION ===
func execute_action(action: Dictionary) -> void:
	"""Execute the Architect's action.

	Args:
		action: Dictionary with action_type and parameters
	"""
	change_state(State.EXECUTING)

	var action_type = action.get("action_type", "idle")

	match action_type:
		"attack":
			await _execute_basic_strike(action)
		"multi_attack":
			await _execute_multi_strike(action)
		"area_attack":
			await _execute_area_attack(action)
		"ultimate":
			await _execute_ultimate(action)
		"summon":
			await _execute_summon(action)
		"idle":
			await get_tree().create_timer(0.3).timeout

	turns_since_summon += 1
	change_state(State.WAITING)

func _execute_basic_strike(action: Dictionary) -> void:
	"""Execute a basic strike."""
	var target_pos = action.get("target_pos", global_position)
	print("%s strikes toward target!" % name)

	var tween = create_tween()
	var original_pos = global_position
	var direction = (target_pos - global_position).normalized()

	tween.tween_property(self, "global_position", original_pos + direction * 15.0, 0.2)
	tween.tween_property(self, "global_position", original_pos, 0.2)
	await tween.finished

func _execute_multi_strike(action: Dictionary) -> void:
	"""Execute multiple strikes."""
	var target_pos = action.get("target_pos", global_position)
	var strike_count = action.get("strike_count", 2)
	print("%s performs multi-strike! (%d strikes)" % [name, strike_count])

	var original_pos = global_position
	var direction = (target_pos - global_position).normalized()

	for i in range(strike_count):
		var tween = create_tween()
		tween.tween_property(self, "global_position", original_pos + direction * 15.0, 0.1)
		tween.tween_property(self, "global_position", original_pos, 0.1)
		await tween.finished
		await get_tree().create_timer(0.1).timeout

func _execute_area_attack(action: Dictionary) -> void:
	"""Execute area-of-effect attack."""
	print("%s unleashes area attack!" % name)

	# Expanding shockwave animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE * 1.3, 0.3)
	modulate = Color.YELLOW
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	await tween.finished

func _execute_ultimate(action: Dictionary) -> void:
	"""Execute ultimate attack."""
	print("%s unleashes ULTIMATE ATTACK!" % name)

	# Dramatic effect
	var tween = create_tween()
	tween.set_parallel(true)
	modulate = Color.RED
	tween.tween_property(self, "modulate", Color.WHITE, 0.5)
	tween.tween_property(self, "scale", Vector2.ONE * 1.5, 0.3)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	await tween.finished

func _execute_summon(action: Dictionary) -> void:
	"""Execute summoning of minions."""
	var minion_count = action.get("minion_count", 2)
	print("%s summons %d minions!" % [name, minion_count])

	# Visual summon effect
	var tween = create_tween()
	modulate = Color.MAGENTA
	tween.tween_property(self, "modulate", Color.WHITE, 0.4)
	await tween.finished

# === HEALTH MANAGEMENT ===
func take_damage(amount: int) -> void:
	"""Take damage with phase transition check.

	Args:
		amount: Amount of damage to take
	"""
	super.take_damage(amount)
	check_phase_transition()

func die() -> void:
	"""Boss defeat sequence."""
	print("%s has been defeated!" % name)
	modulate = Color(0.5, 0.5, 0.5)
	change_state(State.DEAD)

	# Boss defeat animation
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 1.0)
	tween.tween_property(self, "scale", Vector2.ZERO, 1.0)

	enemy_defeated.emit(self)
	await tween.finished
	queue_free()
