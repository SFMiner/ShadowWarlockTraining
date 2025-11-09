# res://scripts/transformations/shadow_slide.gd
extends TransformationBase
class_name ShadowSlide

# === SCRIPT REFERENCES FOR STATIC FUNCTIONS ===
var gs = load("res://scripts/systems/grid_system.gd")
var gc = load("res://scripts/autoload/game_constants.gd")
var ps = load("res://scripts/systems/preview_system.gd")

# === SHADOW SLIDE SPECIFIC ===
var direction: Vector2 = Vector2.RIGHT  # Movement direction (normalized)
var distance_tiles: int = 1  # How far to move in tiles
var actual_distance: int = 0  # Actual distance moved (if blocked)
var blocked: bool = false  # Whether path was blocked by barrier

func _init(p_target: Node2D = null, p_player_level: int = 1) -> void:
	"""Initialize Shadow Slide transformation."""
	super._init(p_target, p_player_level)
	transformation_type = "shadow_slide"

func set_parameters(p_direction: Vector2, p_distance_tiles: int) -> void:
	"""
	Set Shadow Slide parameters.

	Args:
		p_direction: Movement direction (will be normalized)
		p_distance_tiles: Distance to move in tiles
	"""
	direction = p_direction.normalized() if p_direction.length() > 0 else Vector2.RIGHT
	distance_tiles = max(1, p_distance_tiles)
	parameters = {
		"direction": direction,
		"distance_tiles": distance_tiles
	}

func _validate() -> bool:
	"""
	Validate Shadow Slide transformation.

	Checks:
	- Range: distance_tiles <= effective_level
	- Barriers: path must be clear
	- Bounds: target position within arena

	Returns:
		true if valid, false otherwise
	"""
	if not target:
		return false

	# Check range: distance must not exceed effective level
	if distance_tiles > effective_level:
		validation_failed.emit("Out of range (max %d tiles)" % effective_level)
		return false

	# Get current position (world or tile)
	var current_pos: Vector2
	if target.has_meta("current_position"):
		# Use tile position if available
		current_pos = gs.tile_to_world(target.current_position)
	else:
		current_pos = target.global_position

	# Calculate target position
	var target_pos: Vector2 = current_pos + (direction * distance_tiles * gc.TILE_SIZE)

	# Check if target position is within bounds
	if not _is_position_valid(target_pos):
		validation_failed.emit("Target position out of bounds")
		return false

	# Check for barriers along path
	var space_state = target.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(current_pos, target_pos)
	query.collision_mask = 1  # Barrier layer (bit 0)
	query.exclude = [target]  # Don't collide with moving target
	var result = space_state.intersect_ray(query)

	if result:
		# Path is blocked
		blocked = true
		# Calculate how far we can actually go
		var blocked_point = result.position
		var max_distance = current_pos.distance_to(blocked_point)
		actual_distance = int(max_distance / gc.TILE_SIZE)

		# If we can't move at all, fail validation
		if actual_distance == 0:
			validation_failed.emit("Cannot move - barrier blocking")
			return false
		# If we can move partially, that's still valid
		return true
	else:
		# Path is clear
		blocked = false
		actual_distance = distance_tiles
		return true

func _execute() -> void:
	"""
	Execute Shadow Slide transformation.

	Moves target in direction, stopping at barriers if needed.
	Animates the movement with dissolve effect.
	"""
	if not target:
		return

	# Calculate actual target position
	var current_pos: Vector2
	if target.has_meta("current_position"):
		current_pos = gs.tile_to_world(target.current_position)
	else:
		current_pos = target.global_position

	var move_distance = actual_distance if blocked else distance_tiles
	var target_pos: Vector2 = current_pos + (direction * move_distance * gc.TILE_SIZE)

	# Animate the slide
	_animate_shadow_slide(target_pos)

	# Update target position
	target.global_position = target_pos

	# Update tile position if target has it
	if target.has_meta("current_position"):
		target.current_position = gs.world_to_tile(target_pos)

func _animate_shadow_slide(target_pos: Vector2) -> void:
	"""
	Animate Shadow Slide with dissolve and reappear effect.

	Args:
		target_pos: Target world position
	"""
	# Get sprite for animation
	var target_sprite: Sprite2D = null
	if target.has_node("Sprite2D"):
		target_sprite = target.get_node("Sprite2D")
	elif target is Sprite2D:
		target_sprite = target as Sprite2D

	if target_sprite:
		# Dissolve effect (fade out + shrink)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(target_sprite, "modulate:a", 0.0, 0.15)
		tween.tween_property(target_sprite, "scale", Vector2(0.5, 0.5), 0.15)
		await tween.finished

		# Update position while invisible
		target.global_position = target_pos

		# Reappear effect (fade in + restore scale)
		tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(target_sprite, "modulate:a", 1.0, 0.15)
		tween.tween_property(target_sprite, "scale", Vector2.ONE, 0.15)
		await tween.finished
	else:
		# No sprite, just move instantly
		await get_tree().create_timer(0.2).timeout
		target.global_position = target_pos

func _undo() -> void:
	"""Undo Shadow Slide by restoring original position."""
	restore_original_state()

func _preview() -> void:
	"""
	Show preview for Shadow Slide.

	Displays:
	- Ghost at target position
	- Dotted purple line path
	- Red highlight if blocked
	"""
	if not target or not PreviewSystem:
		return

	# Get current position
	var current_pos: Vector2
	if target.has_meta("current_position"):
		current_pos = gs.tile_to_world(target.current_position)
	else:
		current_pos = target.global_position

	# Calculate target position
	var move_distance = actual_distance if blocked else distance_tiles
	var target_pos: Vector2 = current_pos + (direction * move_distance * gc.TILE_SIZE)

	# Get tile positions for preview
	var from_tile = gs.world_to_tile(current_pos)
	var to_tile = gs.world_to_tile(target_pos)

	# Show shadow slide preview using PreviewSystem
	PreviewSystem.show_shadow_slide_preview(from_tile, to_tile)

	# If blocked, show blocking indicator
	if blocked:
		var ghost = Sprite2D.new()
		ghost.name = "BlockedIndicator"
		ghost.position = target_pos
		ghost.modulate = Color(1.0, 0.0, 0.0, 0.3)  # Red semi-transparent
		PreviewSystem.preview_container.add_child(ghost)
		PreviewSystem.active_previews.append(ghost)

func _clear_preview() -> void:
	"""Clear Shadow Slide preview."""
	if PreviewSystem:
		PreviewSystem.clear_all_previews()

func _is_position_valid(world_pos: Vector2) -> bool:
	"""
	Check if a world position is valid (within arena bounds).

	Args:
		world_pos: World position to check

	Returns:
		true if position is within bounds, false otherwise
	"""
	# Get arena bounds from current level or use sensible defaults
	# For now, allow any position (bounds checking handled by level)
	# TODO: Get actual arena bounds from LevelManager
	return true

# === UTILITY ===
func get_blocked_status() -> Dictionary:
	"""
	Get information about blocking.

	Returns:
		Dictionary with blocked status and distance info
	"""
	return {
		"blocked": blocked,
		"intended_distance": distance_tiles,
		"actual_distance": actual_distance
	}
