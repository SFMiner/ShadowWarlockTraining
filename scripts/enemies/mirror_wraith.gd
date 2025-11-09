# res://scripts/enemies/mirror_wraith.gd
extends Enemy
class_name MirrorWraith

@export var copy_delay: float = 1.0

var pending_transformation: Dictionary = {}
var last_copied_type: String = ""

func _ready() -> void:
	enemy_type = "mirror_wraith"
	patrol_speed = 0.0  # Stationary unless copying
	super._ready()
	
	# Connect to player transformation signals
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.transformation_complete.connect(_on_player_transformation)

func _on_player_transformation(type: String) -> void:
	"""Copy player's transformation after delay."""
	last_copied_type = type
	
	# Show countdown indicator
	await get_tree().create_timer(copy_delay).timeout
	
	var player := get_tree().get_first_node_in_group("player") as PlayerAvatar
	if not player:
		return
	
	match type:
		"shadow_slide":
			# Copy slide direction and distance (at reduced power)
			var direction := player.current_direction
			var distance := GameConstants.get_effective_level_for_target(
				GameManager.player_level,
				GameConstants.TargetType.ENEMY
			) * GameConstants.TILE_SIZE
			var target_pos := global_position + direction * distance
			
			# Execute slide (no barrier check for wraith)
			global_position = target_pos
		
		"mirrorwalk":
			# Wraith reflects across same axis but from its own position
			# This would require storing the mirror wall used
			pass
		
		"turn":
			# Copy rotation (wraiths just rotate in place)
			# Would need to track rotation amount
			pass
		
		"shadow_pivot":
			# Wraith copies pivot motion from its position
			# Would need anchor point reference
			pass
		
		"shadowshift":
			# Copy scale change
			# Would need scale value
			pass

func show_copy_indicator() -> void:
	"""Visual feedback that Wraith is about to copy."""
	# TODO: Add glowing cyan indicator with countdown
	pass
