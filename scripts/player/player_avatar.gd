# res://scripts/player/player_avatar.gd
extends CharacterBody2D
class_name PlayerAvatar

# === SCRIPT REFERENCES ===
var gc = load("res://scripts/autoload/game_constants.gd")

const TILE_SIZE: int = 16

@export var sprite: Sprite2D
@export var animation_player: AnimationPlayer

# === CORE PROPERTIES ===
var current_position: Vector2i = Vector2i.ZERO	# Tile coordinates
var current_direction: Vector2 = Vector2.RIGHT	# Facing direction
var is_transforming: bool = false				# Animation lock
var health: int = 1								# Always 1 (one-hit reset)
var transformation_history: Array = []	# For undo
var selected_ability: String = "shadow_slide"	# Currently selected transformation

# Transformation state
var selected_targets: Array[Node2D] = []
var transformation_preview: Node2D

# === SIGNALS ===
signal transformation_started(type: String)
signal transformation_complete(type: String)
signal transformation_cancelled()
signal player_hit()
signal transformation_failed(reason: String)

func _ready() -> void:
	"""Initialize player avatar."""
	# Initialize tile position from current global position
	current_position = gc.pixel_to_tile(global_position)

	# Snap player to tile center
	global_position = gc.tile_to_pixel(current_position)

	add_to_group("player")
	update_sprite_direction()

	print("PlayerAvatar initialized at tile position: %s" % str(current_position))

	# Connect to TurnManager signals for phase tracking
	if TurnManager:
		TurnManager.phase_changed.connect(_on_turn_phase_changed)
		TurnManager.turn_started.connect(_on_turn_started)
		print("PlayerAvatar: Connected to TurnManager signals")
	else:
		print("WARNING: TurnManager not available!")

# === SHADOW SLIDE (Translation) ===
func shadow_slide(target_position: Vector2, target: Node2D = self) -> bool:
	"""
	Shadow Slide: Translation transformation.
	CRITICAL: Cannot pass barriers, CAN pass ground hazards.
	"""
	var start_pos: Vector2 = target.global_position if target != self else global_position
	var distance := start_pos.distance_to(target_position)
	
	# Determine effective level based on target type
	var target_type: GameConstants.TargetType
	if target == self:
		target_type = GameConstants.TargetType.SELF
	elif target is Enemy:
		target_type = GameConstants.TargetType.ENEMY
	else:
		target_type = GameConstants.TargetType.OBJECT
	
	var effective_level = gc.get_effective_level_for_target(GameManager.player_level, target_type)
	var max_range = effective_level * TILE_SIZE
	
	# Check range
	if distance > max_range:
		transformation_failed.emit("Out of range")
		return false
	
	# CRITICAL: Check for barriers (Shadow Slide is blocked by barriers)
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(start_pos, target_position)
	query.collision_mask = 1  # Barrier layer (bit 0)
	query.exclude = [target]  # Don't collide with the moving target itself
	var result := space_state.intersect_ray(query)
	
	if result:
		transformation_failed.emit("Barrier blocks Shadow Slide")
		return false
	
	# Valid slide - execute
	is_transforming = true
	await perform_slide_animation(target, target_position)
	target.global_position = target_position
	is_transforming = false
	transformation_complete.emit("shadow_slide")
	return true

func perform_slide_animation(target: Node2D, target_pos: Vector2) -> void:
	"""Dissolve and reappear animation for Shadow Slide."""
	var target_sprite: Sprite2D = target.get_node_or_null("Sprite2D")
	if not target_sprite:
		target_sprite = target as Sprite2D
	
	if target_sprite:
		# Dissolve effect
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(target_sprite, "modulate:a", 0.0, 0.2)
		tween.tween_property(target_sprite, "scale", Vector2(0.5, 0.5), 0.2)
		await tween.finished
		
		# Reappear at target
		target.global_position = target_pos
		tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(target_sprite, "modulate:a", 1.0, 0.2)
		tween.tween_property(target_sprite, "scale", Vector2.ONE, 0.2)
		await tween.finished
	else:
		# No sprite, just move instantly
		await get_tree().create_timer(0.3).timeout
		target.global_position = target_pos

