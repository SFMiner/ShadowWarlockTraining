# res://scripts/systems/transformation_validator.gd
extends Node

# === SCRIPT REFERENCES FOR STATIC FUNCTIONS ===
var gc = load("res://scripts/autoload/game_constants.gd")
var gs = load("res://scripts/systems/grid_system.gd")

# === VALIDATION RESULTS ===
class ValidationResult:
	var valid: bool = false
	var reason: String = ""
	var warnings: Array[String] = []

	func _init(p_valid: bool = false, p_reason: String = "") -> void:
		valid = p_valid
		reason = p_reason

	func add_warning(warning: String) -> void:
		warnings.append(warning)

# === MASTER VALIDATION ===
func validate(transformation: Node) -> ValidationResult:
	"""
	Perform comprehensive validation of a transformation.

	Args:
		transformation: The transformation object to validate

	Returns:
		ValidationResult with valid status and reason
	"""
	if not transformation:
		return ValidationResult.new(false, "Transformation is null")

	# Check basic properties
	if not transformation.has_meta("target") or transformation.target == null:
		return ValidationResult.new(false, "No target specified for transformation")

	# Perform specific validation based on transformation type
	var result: ValidationResult

	match transformation.transformation_type:
		"shadow_slide":
			result = validate_shadow_slide(transformation)
		"mirrorwalk":
			result = validate_mirrorwalk(transformation)
		"pivot":
			result = validate_pivot(transformation)
		"shadow_pivot":
			result = validate_shadow_pivot(transformation)
		"shadowshift":
			result = validate_shadowshift(transformation)
		_:
			result = ValidationResult.new(false, "Unknown transformation type: %s" % transformation.transformation_type)

	return result

# === SHADOW SLIDE VALIDATION ===
func validate_shadow_slide(transformation: Node) -> ValidationResult:
	"""
	Validate Shadow Slide (translation) transformation.
	Checks: range, collision (barriers block), bounds
	"""
	var result = ValidationResult.new(true, "")

	# Check range
	if not validate_range(transformation):
		return ValidationResult.new(false, "Target is outside effective range for Shadow Slide")

	# Check collision - barriers block Shadow Slide
	if not validate_collision(transformation, true):
		return ValidationResult.new(false, "Path blocked by barrier or obstacle")

	# Check bounds
	if not validate_bounds(transformation):
		return ValidationResult.new(false, "Target destination outside arena bounds")

	return result

# === MIRRORWALK VALIDATION ===
func validate_mirrorwalk(transformation: Node) -> ValidationResult:
	"""
	Validate Mirrorwalk (reflection) transformation.
	Checks: range, bounds (barriers do NOT block)
	"""
	var result = ValidationResult.new(true, "")

	# Check range
	if not validate_range(transformation):
		return ValidationResult.new(false, "Mirror line is outside effective range")

	# Check bounds (no collision check - Mirrorwalk passes through barriers)
	if not validate_bounds(transformation):
		return ValidationResult.new(false, "Reflected position outside arena bounds")

	return result

# === PIVOT VALIDATION ===
func validate_pivot(_transformation: Node) -> ValidationResult:
	"""
	Validate Pivot (self-rotation) transformation.
	Checks: always valid (self-rotation only)
	"""
	# Self-rotation is always valid
	return ValidationResult.new(true, "")

# === SHADOW PIVOT VALIDATION ===
func validate_shadow_pivot(transformation: Node) -> ValidationResult:
	"""
	Validate Shadow Pivot (external rotation) transformation.
	Checks: ability unlock (level 3+), range, bounds
	"""
	var result = ValidationResult.new(true, "")

	# Check unlock level
	if GameManager.player_level < 3:
		return ValidationResult.new(false, "Shadow Pivot unlocked at Level 3")

	# Check range
	if not validate_range(transformation):
		return ValidationResult.new(false, "Anchor point is outside effective range")

	# Check bounds
	if not validate_bounds(transformation):
		return ValidationResult.new(false, "Rotated position outside arena bounds")

	return result

