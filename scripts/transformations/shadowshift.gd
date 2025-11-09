# res://scripts/transformations/shadowshift.gd
extends TransformationBase
class_name Shadowshift

# === SCRIPT REFERENCES FOR STATIC FUNCTIONS ===
var gs = load("res://scripts/systems/grid_system.gd")
var gc = load("res://scripts/autoload/game_constants.gd")
var ps = load("res://scripts/systems/preview_system.gd")

# === SHADOWSHIFT SPECIFIC ===
var scale_factor: float = 1.0  # New size (0.5 = 50%, 2.0 = 200%)
var center_point: Vector2 = Vector2.ZERO  # Center of dilation
var persistent: bool = true  # Whether size change persists
var original_scale: Vector2 = Vector2.ONE  # For undo

func _init(p_target: Node2D = null, p_player_level: int = 1) -> void:
	"""Initialize Shadowshift transformation."""
	super._init(p_target, p_player_level)
	transformation_type = "shadowshift"

func set_parameters(p_scale_factor: float, p_center_point: Vector2 = Vector2.ZERO, p_persistent: bool = true) -> void:
	"""
	Set Shadowshift parameters.

	Args:
		p_scale_factor: New size multiplier (0.5-2.0)
		p_center_point: Center of dilation (usually target position)
		p_persistent: Whether size persists after turn
	"""
	scale_factor = clamp(p_scale_factor, 0.5, 2.0)
	center_point = p_center_point
	persistent = p_persistent
	parameters = {
		"scale_factor": scale_factor,
		"center_point": center_point,
		"persistent": persistent
	}

func _validate() -> bool:
	"""
	Validate Shadowshift transformation.

	Checks:
	- Ability unlocked for target type (L2 self, L4 object, L6 enemy)
	- Scale factor within bounds (0.5-2.0)
	- Only available on ODD player levels
	- Final size fits in arena

	Returns:
		true if valid, false otherwise
	"""
	if not target:
		return false

	# Check if Shadowshift is available on odd levels only
	if player_level % 2 == 0:
		validation_failed.emit("Shadowshift only available on odd levels")
		return false

	# Check if ability is unlocked for target type
	match target_type:
		GameConstants.TargetType.SELF:
			if not GameManager.abilities.get("shadowshift_self", false):
				validation_failed.emit("Self Shadowshift not unlocked (requires Level 2)")
				return false
		GameConstants.TargetType.OBJECT:
			if not GameManager.abilities.get("shadowshift_object", false):
				validation_failed.emit("Object Shadowshift not unlocked (requires Level 4)")
				return false
		GameConstants.TargetType.ENEMY:
			if not GameManager.abilities.get("shadowshift_enemy", false):
				validation_failed.emit("Enemy Shadowshift not unlocked (requires Level 6)")
				return false

	# Get valid scale range from GameConstants
	var scale_range = gc.get_shadowshift_range(player_level, target_type)
	if scale_factor < scale_range.x or scale_factor > scale_range.y:
		validation_failed.emit("Scale %.2f out of range [%.2f - %.2f]" % [scale_factor, scale_range.x, scale_range.y])
		return false

	# Check if scaled size fits in arena
	if not _is_scaled_position_valid(scale_factor):
		validation_failed.emit("Scaled object does not fit in arena")
		return false

	# Store original scale for undo
	original_scale = target.scale

	return true

func _execute() -> void:
	"""
	Execute Shadowshift transformation.

	Applies scale to sprite and collision shapes.
	Updates size-dependent properties.
	"""
	if not target:
		return

	# Animate the scale change
	_animate_shadowshift()

	# Apply scale to target
	target.scale = Vector2(scale_factor, scale_factor)

	# Update collision shape if it exists
	if target.has_node("CollisionShape2D"):
		var collision_shape = target.get_node("CollisionShape2D")
		# Update collision shape radius based on scale
		if collision_shape.shape is CircleShape2D:
			var original_radius = 6.0  # Default radius
			collision_shape.shape.radius = original_radius * scale_factor

	# For non-persistent scale, schedule revert after turn
	if not persistent:
		await get_tree().create_timer(1.0).timeout
		_revert_scale()