# === MIRRORWALK (Reflection) ===
func mirrorwalk(mirror_start: Vector2, mirror_end: Vector2, target: Node2D = self) -> bool:
	"""
	Mirrorwalk: Reflection transformation.
	UNIQUE: CAN pass through barriers (unlike Shadow Slide).
	"""
	var start_pos: Vector2 = target.global_position if target != self else global_position
	
	# Calculate mirror axis placement distance
	var closest_point := Geometry2D.get_closest_point_to_segment(start_pos, mirror_start, mirror_end)
	var distance_to_mirror := start_pos.distance_to(closest_point)
	
	# Determine effective level
	var target_type: GameConstants.TargetType
	if target == self:
		target_type = GameConstants.TargetType.SELF
	elif target is Enemy:
		target_type = GameConstants.TargetType.ENEMY
	else:
		target_type = GameConstants.TargetType.OBJECT
	
	var effective_level = gc.get_effective_level_for_target(GameManager.player_level, target_type)
	var max_range = effective_level * TILE_SIZE
	
	if distance_to_mirror > max_range:
		transformation_failed.emit("Mirror wall out of range")
		return false
	
	# Calculate reflection
	var reflected_pos := calculate_reflection(start_pos, mirror_start, mirror_end)
	
	# Calculate reflected direction if target is player
	if target == self:
		var reflected_dir := calculate_direction_reflection(current_direction, mirror_start, mirror_end)
		
		# Execute mirrorwalk (NO barrier check - passes through)
		is_transforming = true
		await perform_mirrorwalk_animation(mirror_start, mirror_end, reflected_pos)
		global_position = reflected_pos
		current_direction = reflected_dir
		update_sprite_direction()
		is_transforming = false
	else:
		# Non-player target
		is_transforming = true
		await perform_mirrorwalk_animation(mirror_start, mirror_end, reflected_pos)
		target.global_position = reflected_pos
		is_transforming = false
	
	transformation_complete.emit("mirrorwalk")
	return true

func calculate_reflection(point: Vector2, line_start: Vector2, line_end: Vector2) -> Vector2:
	"""Calculate reflected position across a line."""
	var line_vec := (line_end - line_start).normalized()
	var point_vec := point - line_start
	var projection := line_vec * point_vec.dot(line_vec)
	var closest := line_start + projection
	var reflection := closest + (closest - point)
	return reflection

func calculate_direction_reflection(direction: Vector2, line_start: Vector2, line_end: Vector2) -> Vector2:
	"""Calculate reflected direction vector across a line."""
	var line_vec := (line_end - line_start).normalized()
	var reflected := direction - 2 * direction.dot(line_vec) * line_vec
	return reflected.normalized()

func perform_mirrorwalk_animation(_mirror_start: Vector2, _mirror_end: Vector2, _target_pos: Vector2) -> void:
	"""Ripple effect animation for Mirrorwalk."""
	# TODO: Add mirror wall visual effect
	# TODO: Add ripple distortion shader
	await get_tree().create_timer(0.5).timeout

# === TURN (Rotation in place) ===
func turn(angle_degrees: float) -> void:
	"""
	Turn: Rotate around self.
	Position unchanged, orientation changes.
	"""
	var angle_rad := deg_to_rad(angle_degrees)
	current_direction = current_direction.rotated(angle_rad)
	
	# Snap to 8 directions if enabled
	if GameManager.angle_snap:
		var angle := current_direction.angle()
		angle = round(angle / (PI / 4)) * (PI / 4)
		current_direction = Vector2.RIGHT.rotated(angle)
	
	update_sprite_direction()
	transformation_complete.emit("turn")

# === SHADOW PIVOT (Rotation around external point) ===
func shadow_pivot(anchor_point: Vector2, angle_degrees: float, target: Node2D = self) -> bool:
	"""
	Shadow Pivot: Rotate around external anchor point.
	Both position and orientation change.
	"""
	if not GameManager.abilities["shadow_pivot"]:
		transformation_failed.emit("Shadow Pivot not unlocked")
		return false
	
	var start_pos: Vector2 = target.global_position if target != self else global_position
	var distance := start_pos.distance_to(anchor_point)
	
	# Determine effective level
	var target_type: GameConstants.TargetType
	if target == self:
		target_type = GameConstants.TargetType.SELF
	elif target is Enemy:
		target_type = GameConstants.TargetType.ENEMY
	else:
		target_type = GameConstants.TargetType.OBJECT
	
	var effective_level = gc.get_effective_level_for_target(GameManager.player_level, target_type)
	var max_range = effective_level * TILE_SIZE
	
	if distance > max_range:
		transformation_failed.emit("Anchor out of range")
		return false
	
	# Calculate rotation around anchor
	var offset := start_pos - anchor_point
	var angle_rad := deg_to_rad(angle_degrees)
	var rotated_offset := offset.rotated(angle_rad)
	var new_position := anchor_point + rotated_offset
	
	# Update direction if player
	if target == self:
		current_direction = current_direction.rotated(angle_rad)
		
		# Execute pivot
		is_transforming = true
		await perform_pivot_animation(anchor_point, new_position, angle_degrees)
		global_position = new_position
		update_sprite_direction()
		is_transforming = false
	else:
		# Non-player target
		is_transforming = true
		await perform_pivot_animation(anchor_point, new_position, angle_degrees)
		target.global_position = new_position
		is_transforming = false
	
	transformation_complete.emit("shadow_pivot")
	return true

