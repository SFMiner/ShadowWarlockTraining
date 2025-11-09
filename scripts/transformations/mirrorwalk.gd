# res://scripts/transformations/mirrorwalk.gd
extends TransformationBase
class_name Mirrorwalk

# === SCRIPT REFERENCES FOR STATIC FUNCTIONS ===
var gs = load("res://scripts/systems/grid_system.gd")
var gc = load("res://scripts/autoload/game_constants.gd")
var ps = load("res://scripts/systems/preview_system.gd")

# === MIRRORWALK SPECIFIC ===
var mirror_start: Vector2 = Vector2.ZERO  # Mirror line start point
var mirror_end: Vector2 = Vector2(100, 0)  # Mirror line end point
var reflected_position: Vector2 = Vector2.ZERO  # Calculated reflected position
var reflected_direction: Vector2 = Vector2.RIGHT  # Calculated reflected direction

func _init(p_target: Node2D = null, p_player_level: int = 1) -> void:
	"""Initialize Mirrorwalk transformation."""
	super._init(p_target, p_player_level)
	transformation_type = "mirrorwalk"

func set_parameters(p_mirror_start: Vector2, p_mirror_end: Vector2) -> void:
	"""
	Set Mirrorwalk parameters.

	Args:
		p_mirror_start: Start point of mirror line
		p_mirror_end: End point of mirror line
	"""
	mirror_start = p_mirror_start
	mirror_end = p_mirror_end
	parameters = {
		"mirror_start": mirror_start,
		"mirror_end": mirror_end
	}

func _validate() -> bool:
	"""
	Validate Mirrorwalk transformation.

	Checks:
	- Mirror line within range
	- Reflected position within bounds
	- Mirrorwalk IGNORES barriers (passes through)

	Returns:
		true if valid, false otherwise
	"""
	if not target:
		return false

	# Get current position
	var current_pos: Vector2
	if target.has_meta("current_position"):
		current_pos = gs.tile_to_world(target.current_position)
	else:
		current_pos = target.global_position

	# Find closest point on mirror line to target
	var closest_point = Geometry2D.get_closest_point_to_segment(current_pos, mirror_start, mirror_end)
	var distance_to_mirror = current_pos.distance_to(closest_point)

	# Check if mirror line is within range
	if distance_to_mirror > effective_level * gc.TILE_SIZE:
		validation_failed.emit("Mirror line out of range")
		return false

	# Calculate reflection
	reflected_position = _calculate_reflection(current_pos, mirror_start, mirror_end)

	# Check if reflected position is within bounds
	if not _is_position_valid(reflected_position):
		validation_failed.emit("Reflected position out of bounds")
		return false

	# Calculate direction reflection if target has direction
	if target.has_meta("current_direction"):
		var current_direction = target.current_direction
		reflected_direction = _calculate_direction_reflection(current_direction, mirror_start, mirror_end)
	else:
		reflected_direction = Vector2.RIGHT

	return true

func _calculate_reflection(point: Vector2, line_start: Vector2, line_end: Vector2) -> Vector2:
	"""
	Calculate reflected position across a line.

	Uses perpendicular projection method:
	1. Find closest point on line
	2. Reflect: reflected = 2 * closest - point

	Args:
		point: Point to reflect
		line_start: Mirror line start
		line_end: Mirror line end

	Returns:
		Reflected point position
	"""
	var line_vec: Vector2 = line_end - line_start
	var line_len_sq: float = line_vec.length_squared()

	if line_len_sq == 0:
		return point  # Line is a point, return original

	# Project point onto line
	var point_vec: Vector2 = point - line_start
	var t: float = point_vec.dot(line_vec) / line_len_sq
	var closest_point: Vector2 = line_start + t * line_vec

	# Reflect: point' = 2 * closest - point
	return 2 * closest_point - point

