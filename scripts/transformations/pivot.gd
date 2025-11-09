# res://scripts/transformations/pivot.gd
extends TransformationBase
class_name Pivot

# === SCRIPT REFERENCES ===
var ps = load("res://scripts/systems/preview_system.gd")

# === PIVOT SPECIFIC ===
var angle_degrees: float = 90.0  # Rotation angle
var clockwise: bool = true  # Rotation direction
var original_direction: Vector2 = Vector2.RIGHT  # For undo

func _init(p_target: Node2D = null, p_player_level: int = 1) -> void:
	"""Initialize Pivot transformation."""
	super._init(p_target, p_player_level)
	transformation_type = "pivot"

func set_parameters(p_angle_degrees: float, p_clockwise: bool = true) -> void:
	"""
	Set Pivot parameters.

	Args:
		p_angle_degrees: Rotation angle in degrees
		p_clockwise: Whether to rotate clockwise
	"""
	angle_degrees = p_angle_degrees
	clockwise = p_clockwise
	parameters = {
		"angle_degrees": angle_degrees,
		"clockwise": clockwise
	}

func _validate() -> bool:
	"""
	Validate Pivot transformation.

	Pivot is always valid (no range check for self-rotation).

	Returns:
		true (always valid)
	"""
	if not target:
		return false

	# Pivot has no range restriction - always valid
	# Store original direction for undo
	if target.has_meta("current_direction"):
		original_direction = target.current_direction
	else:
		original_direction = Vector2.RIGHT

	return true

func _execute() -> void:
	"""
	Execute Pivot transformation.

	Rotates target direction by specified angle.
	Position remains unchanged.
	Applies angle snapping if enabled in GameManager.
	"""
	if not target or not target.has_meta("current_direction"):
		return

	# Calculate rotation angle in radians
	var angle_rad = deg_to_rad(angle_degrees)
	if not clockwise:
		angle_rad = -angle_rad

	# Get current direction and rotate
	var current_direction = target.current_direction
	var new_direction = current_direction.rotated(angle_rad)

	# Apply angle snapping if enabled
	if GameManager.angle_snap:
		var angle = new_direction.angle()
		# Snap to 45-degree increments (8 directions)
		angle = round(angle / (PI / 4)) * (PI / 4)
		new_direction = Vector2.RIGHT.rotated(angle)

	# Update direction
	target.current_direction = new_direction

	# Update sprite direction if method exists
	if target.has_method("update_sprite_direction"):
		target.update_sprite_direction()

	# Brief animation
	_animate_pivot()

func _animate_pivot() -> void:
	"""
	Animate Pivot with quick rotation effect.

	Brief spin animation (0.2 seconds).
	"""
	var target_sprite: Sprite2D = null
	if target.has_node("Sprite2D"):
		target_sprite = target.get_node("Sprite2D")
	elif target is Sprite2D:
		target_sprite = target as Sprite2D

	if target_sprite:
		# Spin effect with color flash
		var tween = create_tween()
		tween.tween_property(target_sprite, "modulate", Color(1.0, 0.65, 0.15, 1.0), 0.1)
		tween.tween_property(target_sprite, "modulate", Color.WHITE, 0.1)
		await tween.finished
	else:
		# No sprite, just wait
		await get_tree().create_timer(0.2).timeout

func _undo() -> void:
	"""Undo Pivot by restoring original direction."""
	if target and target.has_meta("current_direction"):
		target.current_direction = original_direction
		if target.has_method("update_sprite_direction"):
			target.update_sprite_direction()

func _preview() -> void:
	"""
	Show preview for Pivot.

	Displays:
	- Rotation arc indicator
	- Arrow showing final direction
	"""
	if not target or not PreviewSystem:
		return

	# Get target position
	var target_pos: Vector2
	if target.has_meta("current_position"):
		target_pos = gs.tile_to_world(target.current_position) if has_meta("gs") else target.global_position
	else:
		target_pos = target.global_position

	# Show pivot preview using PreviewSystem
	PreviewSystem.show_pivot_preview(target_pos, angle_degrees, clockwise)

func _clear_preview() -> void:
	"""Clear Pivot preview."""
	if PreviewSystem:
		PreviewSystem.clear_all_previews()

# === UTILITY ===
func get_rotation_info() -> Dictionary:
	"""
	Get information about the rotation.

	Returns:
		Dictionary with rotation details
	"""
	return {
		"angle_degrees": angle_degrees,
		"clockwise": clockwise,
		"original_direction": original_direction,
		"final_direction": target.current_direction if target and target.has_meta("current_direction") else Vector2.RIGHT
	}