# === SHADOWSHIFT VALIDATION ===
func validate_shadowshift(transformation: Node) -> ValidationResult:
	"""
	Validate Shadowshift (dilation/scaling) transformation.
	Checks: ability unlock (level-dependent), scale bounds, target restrictions
	"""
	var result = ValidationResult.new(true, "")

	var target_type = transformation.target_type if transformation.has_meta("target_type") else GameConstants.TargetType.SELF

	# Check ability unlock based on target type and level
	match target_type:
		GameConstants.TargetType.SELF:
			if GameManager.player_level < 2:
				return ValidationResult.new(false, "Shadowshift (self) unlocked at Level 2")
		GameConstants.TargetType.OBJECT:
			if GameManager.player_level < 4:
				return ValidationResult.new(false, "Shadowshift (object) unlocked at Level 4")
		GameConstants.TargetType.ENEMY:
			if GameManager.player_level < 6:
				return ValidationResult.new(false, "Shadowshift (enemy) unlocked at Level 6")

	# Check if level is odd (Shadowshift only on odd levels)
	if GameManager.player_level % 2 == 0:
		result.add_warning("Shadowshift is most powerful on odd levels")

	# Check scale bounds
	if transformation.has_meta("scale_factor"):
		var scale_factor: float = transformation.scale_factor
		var scale_range = gc.get_shadowshift_range(GameManager.player_level, target_type)

		if scale_factor < scale_range.x or scale_factor > scale_range.y:
			return ValidationResult.new(false, "Scale factor %.2f outside allowed range (%.2f - %.2f)" % [scale_factor, scale_range.x, scale_range.y])

	return result

# === RANGE VALIDATION ===
func validate_range(transformation: Node) -> bool:
	"""
	Check if target is within effective range.

	Args:
		transformation: The transformation to check

	Returns:
		true if target within range, false otherwise
	"""
	if not transformation.target:
		return false

	var player_pos: Vector2i
	var target_pos: Vector2i

	# Get player position
	if transformation.has_meta("player_position"):
		player_pos = transformation.player_position
	else:
		# Try to find player in scene
		var player_node = get_tree().root.find_child("Player", true, false)
		if player_node and player_node.has_meta("current_position"):
			player_pos = player_node.current_position
		else:
			push_warning("TransformationValidator: Could not determine player position")
			return true  # Allow if we can't determine player position

	# Get target position
	if transformation.target.has_meta("current_position"):
		target_pos = transformation.target.current_position
	else:
		target_pos = gs.world_to_tile(transformation.target.position)

	# Get effective range
	var ability_name = transformation.transformation_type
	var range_tiles = gc.get_transformation_range(GameManager.player_level, ability_name)
	var distance = gs.get_manhattan_distance(player_pos, target_pos)

	return distance <= range_tiles

# === TARGET TYPE VALIDATION ===
func validate_target_type(transformation: Node) -> bool:
	"""
	Check if ability is unlocked for the target type.

	Args:
		transformation: The transformation to check

	Returns:
		true if ability available for target type, false otherwise
	"""
	if not transformation.target:
		return false

	var ability_name = transformation.transformation_type
	var target_type = transformation.target_type if transformation.has_meta("target_type") else GameConstants.TargetType.SELF

	# Check if ability is unlocked
	if not GameManager.abilities.get(ability_name, false):
		return false

	# Check target-specific restrictions
	match ability_name:
		"shadowshift_self":
			return target_type == GameConstants.TargetType.SELF
		"shadowshift_object":
			return target_type in [GameConstants.TargetType.SELF, GameConstants.TargetType.OBJECT]
		"shadowshift_enemy":
			return target_type == GameConstants.TargetType.ENEMY
		"shadow_pivot":
			return GameManager.player_level >= 3

	return true

