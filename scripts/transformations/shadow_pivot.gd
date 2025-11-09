# res://scripts/transformations/shadow_pivot.gd
extends TransformationBase
class_name ShadowPivot

# === SCRIPT REFERENCES FOR STATIC FUNCTIONS ===
var gs = load("res://scripts/systems/grid_system.gd")
var gc = load("res://scripts/autoload/game_constants.gd")
var ps = load("res://scripts/systems/preview_system.gd")

# === SHADOW PIVOT SPECIFIC ===
var anchor_point: Vector2 = Vector2.ZERO  # Center of rotation
var angle_degrees: float = 90.0  # Rotation angle
var clockwise: bool = true  # Rotation direction
var rotated_position: Vector2 = Vector2.ZERO  # Calculated final position
var rotated_direction: Vector2 = Vector2.RIGHT  # Calculated final direction
var original_position: Vector2 = Vector2.ZERO  # For undo
var original_direction: Vector2 = Vector2.RIGHT  # For undo

func _init(p_target: Node2D = null, p_player_level: int = 1) -> void:
	"""Initialize Shadow Pivot transformation."""
	super._init(p_target, p_player_level)
	transformation_type = "shadow_pivot"

func set_parameters(p_anchor_point: Vector2, p_angle_degrees: float, p_clockwise: bool = true) -> void:
	"""
	Set Shadow Pivot parameters.

	Args:
		p_anchor_point: Center point of rotation
		p_angle_degrees: Rotation angle in degrees
		p_clockwise: Whether to rotate clockwise
	"""
	anchor_point = p_anchor_point
	angle_degrees = p_angle_degrees
	clockwise = p_clockwise
	parameters = {
		"anchor_point": anchor_point,
		"angle_degrees": angle_degrees,
		"clockwise": clockwise
	}

func _validate() -> bool:
	"""
	Validate Shadow Pivot transformation.

	Checks:
	- Ability unlocked at level 3+
	- Anchor point within range
	- Final position within bounds
	- Target not at anchor (would create invalid rotation)

	Returns:
		true if valid, false otherwise
	"""
	if not target:
		return false

	# Check if Shadow Pivot is unlocked (Level 3+)
	if not GameManager.abilities.get("shadow_pivot", false):
		validation_failed.emit("Shadow Pivot not unlocked")
		return false

	# Get current position
	var current_pos: Vector2
	if target.has_meta("current_position"):
		current_pos = gs.tile_to_world(target.current_position)
		original_position = current_pos
	else:
		current_pos = target.global_position
		original_position = current_pos

	# Check distance from target to anchor
	var distance_to_anchor = current_pos.distance_to(anchor_point)
	if distance_to_anchor > effective_level * gc.TILE_SIZE:
		validation_failed.emit("Anchor point out of range")
		return false

	# Prevent rotation around target itself
	if distance_to_anchor < 1.0:
		validation_failed.emit("Cannot rotate around self")
		return false

	# Calculate rotated position
	rotated_position = _rotate_point_around_pivot(current_pos, anchor_point, angle_degrees, clockwise)

	# Check if rotated position is within bounds
	if not _is_position_valid(rotated_position):
		validation_failed.emit("Rotated position out of bounds")
		return false

	# Calculate rotated direction
	if target.has_meta("current_direction"):
		original_direction = target.current_direction
		var angle_rad = deg_to_rad(angle_degrees)
		if not clockwise:
			angle_rad = -angle_rad
		rotated_direction = original_direction.rotated(angle_rad)
	else:
		rotated_direction = Vector2.RIGHT

	return true

func _rotate_point_around_pivot(point: Vector2, pivot: Vector2, angle_deg: float, clockwise: bool) -> Vector2:
	"""
	Rotate a point around a pivot point.

	Transformation:
	1. Translate to origin: p' = p - pivot
	2. Rotate: p'' = rotate(p', angle)
	3. Translate back: result = p'' + pivot

	Args:
		point: Point to rotate
		pivot: Center of rotation
		angle_deg: Angle in degrees
		clockwise: Whether to rotate clockwise

	Returns:
		Rotated point position
	"""
	# Convert angle to radians
	var angle_rad = deg_to_rad(angle_deg)
	if not clockwise:
		angle_rad = -angle_rad

	# Translate to origin
	var translated = point - pivot

	# Rotate using matrix rotation
	var rotated = translated.rotated(angle_rad)

	# Translate back
	return rotated + pivot