func _animate_shadowshift() -> void:
	"""
	Animate Shadowshift with pulsing effect.

	Creates a violet pulsing aura during scale change.
	"""
	var target_sprite: Sprite2D = null
	if target.has_node("Sprite2D"):
		target_sprite = target.get_node("Sprite2D")
	elif target is Sprite2D:
		target_sprite = target as Sprite2D

	if target_sprite:
		# Pulsing glow with scale
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(target_sprite, "modulate", Color(0.6, 0.2, 0.7, 1.0), 0.15)
		tween.tween_property(target, "scale", Vector2(scale_factor, scale_factor), 0.3)
		await tween.finished
		tween = create_tween()
		tween.tween_property(target_sprite, "modulate", Color.WHITE, 0.1)
		await tween.finished
	else:
		# No sprite, just scale
		var tween = create_tween()
		tween.tween_property(target, "scale", Vector2(scale_factor, scale_factor), 0.3)
		await tween.finished

func _revert_scale() -> void:
	"""Revert scale for non-persistent Shadowshift."""
	if target:
		target.scale = original_scale
		if target.has_node("CollisionShape2D"):
			var collision_shape = target.get_node("CollisionShape2D")
			if collision_shape.shape is CircleShape2D:
				var original_radius = 6.0
				collision_shape.shape.radius = original_radius

func _undo() -> void:
	"""Undo Shadowshift by restoring original scale."""
	if target:
		target.scale = original_scale
		if target.has_node("CollisionShape2D"):
			var collision_shape = target.get_node("CollisionShape2D")
			if collision_shape.shape is CircleShape2D:
				var original_radius = 6.0
				collision_shape.shape.radius = original_radius

func _preview() -> void:
	"""
	Show preview for Shadowshift.

	Displays:
	- Ghost at new size
	- Center point indicator
	- Dilation lines
	"""
	if not target or not PreviewSystem:
		return

	# Get target position
	var target_pos: Vector2
	if target.has_meta("current_position"):
		target_pos = gs.tile_to_world(target.current_position)
	else:
		target_pos = target.global_position

	# Use target position as center if not specified
	center_point = target_pos

	# Show shadowshift preview using PreviewSystem
	PreviewSystem.show_shadowshift_preview(center_point, scale_factor, target)

func _clear_preview() -> void:
	"""Clear Shadowshift preview."""
	if PreviewSystem:
		PreviewSystem.clear_all_previews()

func _is_scaled_position_valid(new_scale: float) -> bool:
	"""
	Check if scaled size fits within arena bounds.

	Args:
		new_scale: Scale factor to check

	Returns:
		true if scaled object fits, false otherwise
	"""
	# Get target bounds
	if not target:
		return true

	# Get sprite size if available
	var sprite_size = Vector2(16, 16)  # Default size
	if target.has_node("Sprite2D"):
		var sprite = target.get_node("Sprite2D")
		if sprite.texture:
			sprite_size = sprite.texture.get_size()
	elif target is Sprite2D and (target as Sprite2D).texture:
		sprite_size = (target as Sprite2D).texture.get_size()

	# Check if scaled size fits (simplified - just ensure it's reasonable)
	var scaled_size = sprite_size * new_scale
	if scaled_size.x > 512 or scaled_size.y > 512:
		return false

	return true

# === UTILITY ===
func get_scale_info() -> Dictionary:
	"""
	Get information about the scale.

	Returns:
		Dictionary with scale details
	"""
	var scale_range = gc.get_shadowshift_range(player_level, target_type)
	return {
		"scale_factor": scale_factor,
		"original_scale": original_scale,
		"min_scale": scale_range.x,
		"max_scale": scale_range.y,
		"persistent": persistent,
		"center_point": center_point
	}
