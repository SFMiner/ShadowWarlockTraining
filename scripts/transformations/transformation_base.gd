# res://scripts/transformations/transformation_base.gd
extends Node

# === TRANSFORMATION PROPERTIES ===
var transformation_type: String = "base"  # e.g., "shadow_slide", "mirrorwalk"
var target: Node2D = null  # What entity to transform
var parameters: Dictionary = {}  # Transformation-specific parameters
var original_state: Dictionary = {}  # For undo functionality

# === STATE ===
var is_valid: bool = false
var is_executed: bool = false
var power_cost: int = 0
var effective_level: int = 1

# === TARGET TYPE ===
var target_type: int = GameConstants.TargetType.SELF
var player_level: int = 1

# === SIGNALS ===
signal validation_failed(reason: String)
signal transformation_complete()

func _init(p_target: Node2D = null, p_player_level: int = 1) -> void:
	"""
	Initialize transformation with target and player level.

	Args:
		p_target: The entity to transform
		p_player_level: Current player level for power calculations
	"""
	target = p_target
	player_level = p_player_level
	_determine_target_type()

func _determine_target_type() -> void:
	"""Determine the target type (SELF, OBJECT, or ENEMY) based on target."""
	if not target:
		target_type = GameConstants.TargetType.SELF
		return

	# Check if target is player
	if target.is_in_group("player"):
		target_type = GameConstants.TargetType.SELF
	# Check if target is enemy
	elif target.is_in_group("enemies"):
		target_type = GameConstants.TargetType.ENEMY
	# Otherwise treat as object
	else:
		target_type = GameConstants.TargetType.OBJECT

func calculate_power_cost() -> void:
	"""Calculate the power cost based on player level and target type."""
	effective_level = GameConstants.get_effective_level_for_target(player_level, target_type)
	power_cost = (player_level - GameConstants.TARGET_COSTS[target_type]) * GameConstants.TILE_SIZE

func validate() -> bool:
	"""
	Validate if this transformation is legal.
	Override in subclasses to add specific validation logic.

	Returns:
		true if transformation is valid, false otherwise
	"""
	if not target:
		validation_failed.emit("No target specified")
		return false

	# Calculate power cost
	calculate_power_cost()

	# Call subclass validation
	is_valid = _validate()
	if not is_valid:
		validation_failed.emit("Transformation validation failed")

	return is_valid

func _validate() -> bool:
	"""
	Virtual method - override in subclasses.
	Check if transformation is legal.

	Returns:
		true if valid, false otherwise
	"""
	return true

func execute() -> void:
	"""
	Execute the transformation.
	Saves original state before executing.
	"""
	if is_executed:
		push_warning("TransformationBase: Transformation already executed")
		return

	# Save original state for undo
	_save_original_state()

	# Execute the transformation
	_execute()

	is_executed = true
	transformation_complete.emit()

func _execute() -> void:
	"""
	Virtual method - override in subclasses.
	Perform the actual transformation.
	"""
	pass

func undo() -> void:
	"""
	Undo the transformation and restore original state.
	"""
	if not is_executed:
		push_warning("TransformationBase: Cannot undo - transformation not executed")
		return

	_clear_preview()
	_undo()
	is_executed = false

func _undo() -> void:
	"""
	Virtual method - override in subclasses.
	Reverse the transformation.
	"""
	pass

func preview() -> void:
	"""
	Show a preview/ghost of the transformation result.
	"""
	_preview()

func _preview() -> void:
	"""
	Virtual method - override in subclasses.
	Display ghost preview of transformation.
	"""
	pass

func clear_preview() -> void:
	"""
	Clear the preview display.
	"""
	_clear_preview()

func _clear_preview() -> void:
	"""
	Virtual method - override in subclasses.
	Remove preview visual effects.
	"""
	pass

# === STATE MANAGEMENT ===
func _save_original_state() -> void:
	"""Save the original state before executing transformation."""
	if target:
		original_state = {
			"position": target.position if target.has_meta("position") else Vector2.ZERO,
			"tile_position": target.current_position if target.has_meta("current_position") else Vector2i.ZERO,
			"rotation": target.rotation if target.has_meta("rotation") else 0.0,
			"scale": target.scale if target.has_meta("scale") else Vector2.ONE,
			"direction": target.current_direction if target.has_meta("current_direction") else Vector2.RIGHT,
		}

func restore_original_state() -> void:
	"""Restore target to its original state."""
	if not target or original_state.is_empty():
		return

	if original_state.has("position") and original_state["position"] != Vector2.ZERO:
		target.position = original_state["position"]
	if original_state.has("tile_position") and original_state["tile_position"] != Vector2i.ZERO:
		target.current_position = original_state["tile_position"]
	if original_state.has("rotation"):
		target.rotation = original_state["rotation"]
	if original_state.has("scale"):
		target.scale = original_state["scale"]
	if original_state.has("direction"):
		target.current_direction = original_state["direction"]

# === UTILITY FUNCTIONS ===
func get_target_info() -> Dictionary:
	"""
	Get information about the target.

	Returns:
		Dictionary with target information
	"""
	if not target:
		return {}

	return {
		"name": target.name,
		"type": "SELF" if target_type == GameConstants.TargetType.SELF else ("ENEMY" if target_type == GameConstants.TargetType.ENEMY else "OBJECT"),
		"position": target.position,
		"tile_position": target.current_position if target.has_meta("current_position") else Vector2i.ZERO,
	}

func get_transformation_info() -> Dictionary:
	"""
	Get information about this transformation.

	Returns:
		Dictionary with transformation details
	"""
	return {
		"type": transformation_type,
		"valid": is_valid,
		"executed": is_executed,
		"power_cost": power_cost,
		"effective_level": effective_level,
		"player_level": player_level,
		"target_type": target_type,
		"parameters": parameters.duplicate()
	}

func clone() -> TransformationBase:
	"""
	Create a copy of this transformation.

	Returns:
		A new TransformationBase with same parameters
	"""
	var clone = TransformationBase.new(target, player_level)
	clone.transformation_type = transformation_type
	clone.parameters = parameters.duplicate()
	clone.target_type = target_type
	return clone