func perform_pivot_animation(_anchor: Vector2, _target_pos: Vector2, _angle: float) -> void:
	"""Arc motion animation for Shadow Pivot."""
	# TODO: Add tether line visual
	# TODO: Add arc motion trail
	await get_tree().create_timer(0.6).timeout

# === SHADOWSHIFT (Dilation) ===
func shadowshift(new_scale: float, target: Node2D = self) -> bool:
	"""
	Shadowshift: Change size while keeping center position fixed.
	Progression: Self (Lvl 2) -> Objects (Lvl 4) -> Enemies (Lvl 8)
	"""
	# Check if target type is unlocked
	var target_type: GameConstants.TargetType
	if target == self:
		if not GameManager.abilities["shadowshift_self"]:
			transformation_failed.emit("Self Shadowshift not unlocked")
			return false
		target_type = GameConstants.TargetType.SELF
	elif target is Enemy:
		if not GameManager.abilities["shadowshift_enemy"]:
			transformation_failed.emit("Enemy Shadowshift not unlocked")
			return false
		target_type = GameConstants.TargetType.ENEMY
	else:
		if not GameManager.abilities["shadowshift_object"]:
			transformation_failed.emit("Object Shadowshift not unlocked")
			return false
		target_type = GameConstants.TargetType.OBJECT
	
	# Get valid scale range
	var scale_range = gc.get_shadowshift_range(GameManager.player_level, target_type)
	if new_scale < scale_range.x or new_scale > scale_range.y:
		transformation_failed.emit("Scale out of range")
		return false
	
	# Execute scale
	is_transforming = true
	await perform_shadowshift_animation(target, new_scale)
	target.scale = Vector2(new_scale, new_scale)
	is_transforming = false
	transformation_complete.emit("shadowshift")
	return true

func perform_shadowshift_animation(target: Node2D, new_scale: float) -> void:
	"""Pulse animation for size change."""
	var tween := create_tween()
	tween.tween_property(target, "scale", Vector2(new_scale, new_scale), 0.4)
	await tween.finished

# === SPRITE DIRECTION UPDATE ===
func update_sprite_direction() -> void:
	"""Update sprite frame based on 8-directional movement."""
	if not sprite:
		return

	var angle := current_direction.angle()
	var direction_index := int(round(angle / (PI / 4))) % 8

	# Sprite frames: 0=E, 1=SE, 2=S, 3=SW, 4=W, 5=NW, 6=N, 7=NE
	sprite.frame = direction_index

# === TILE POSITION HELPERS ===
func move_to_tile(tile_pos: Vector2i) -> void:
	"""Move player to tile position and update both tile and world coordinates.

	Args:
		tile_pos: Target position in tile coordinates
	"""
	current_position = tile_pos
	global_position = gc.tile_to_pixel(tile_pos)

func get_tile_position() -> Vector2i:
	"""Get player current tile position.

	Returns:
		Current position in tile coordinates
	"""
	return current_position

# === INPUT HANDLING ===
func _input(event: InputEvent) -> void:
	"""Handle keyboard shortcuts for ability selection.

	Args:
		event: Input event
	"""
	# Only accept input during player action phase
	if TurnManager.current_phase != TurnManager.Phase.PLAYER_ACTION:
		return

	# Listen for key presses
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				selected_ability = "shadow_slide"
				print("Selected: Shadow Slide")
			KEY_2:
				selected_ability = "mirrorwalk"
				print("Selected: Mirrorwalk")
			KEY_3:
				selected_ability = "pivot"
				print("Selected: Pivot")
			KEY_4:
				selected_ability = "shadowshift"
				print("Selected: Shadowshift")

