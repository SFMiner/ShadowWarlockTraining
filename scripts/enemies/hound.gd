# res://scripts/enemies/hound.gd
extends Enemy
class_name Hound

# === HOUND AI PARAMETERS ===
@export var attack_range: float = 80.0  # 5 tiles at 16px per tile
@export var alert_distance: float = 160.0  # 10 tiles at 16px per tile
@export var attack_damage: int = 1
@export var movement_tiles: int = 3

func _ready() -> void:
	enemy_type = "hound_pale"
	health = 2
	max_health = 2
	super._ready()

# === AI LOGIC ===
func calculate_next_action() -> Dictionary:
	"""Hound AI: Patrol, pursue, or attack player.

	Returns:
		Dictionary with action_type, target_pos, and extra_data
	"""
	change_state(State.TELEGRAPHING)

	var player = get_tree().get_first_child_in_group("player")
	if not player:
		return idle_action()

	var distance_to_player = get_distance_to_player()

	# Attack if in range
	if distance_to_player <= attack_range:
		return attack_action(player.global_position)

	# Pursue if alerted
	if distance_to_player <= alert_distance and can_see_player():
		return move_action(calculate_pursuit_target(player))

	# Otherwise patrol
	return idle_action()

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

func move_action(target_pos: Vector2) -> Dictionary:
	"""Return a movement action toward target."""
	var action = {
		"action_type": "move",
		"target_pos": target_pos,
		"extra_data": {
			"movement_tiles": movement_tiles
		}
	}
	action_planned.emit(action)
	telegraph_data = action
	return action

func attack_action(target_pos: Vector2) -> Dictionary:
	"""Return an attack action toward target."""
	var action = {
		"action_type": "attack",
		"target_pos": target_pos,
		"extra_data": {
			"damage": attack_damage
		}
	}
	action_planned.emit(action)
	telegraph_data = action
	return action

func calculate_pursuit_target(player: Node2D) -> Vector2:
	"""Calculate position to move toward player.

	Args:
		player: Player node to pursue

	Returns:
		Target position for movement
	"""
	var gs = load("res://scripts/systems/grid_system.gd")
	var my_tile = gs.world_to_tile(global_position)
	var player_tile = gs.world_to_tile(player.global_position)

	# Move toward player one tile at a time
	var direction = (player_tile - my_tile).normalized()
	var next_tile = my_tile + direction.round()

	# Clamp to valid tiles
	if not gs.is_tile_valid(next_tile):
		return global_position

	return gs.tile_to_world(next_tile)

func execute_action(action: Dictionary) -> void:
	"""Execute the Hound's action.

	Args:
		action: Dictionary with action_type and parameters
	"""
	change_state(State.EXECUTING)

	var action_type = action.get("action_type", "idle")
	var target_pos = action.get("target_pos", global_position)

	match action_type:
		"move":
			await _execute_move(target_pos)
		"attack":
			await _execute_attack(target_pos)
		"idle":
			await get_tree().create_timer(0.3).timeout

	change_state(State.WAITING)

func _execute_move(target_pos: Vector2) -> void:
	"""Execute movement toward target.

	Args:
		target_pos: Target position to move toward
	"""
	print("%s moves toward %.1f, %.1f" % [name, target_pos.x, target_pos.y])

	# Animate movement
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, 0.4)
	await tween.finished

func _execute_attack(target_pos: Vector2) -> void:
	"""Execute attack animation.

	Args:
		target_pos: Position to attack toward
	"""
	print("%s attacks toward %.1f, %.1f" % [name, target_pos.x, target_pos.y])

	# Visual attack animation: lunge forward and back
	var tween = create_tween()
	var original_pos = global_position
	var lunge_direction = (target_pos - global_position).normalized()
	var lunge_distance = 20.0

	tween.tween_property(
		self,
		"global_position",
		original_pos + lunge_direction * lunge_distance,
		0.2
	)
	tween.tween_property(self, "global_position", original_pos, 0.2)
	await tween.finished
