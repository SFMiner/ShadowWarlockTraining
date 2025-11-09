# res://scripts/enemies/hollow_sentinel.gd
extends Enemy
class_name HollowSentinel

@export var light_beam: Area2D  # Reference to light beam collision area
@export var light_beam_visual: Polygon2D  # Visual representation
@export var light_direction: Vector2 = Vector2.RIGHT
@export var light_range: float = 200.0
@export var light_cone_angle: float = 90.0  # degrees

func _ready() -> void:
	enemy_type = "hollow_sentinel"
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