func _unhandled_input(event: InputEvent) -> void:
	"""Handle mouse clicks for targeting.

	Args:
		event: Input event
	"""
	# Only accept input during player action phase
	if TurnManager.current_phase != TurnManager.Phase.PLAYER_ACTION:
		return

	# Listen for left mouse button clicks
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world_pos = get_global_mouse_position()
		var target_tile = gc.pixel_to_tile(world_pos)
		_start_transformation_targeting(target_tile)

func _start_transformation_targeting(target_tile: Vector2i) -> void:
	"""Handle targeting and validation for transformations.

	Args:
		target_tile: Target tile position in grid coordinates
	"""
	print("Clicked tile: %s" % str(target_tile))
	print("Player tile: %s" % str(current_position))
	print("Selected ability: %s" % selected_ability)

	# Ignore if clicking on current tile
	if target_tile == current_position:
		print("Cannot target current tile")
		return

	# Calculate delta
	var delta = target_tile - current_position
	var delta_x = abs(delta.x)
	var delta_y = abs(delta.y)

	# For orthogonal-only abilities (Shadow Slide), use the primary axis
	# (whichever direction has more distance)
	var direction: Vector2
	var distance: int

	if selected_ability == "shadow_slide":
		# Shadow Slide: choose the primary axis
		if delta_x > delta_y:
			# Horizontal movement (strictly more right than down)
			direction = Vector2.RIGHT if delta.x > 0 else Vector2.LEFT
			distance = delta_x
		else:
			# Vertical movement (equal or more down than right)
			direction = Vector2.DOWN if delta.y > 0 else Vector2.UP
			distance = delta_y

		# Cap distance by player's transformation range
		var max_range = GameConstants.get_transformation_range(GameManager.player_level, "shadow_slide")
		distance = min(distance, max_range)

		print("Shadow Slide: direction=%s, distance=%d tiles (max range: %d)" % [direction, distance, max_range])
		_execute_shadow_slide(direction, distance)

	else:
		# Other abilities use the full direction vector (8-directional)
		var direction_vector = Vector2(delta)
		distance = int(direction_vector.length())
		direction = direction_vector.normalized()

		match selected_ability:
			"mirrorwalk":
				print("Mirrorwalk: not yet implemented")
			"pivot":
				print("Pivot: not yet implemented")
			"shadowshift":
				print("Shadowshift: not yet implemented")
			_:
				print("Unknown ability: %s" % selected_ability)

func _execute_shadow_slide(direction: Vector2, distance: int) -> void:
	"""Execute Shadow Slide transformation.

	Args:
		direction: Normalized direction vector
		distance: Distance in tiles
	"""
	# Calculate target world position
	var target_world_pos = global_position + (direction * distance * TILE_SIZE)

	# Emit transformation started signal
	transformation_started.emit("shadow_slide")

	# Show preview if available
	if PreviewSystem:
		PreviewSystem.create_ghost(self)

	# Execute the transformation using the existing shadow_slide method
	var success = await shadow_slide(target_world_pos, self)

	if success:
		# Update tile position from new world position
		current_position = gc.pixel_to_tile(global_position)

		# Add to transformation history
		transformation_history.append({
			"type": "shadow_slide",
			"direction": direction,
			"distance": distance,
			"new_position": current_position
		})

		# Emit transformation complete signal
		transformation_complete.emit("shadow_slide")

		print("Shadow Slide executed: moved %d tiles in direction %s" % [distance, direction])

		# End player action and advance turn
		if TurnManager:
			TurnManager.end_player_action()
	else:
		print("Shadow Slide failed")
		transformation_cancelled.emit()

# === DEBUG HELPERS ===
func _process(_delta: float) -> void:
	"""Debug helper for testing.

	Press SPACE to force PLAYER_ACTION phase for testing purposes.
	REMOVE THIS BEFORE RELEASE!
	"""
	if Input.is_action_just_pressed("ui_accept"):
		if TurnManager:
			print("DEBUG: Forcing PLAYER_ACTION phase")
			TurnManager.current_phase = TurnManager.Phase.PLAYER_ACTION

# === SIGNAL CALLBACKS ===
func _on_turn_phase_changed(new_phase: int, phase_name: String) -> void:
	"""Called when turn phase changes.

	Args:
		new_phase: New phase enum value
		phase_name: Human-readable phase name
	"""
	print(">>> TURN PHASE CHANGED: %s" % phase_name)

func _on_turn_started(turn_number: int) -> void:
	"""Called when a new turn starts.

	Args:
		turn_number: Turn number
	"""
	print(">>> TURN STARTED: Turn %d" % turn_number)
