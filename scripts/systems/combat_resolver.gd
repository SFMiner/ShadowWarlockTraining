# res://scripts/systems/combat_resolver.gd
extends Node

# === SCRIPT REFERENCES ===
var gs = load("res://scripts/systems/grid_system.gd")

# === STATE ===
var is_resolving: bool = false
var resolution_complete: Signal = Signal()

# === SIGNALS ===
signal enemy_action_started(enemy: Node2D)
signal enemy_action_complete(enemy: Node2D)
signal player_hit(enemy: Node2D)
signal enemy_defeated(enemy: Node2D)
signal victory()
signal level_reset()

func _ready() -> void:
	"""Initialize Combat Resolver."""
	add_to_group("combat_resolver")
	print("Combat Resolver initialized")

# === MAIN RESOLUTION ===
func execute_enemy_actions(enemy_actions: Array[Dictionary]) -> void:
	"""
	Execute all queued enemy actions sequentially.

	Args:
		enemy_actions: Array of {enemy, action_type, params} dictionaries
	"""
	if is_resolving:
		push_warning("Already resolving - ignoring new resolution request")
		return

	is_resolving = true
	print("Combat Resolution: Starting (%d enemy actions)" % enemy_actions.size())

	for action_data in enemy_actions:
		if not action_data.has("enemy"):
			continue

		var enemy = action_data["enemy"]
		if not is_instance_valid(enemy):
			continue

		enemy_action_started.emit(enemy)
		print("Executing action for %s" % enemy.name)

		# Execute the action
		await _execute_single_action(enemy, action_data)

		enemy_action_complete.emit(enemy)

		# Check if player was hit
		if check_player_collision(enemy):
			print("Player hit during combat resolution!")
			player_hit.emit(enemy)
			trigger_level_reset()
			is_resolving = false
			return

	is_resolving = false
	resolution_complete.emit()

func _execute_single_action(enemy: Node2D, action_data: Dictionary) -> void:
	"""
	Execute a single enemy action.

	Args:
		enemy: Enemy performing action
		action_data: Dictionary with action info
	"""
	var action_type = action_data.get("action_type", "idle")
	var params = action_data.get("params", {})

	match action_type:
		"move":
			var target_pos = params.get("target_pos", enemy.global_position)
			await _execute_move(enemy, target_pos)

		"attack":
			var target_pos = params.get("target_pos", Vector2.ZERO)
			await _execute_attack(enemy, target_pos)

		"idle":
			print("%s performs no action" % enemy.name)
			await get_tree().create_timer(0.3).timeout

		_:
			print("%s performs unknown action: %s" % [enemy.name, action_type])
			await get_tree().create_timer(0.3).timeout

func _execute_move(enemy: Node2D, target_pos: Vector2) -> void:
	"""
	Execute enemy movement.

	Args:
		enemy: Enemy to move
		target_pos: Target position
	"""
	print("%s moves to %.1f, %.1f" % [enemy.name, target_pos.x, target_pos.y])

	# Check for enemy-enemy collision
	var other_enemies = get_tree().get_nodes_in_group("enemies")
	if check_enemy_enemy_collision(enemy, other_enemies):
		print("%s blocked by another enemy" % enemy.name)
		return

	# Check for hazard collision at target
	if check_hazard_collision_at(target_pos):
		print("%s would hit hazard at target" % enemy.name)
		return

	# Animate movement
	var tween = create_tween()
	tween.tween_property(enemy, "global_position", target_pos, 0.4)
	await tween.finished

	# Update tile position if enemy has it
	if enemy.has_meta("current_position"):
		enemy.current_position = gs.world_to_tile(target_pos)

func _execute_attack(enemy: Node2D, target_pos: Vector2) -> void:
	"""
	Execute enemy attack (visual only, damage checked via collision).

	Args:
		enemy: Enemy attacking
		target_pos: Target position
	"""
	print("%s attacks toward %.1f, %.1f" % [enemy.name, target_pos.x, target_pos.y])

	# Visual attack animation
	var tween = create_tween()
	var original_pos = enemy.global_position
	tween.tween_property(enemy, "global_position", target_pos, 0.2)
	tween.tween_property(enemy, "global_position", original_pos, 0.2)
	await tween.finished

