# res://scripts/enemies/hollow_sentinel.gd
extends Enemy
class_name HollowSentinel

# === HOLLOW SENTINEL AI PARAMETERS ===
@export var light_beam: Area2D  # Reference to light beam collision area
@export var light_beam_visual: Polygon2D  # Visual representation
@export var light_direction: Vector2 = Vector2.RIGHT
@export var light_range: float = 200.0
@export var light_cone_angle: float = 90.0  # degrees
@export var rotation_speed: float = 45.0  # degrees per turn
@export var beam_damage: int = 1
@export var shield_health: int = 1

var target_direction: Vector2 = Vector2.RIGHT
var is_shielded: bool = false

func _ready() -> void:
	enemy_type = "hollow_sentinel"
	health = 3
	max_health = 3
	patrol_speed = 0.0  # Completely stationary
	super._ready()
	update_light_beam()

func update_light_beam() -> void:
	"""Update light beam visual and collision based on direction."""
	if not light_beam or not light_beam_visual:
		return
	
	# Calculate cone vertices
	var half_angle := deg_to_rad(light_cone_angle / 2.0)
	var base_angle := light_direction.angle()
	
	var vertices: PackedVector2Array = [
		Vector2.ZERO,  # Origin at sentinel
		light_direction.rotated(-half_angle) * light_range,
		light_direction.rotated(half_angle) * light_range
	]
	
	light_beam_visual.polygon = vertices
	
	# Update collision shape
	var collision_shape := light_beam.get_node_or_null("CollisionPolygon2D")
	if collision_shape:
		collision_shape.polygon = vertices

func rotate_sentinel(angle_degrees: float) -> void:
	"""Rotate the sentinel, which rotates its light beam."""
	light_direction = light_direction.rotated(deg_to_rad(angle_degrees))
	update_light_beam()

func set_light_direction(new_direction: Vector2) -> void:
	"""Set absolute light direction."""
	light_direction = new_direction.normalized()
	update_light_beam()

func is_blocking_position(pos: Vector2) -> bool:
	"""Check if a position is within the light beam."""
	if not light_beam:
		return false
	
	var local_pos := to_local(pos)
	var angle_to_point := local_pos.angle()
	var beam_angle := light_direction.angle()
	var half_cone := deg_to_rad(light_cone_angle / 2.0)
	
	# Check if within cone angle
	var angle_diff := abs(angle_difference(angle_to_point, beam_angle))
	if angle_diff > half_cone:
		return false
	
	# Check if within range
	return local_pos.length() <= light_range

func angle_difference(a: float, b: float) -> float:
	"""Calculate shortest angular difference."""
	var diff := fmod(a - b, TAU)
	if diff > PI:
		diff -= TAU
	elif diff < -PI:
		diff += TAU
	return diff

# === AI LOGIC ===
func calculate_next_action() -> Dictionary:
	"""Hollow Sentinel AI: Aim beam toward player or rotate defensively.

	Returns:
		Dictionary with action_type, target_pos, and extra_data
	"""
	change_state(State.TELEGRAPHING)

	var player = get_tree().get_first_child_in_group("player")
	if not player:
		return idle_action()

	# Calculate direction to player
	var direction_to_player = (player.global_position - global_position).normalized()
	target_direction = direction_to_player

	var action = {
		"action_type": "aim",
		"target_pos": player.global_position,
		"extra_data": {
			"target_direction": target_direction,
			"rotation_speed": rotation_speed
		}
	}
	action_planned.emit(action)
	telegraph_data = action
	return action

func idle_action() -> Dictionary:
	"""Return an idle action (beam stays in place)."""
	var action = {
		"action_type": "idle",
		"target_pos": global_position,
		"extra_data": {}
	}
	action_planned.emit(action)
	telegraph_data = action
	return action

func execute_action(action: Dictionary) -> void:
	"""Execute the Hollow Sentinel's action.

	Args:
		action: Dictionary with action_type and parameters
	"""
	change_state(State.EXECUTING)

	var action_type = action.get("action_type", "idle")

	match action_type:
		"aim":
			await _execute_aim(action)
		"idle":
			await get_tree().create_timer(0.3).timeout

	change_state(State.WAITING)

func _execute_aim(action: Dictionary) -> void:
	"""Execute aiming the light beam toward target.

	Args:
		action: Dictionary with aim parameters
	"""
	var target_dir = action.get("target_direction", target_direction)
	var speed = action.get("rotation_speed", rotation_speed)

	print("%s aims light beam..." % name)

	# Animate light beam rotation
	var tween = create_tween()
	var angle_change = deg_to_rad(speed)
	var start_angle = light_direction.angle()
	var target_angle = target_dir.angle()

	# Normalize angle difference
	var diff = angle_difference(target_angle, start_angle)
	var duration = abs(diff) / deg_to_rad(speed)

	tween.tween_callback(func():
		var t = 0.0
		var anim_duration = duration if duration > 0.01 else 0.1
		var anim_tween = create_tween()
		anim_tween.set_trans(Tween.TRANS_LINEAR)
		anim_tween.set_ease(Tween.EASE_IN_OUT)

		for _step in range(int(anim_duration * 10)):
			t += 0.1 / anim_duration
			var current_angle = start_angle + diff * t
			light_direction = Vector2.RIGHT.rotated(current_angle)
			update_light_beam()
			await get_tree().create_timer(0.01).timeout
	)
	await tween.finished

	light_direction = target_dir
	update_light_beam()

func engage_shield() -> void:
	"""Activate shield to block one hit."""
	if not is_shielded:
		is_shielded = true
		print("%s shield engaged!" % name)
		# Visual feedback
		modulate = Color.YELLOW
		await get_tree().create_timer(0.2).timeout
		modulate = Color.WHITE

func take_damage(amount: int) -> void:
	"""Take damage, shield blocks first hit.

	Args:
		amount: Amount of damage to take
	"""
	if is_shielded:
		is_shielded = false
		print("%s shield was hit!" % name)
		modulate = Color.RED
		await get_tree().create_timer(0.2).timeout
		modulate = Color.WHITE
		return

	super.take_damage(amount)

func rotate_toward_player() -> void:
	"""Rotate beam toward player for aiming."""
	var player = get_tree().get_first_child_in_group("player")
	if player:
		target_direction = (player.global_position - global_position).normalized()