# === COLLISION VALIDATION ===
func validate_collision(transformation: Node, _barriers_block: bool = true) -> bool:
	"""
	Check if destination tile is valid and obstacles are clear.

	Args:
		transformation: The transformation to check
		_barriers_block: If true, barriers block; if false, allow passage (not yet implemented)

	Returns:
		true if collision-free, false otherwise
	"""
	if not transformation.target or not transformation.has_meta("destination_tile"):
		return true  # Can't check, assume valid

	var destination: Vector2i = transformation.destination_tile
	var current_pos: Vector2i

	if transformation.target.has_meta("current_position"):
		current_pos = transformation.target.current_position
	else:
		current_pos = gs.world_to_tile(transformation.target.position)

	# Get tiles along path
	var path_tiles = gs.get_line_of_tiles(current_pos, destination)

	# Check each tile along the path
	for tile in path_tiles:
		# Check if tile is in bounds (assume grid_size is available)
		# This would need to be passed in or retrieved from level

		# TODO: Check for barriers/walls at tile
		# This requires access to tilemap which should be passed in validation context

		# For now, assume path is clear if we get here
		pass

	return true

# === BOUNDS VALIDATION ===
func validate_bounds(transformation: Node) -> bool:
	"""
	Check if transformation keeps target within arena bounds.

	Args:
		transformation: The transformation to check

	Returns:
		true if in bounds, false otherwise
	"""
	if not transformation.target or not transformation.has_meta("destination_tile"):
		return true

	var destination: Vector2i = transformation.destination_tile

	# Get grid size from level or use default
	var grid_size: Vector2i = Vector2i(40, 25)  # Default, should be from LevelManager

	return gs.is_tile_valid(destination, grid_size)

# === MULTI-TARGET VALIDATION ===
func validate_multi_target(targets: Array[Node2D]) -> ValidationResult:
	"""
	Check if multiple targets can be affected.

	Args:
		targets: Array of target entities

	Returns:
		ValidationResult indicating validity
	"""
	var result = ValidationResult.new(true, "")

	if targets.is_empty():
		return ValidationResult.new(false, "No targets specified")

	var target_count = targets.size()

	# Check Split Power limits
	if GameManager.abilities.get("split_power", false):
		var max_split = GameManager.multi_target.get("split_max_targets", 1)
		if target_count > max_split:
			result.add_warning("Split Power limited to %d targets (have %d)" % [max_split, target_count])

	# Check Mastery limits
	if GameManager.abilities.get("multi_target_mastery", false):
		var max_mastery = GameManager.multi_target.get("mastery_max_targets", 1)
		if target_count > max_mastery:
			return ValidationResult.new(false, "Multi-Target Mastery limited to %d targets (have %d)" % [max_mastery, target_count])

	return result

# === COMBO VALIDATION ===
func validate_combo(transformations: Array[Node]) -> ValidationResult:
	"""
	Check if a combo sequence is valid.

	Args:
		transformations: Array of transformations in combo sequence

	Returns:
		ValidationResult indicating validity
	"""
	if transformations.is_empty():
		return ValidationResult.new(false, "No transformations in combo")

	var combo_length = transformations.size()

	# Check combo unlock level
	match combo_length:
		2:
			if not GameManager.abilities.get("combo_2", false):
				return ValidationResult.new(false, "Combo 2 unlocked at Level 4")
		3:
			if not GameManager.abilities.get("combo_3", false):
				return ValidationResult.new(false, "Combo 3 unlocked at Level 7")
		4:
			if not GameManager.abilities.get("combo_4", false):
				return ValidationResult.new(false, "Combo 4 unlocked at Level 8")
		_:
			if combo_length > 4:
				return ValidationResult.new(false, "Maximum combo length is 4")

	# Validate each transformation in combo
	for transformation in transformations:
		var result = validate(transformation)
		if not result.valid:
			return ValidationResult.new(false, "Combo step invalid: %s" % result.reason)

	return ValidationResult.new(true, "")

# === UTILITY ===
func get_validation_error_text(result: ValidationResult) -> String:
	"""
	Format validation result into user-readable text.

	Args:
		result: The validation result

	Returns:
		String with error or success message
	"""
	if result.valid:
		return "Valid transformation"
	else:
		var text = "Invalid: " + result.reason
		if not result.warnings.is_empty():
			text += "\nWarnings:\n"
			for warning in result.warnings:
				text += "  - " + warning + "\n"
		return text