func _calculate_direction_reflection(direction: Vector2, line_start: Vector2, line_end: Vector2) -> Vector2:
	"""
	Calculate reflected direction vector across a line.

	Uses normal vector approach:
	d' = d - 2(d·n)n where n is perpendicular to line

	Args:
		direction: Direction to reflect
		line_start: Mirror line start
		line_end: Mirror line end

	Returns:
		Reflected direction vector (normalized)
	"""
	var line_vec: Vector2 = (line_end - line_start).normalized()
	var normal: Vector2 = Vector2(-line_vec.y, line_vec.x)  # Perpendicular

	# Reflect: d' = d - 2(d·n)n
	var reflected = direction - 2 * direction.dot(normal) * normal
	return reflected.normalized() if reflected.length() > 0 else direction

func _execute() -> void:
	"""
	Execute Mirrorwalk transformation.

	Moves target to reflected position and updates direction.
	CRITICAL: Passes through barriers (unlike Shadow Slide).
	Animates the reflection effect.
	"""
	if not target:
		return

	# Animate the mirrorwalk
	_animate_mirrorwalk()

	# Update target position
	target.global_position = reflected_position

	# Update tile position if target has it
	if target.has_meta("current_position"):
		target.current_position = gs.world_to_tile(reflected_position)

	# Update direction if target has it
	if target.has_meta("current_direction"):
		target.current_direction = reflected_direction
		# Call update method if it exists
		if target.has_method("update_sprite_direction"):
			target.update_sprite_direction()

func _animate_mirrorwalk() -> void:
	"""
	Animate Mirrorwalk with ripple effect.

	Creates a ripple distortion effect from the mirror line.
	"""
	var target_sprite: Sprite2D = null
	if target.has_node("Sprite2D"):
		target_sprite = target.get_node("Sprite2D")
	elif target is Sprite2D:
		target_sprite = target as Sprite2D

	if target_sprite:
		# Ripple/shimmer effect: fade to cyan, then back to normal
		var tween = create_tween()
		tween.tween_property(target_sprite, "modulate", Color(0.0, 0.75, 0.83, 0.5), 0.2)
		tween.tween_property(target_sprite, "modulate", Color.WHITE, 0.2)
		await tween.finished
	else:
		# No sprite, just wait
		await get_tree().create_timer(0.3).timeout

func _undo() -> void:
	"""Undo Mirrorwalk by restoring original position and direction."""
	restore_original_state()

func _preview() -> void:
	"""
	Show preview for Mirrorwalk.

	Displays:
	- Mirror line in cyan
	- Ghost at reflected position
	- Reflection path indicator
	"""
	if not target or not PreviewSystem:
		return

	# Get current position
	var current_pos: Vector2
	if target.has_meta("current_position"):
		current_pos = gs.tile_to_world(target.current_position)
	else:
		current_pos = target.global_position

	# Show mirrorwalk preview using PreviewSystem
	PreviewSystem.show_mirrorwalk_preview(mirror_start, mirror_end, reflected_position)

	# Show barrier-pass indicator
	var info_text = Sprite2D.new()
	info_text.name = "MirrorwalkInfo"
	info_text.modulate = Color(0.0, 0.75, 0.83, 0.5)  # Cyan semi-transparent
	info_text.position = (mirror_start + mirror_end) / 2.0
	PreviewSystem.preview_container.add_child(info_text)
	PreviewSystem.active_previews.append(info_text)

func _clear_preview() -> void:
	"""Clear Mirrorwalk preview."""
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
func get_reflection_info() -> Dictionary:
	"""
	Get information about the reflection.

	Returns:
		Dictionary with reflection details
	"""
	var current_pos: Vector2
	if target and target.has_meta("current_position"):
		current_pos = gs.tile_to_world(target.current_position)
	elif target:
		current_pos = target.global_position
	else:
		current_pos = Vector2.ZERO

	return {
		"original_position": current_pos,
		"reflected_position": reflected_position,
		"mirror_start": mirror_start,
		"mirror_end": mirror_end,
		"original_direction": target.current_direction if target and target.has_meta("current_direction") else Vector2.RIGHT,
		"reflected_direction": reflected_direction
	}