func _execute() -> void:
	"""
	Execute Shadow Pivot transformation.

	Orbits target around anchor point and updates direction.
	Animates the orbital motion.
	"""
	if not target:
		return

	# Animate the pivot
	_animate_shadow_pivot()

	# Update target position
	target.global_position = rotated_position

	# Update tile position if target has it
	if target.has_meta("current_position"):
		target.current_position = gs.world_to_tile(rotated_position)

	# Update direction if target has it
	if target.has_meta("current_direction"):
		target.current_direction = rotated_direction
		if target.has_method("update_sprite_direction"):
			target.update_sprite_direction()

func _animate_shadow_pivot() -> void:
	"""
	Animate Shadow Pivot with orbital motion effect.

	Creates an orbital spark trail effect with smooth motion.
	"""
	var target_sprite: Sprite2D = null
	if target.has_node("Sprite2D"):
		target_sprite = target.get_node("Sprite2D")
	elif target is Sprite2D:
		target_sprite = target as Sprite2D

	if target_sprite:
		# Orbital glow effect
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(target_sprite, "modulate", Color(1.0, 0.65, 0.15, 1.0), 0.15)
		tween.tween_property(target, "global_position", rotated_position, 0.4)
		await tween.finished
		tween = create_tween()
		tween.tween_property(target_sprite, "modulate", Color.WHITE, 0.1)
		await tween.finished
	else:
		# No sprite, just move
		var tween = create_tween()
		tween.tween_property(target, "global_position", rotated_position, 0.4)
		await tween.finished

func _undo() -> void:
	"""Undo Shadow Pivot by restoring original position and direction."""
	if target:
		target.global_position = original_position
		if target.has_meta("current_position"):
			target.current_position = gs.world_to_tile(original_position)
		if target.has_meta("current_direction"):
			target.current_direction = original_direction
			if target.has_method("update_sprite_direction"):
				target.update_sprite_direction()

func _preview() -> void:
	"""
	Show preview for Shadow Pivot.

	Displays:
	- Anchor point (amber circle)
	- Tether line from target to anchor
	- Rotation arc
	- Ghost at final position
	"""
	if not target or not PreviewSystem:
		return

	# Get current position
	var current_pos: Vector2
	if target.has_meta("current_position"):
		current_pos = gs.tile_to_world(target.current_position)
	else:
		current_pos = target.global_position

	# Generate arc points for preview
	var arc_points = _generate_rotation_arc(current_pos, anchor_point, angle_degrees, clockwise)

	# Show shadow pivot preview using PreviewSystem
	PreviewSystem.show_shadow_pivot_preview(anchor_point, current_pos, arc_points)

func _generate_rotation_arc(start_pos: Vector2, pivot: Vector2, angle_deg: float, clockwise: bool) -> PackedVector2Array:
	"""
	Generate points for rotation arc visualization.

	Args:
		start_pos: Starting position
		pivot: Center of rotation
		angle_deg: Total rotation angle
		clockwise: Rotation direction

	Returns:
		Array of points defining the arc
	"""
	var arc_points = PackedVector2Array()

	# Calculate offset vector
	var offset = start_pos - pivot
	var radius = offset.length()
	var start_angle = offset.angle()

	# Calculate end angle
	var angle_rad = deg_to_rad(angle_deg)
	if not clockwise:
		angle_rad = -angle_rad
	var end_angle = start_angle + angle_rad

	# Generate arc points (every 5 degrees)
	var steps = max(1, int(abs(angle_deg) / 5.0))
	for i in range(steps + 1):
		var t = float(i) / float(steps)
		var current_angle = start_angle + (end_angle - start_angle) * t
		var x = pivot.x + cos(current_angle) * radius
		var y = pivot.y + sin(current_angle) * radius
		arc_points.append(Vector2(x, y))

	return arc_points

func _clear_preview() -> void:
	"""Clear Shadow Pivot preview."""
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
func get_rotation_info() -> Dictionary:
	"""
	Get information about the rotation.

	Returns:
		Dictionary with rotation details
	"""
	return {
		"anchor_point": anchor_point,
		"angle_degrees": angle_degrees,
		"clockwise": clockwise,
		"original_position": original_position,
		"rotated_position": rotated_position,
		"original_direction": original_direction,
		"rotated_direction": rotated_direction
	}
