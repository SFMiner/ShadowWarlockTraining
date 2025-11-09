# res://scripts/enemies/enemy_base.gd
extends CharacterBody2D
class_name Enemy

@export var enemy_type: String = "hound"
@export var patrol_speed: float = 32.0  # pixels per second
@export var patrol_waypoints: Array[Vector2] = []

var current_waypoint_index: int = 0
var is_active: bool = true

signal player_contact()

func _ready() -> void:
	add_to_group("enemies")
	# Unlock bestiary entry when first encountered
	GameManager.unlock_bestiary_entry(enemy_type)

func _physics_process(delta: float) -> void:
	if not is_active or patrol_waypoints.is_empty():
		return
	
	# Simple waypoint patrol
	var target := patrol_waypoints[current_waypoint_index]
	var direction := global_position.direction_to(target)
	velocity = direction * patrol_speed
	
	move_and_slide()
	
	# Check if reached waypoint
	if global_position.distance_to(target) < 5.0:
		current_waypoint_index = (current_waypoint_index + 1) % patrol_waypoints.size()

func _on_area_2d_body_entered(body: Node2D) -> void:
	"""Detect player contact."""
	if body is PlayerAvatar:
		player_contact.emit()

func pause_patrol() -> void:
	"""Temporarily stop patrol (for being affected by transformations)."""
	is_active = false

func resume_patrol() -> void:
	"""Resume patrol after transformation."""
	is_active = true