# === COLLISION DETECTION ===
func check_player_collision(enemy: Node2D) -> bool:
	"""
	Check if enemy overlaps player.

	Args:
		enemy: Enemy to check

	Returns:
		true if collision detected
	"""
	var player = get_tree().get_first_child_in_group("player")
	if not player:
		return false

	var distance = enemy.global_position.distance_to(player.global_position)
	var collision_distance = 20.0  # Approximate collision distance

	return distance < collision_distance

func check_enemy_enemy_collision(enemy: Node2D, others: Array[Node2D]) -> bool:
	"""
	Check if enemy collides with other enemies.

	Args:
		enemy: Enemy to check
		others: Array of other enemies

	Returns:
		true if collision detected
	"""
	for other in others:
		if other == enemy or not is_instance_valid(other):
			continue

		var distance = enemy.global_position.distance_to(other.global_position)
		var collision_distance = 20.0

		if distance < collision_distance:
			print("%s blocked by %s" % [enemy.name, other.name])
			return true

	return false

func check_hazard_collision(entity: Node2D) -> bool:
	"""
	Check if entity is on a hazard tile.

	Args:
		entity: Entity to check

	Returns:
		true if on hazard
	"""
	# TODO: Check TileMap for hazard tiles at entity position
	# For now, return false (no hazards)
	return false

func check_hazard_collision_at(world_pos: Vector2) -> bool:
	"""
	Check if a world position contains a hazard.

	Args:
		world_pos: World position to check

	Returns:
		true if hazard at position
	"""
	# TODO: Check TileMap for hazard tiles at position
	# For now, return false (no hazards)
	return false

# === LEVEL RESET ===
func trigger_level_reset() -> void:
	"""
	Reset level after player gets hit.

	Restores all positions and clears action queues.
	"""
	print("LEVEL RESET TRIGGERED")
	level_reset.emit()

	# Get all entities
	var player = get_tree().get_first_child_in_group("player")
	var enemies = get_tree().get_nodes_in_group("enemies")

	# Reset player
	if player:
		# Store start position - for now use current position as reset point
		# TODO: Get actual spawn position from level
		pass

	# Reset enemies
	for enemy in enemies:
		# TODO: Reset enemy to spawn position
		pass

	# Update resets counter
	if GameManager:
		GameManager.resets_used += 1

	# Restart turn cycle
	if TurnManager:
		TurnManager.turn_number = 0
		TurnManager.current_phase = TurnManager.Phase.IDLE
		TurnManager.clear_action_queue()
		await get_tree().create_timer(0.5).timeout
		TurnManager.start_turn()

# === WIN CONDITION CHECKING ===
func check_victory_conditions() -> bool:
	"""
	Check if player has won the level.

	Returns:
		true if victory condition met
	"""
	# Check if all enemies defeated
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return true

	# TODO: Check level-specific objectives
	# - Reached exit
	# - Collected items
	# - Protected NPC

	return false

# === ENEMY REMOVAL ===
func remove_enemy(enemy: Node2D) -> void:
	"""
	Remove defeated enemy from scene.

	Args:
		enemy: Enemy to remove
	"""
	if not is_instance_valid(enemy):
		return

	print("%s removed from combat" % enemy.name)
	enemy_defeated.emit(enemy)

	# Update bestiary if needed
	if GameManager and enemy.has_meta("enemy_type"):
		GameManager.unlock_bestiary_entry(enemy.enemy_type)

	# Remove from scene
	enemy.queue_free()

	# Check if all enemies defeated
	if check_victory_conditions():
		print("ALL ENEMIES DEFEATED - VICTORY!")
		victory.emit()

# === UTILITY ===
func get_resolution_info() -> Dictionary:
	"""
	Get combat resolution information.

	Returns:
		Dictionary with resolution state
	"""
	return {
		"is_resolving": is_resolving,
		"enemies_remaining": get_tree().get_nodes_in_group("enemies").size()
	}
