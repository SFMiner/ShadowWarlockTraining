# res://scripts/enemies/enemy_base.gd
extends CharacterBody2D
class_name Enemy

# === STATE MACHINE ===
enum State {
	IDLE,           # Patrolling/Waiting
	TELEGRAPHING,   # About to act
	WAITING,        # Waiting for resolution phase
	EXECUTING,      # Performing action
	DEAD            # Defeated
}

@export var enemy_type: String = "hound"
@export var patrol_speed: float = 32.0  # pixels per second
@export var patrol_waypoints: Array[Vector2] = []
@export var health: int = 3
@export var max_health: int = 3

var current_waypoint_index: int = 0
var is_active: bool = true
var current_state: State = State.IDLE
var telegraph_data: Dictionary = {}

signal player_contact()
signal state_changed(new_state: State)
signal action_planned(action: Dictionary)
signal health_changed(current: int, maximum: int)
signal enemy_defeated(enemy: Node2D)

func _ready() -> void:
	add_to_group("enemies")
	# Unlock bestiary entry when first encountered
	GameManager.unlock_bestiary_entry(enemy_type)

func _physics_process(delta: float) -> void:
	if not is_active or patrol_waypoints.is_empty():
		return
	
	# Simple waypoint patrol
	var target := patrol_waypoints[current_waypoint_index]
	var direction := global_position.direction_to(target)
	velocity = direction * patrol_speed
	
	move_and_slide()
	
	# Check if reached waypoint
	if global_position.distance_to(target) < 5.0:
		current_waypoint_index = (current_waypoint_index + 1) % patrol_waypoints.size()

func _on_area_2d_body_entered(body: Node2D) -> void:
	"""Detect player contact."""
	if body is PlayerAvatar:
		player_contact.emit()

func pause_patrol() -> void:
	"""Temporarily stop patrol (for being affected by transformations)."""
	is_active = false

func resume_patrol() -> void:
	"""Resume patrol after transformation."""
	is_active = true

# === STATE MANAGEMENT ===
func change_state(new_state: State) -> void:
	"""Change enemy state and emit signal."""
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(new_state)

# === AI DECISION FRAMEWORK ===
func calculate_next_action() -> Dictionary:
	"""Virtual method: Calculate enemy's action for this turn.

	Override in subclasses to implement specific AI logic.

	Returns:
		Dictionary with action_type, target_pos, and extra_data
	"""
	change_state(State.TELEGRAPHING)
	var action = {
		"action_type": "idle",
		"target_pos": global_position,
		"extra_data": {}
	}
	action_planned.emit(action)
	telegraph_data = action
	return action

func execute_action(action: Dictionary) -> void:
	"""Virtual method: Execute the planned action.

	Override in subclasses to implement specific movement/attack logic.

	Args:
		action: Dictionary with action data to execute
	"""
	change_state(State.EXECUTING)
	await get_tree().create_timer(0.3).timeout
	change_state(State.WAITING)

# === VISION/SENSING ===
func get_distance_to_player() -> float:
	"""Get distance to player."""
	var player = get_tree().get_first_child_in_group("player")
	if not player:
		return 999.0
	return global_position.distance_to(player.global_position)

func can_see_player() -> bool:
	"""Check if player is visible (override for line-of-sight)."""
	return get_distance_to_player() < 500.0  # Large default range

func get_tiles_in_vision() -> Array[Vector2i]:
	"""Get all tiles visible to this enemy."""
	var tiles: Array[Vector2i] = []
	var player = get_tree().get_first_child_in_group("player")
	if not player:
		return tiles

	var gs = load("res://scripts/systems/grid_system.gd")
	var my_tile = gs.world_to_tile(global_position)
	var player_tile = gs.world_to_tile(player.global_position)
	var distance = gs.get_manhattan_distance(my_tile, player_tile)

	# Default 10-tile vision radius
	var vision_range = 10
	if distance <= vision_range:
		tiles.append(player_tile)

	return tiles

# === HEALTH MANAGEMENT ===
func take_damage(amount: int) -> void:
	"""Take damage and potentially die."""
	health -= amount
	health_changed.emit(health, max_health)

	if health <= 0:
		die()

func heal(amount: int) -> void:
	"""Restore health."""
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)

func die() -> void:
	"""Handle enemy death."""
	change_state(State.DEAD)
	enemy_defeated.emit(self)
	queue_free()
