# res://scripts/enemies/mirror_wraith.gd
extends Enemy
class_name MirrorWraith

# === MIRROR WRAITH AI PARAMETERS ===
@export var copy_delay: float = 1.0  # Delay before copying transformation
@export var copy_range: float = 200.0  # Maximum range to copy from
@export var reflection_damage: int = 1

var pending_transformation: Dictionary = {}
var last_copied_type: String = ""
var is_copying: bool = false

func _ready() -> void:
	enemy_type = "mirror_wraith"
	health = 2
	max_health = 2
	patrol_speed = 0.0  # Stationary unless copying
	super._ready()

# === AI LOGIC ===
func calculate_next_action() -> Dictionary:
	"""Mirror Wraith AI: Prepare to copy or reflect player.

	Returns:
		Dictionary with action_type, target_pos, and extra_data
	"""
	change_state(State.TELEGRAPHING)

	var player = get_tree().get_first_child_in_group("player")
	if not player or get_distance_to_player() > copy_range:
		return idle_action()

	# Prepare to copy: show readiness state
	is_copying = true
	var action = {
		"action_type": "copy",
		"target_pos": global_position,
		"extra_data": {
			"copy_delay": copy_delay,
			"target_player": player
		}
	}
	action_planned.emit(action)
	telegraph_data = action
	return action

func idle_action() -> Dictionary:
	"""Return an idle action (Mirror Wraith default)."""
	is_copying = false
	var action = {
		"action_type": "idle",
		"target_pos": global_position,
		"extra_data": {}
	}
	action_planned.emit(action)
	telegraph_data = action
	return action

func execute_action(action: Dictionary) -> void:
	"""Execute the Mirror Wraith's action.

	Args:
		action: Dictionary with action_type and parameters
	"""
	change_state(State.EXECUTING)

	var action_type = action.get("action_type", "idle")

	match action_type:
		"copy":
			await _execute_copy(action)
		"idle":
			await get_tree().create_timer(0.3).timeout

	change_state(State.WAITING)

func _execute_copy(action: Dictionary) -> void:
	"""Execute copying of player's last transformation.

	Args:
		action: Dictionary with copy parameters
	"""
	var player = action.get("target_player")
	if not player:
		return

	var delay = action.get("copy_delay", copy_delay)

	# Show copying indicator
	_show_copy_indicator()
	print("%s prepares to reflect..." % name)

	# Wait for copy delay
	await get_tree().create_timer(delay).timeout

	# Get player's last transformation info if available
	if player.has_meta("last_transformation"):
		var last_trans = player.get_meta("last_transformation")
		print("%s copies: %s" % [name, last_trans])

		# Execute the copy (visual only, actual mechanics handled by telegraph)
		await _perform_copy_animation(player)

func _perform_copy_animation(player: Node2D) -> void:
	"""Play visual feedback for copying transformation.

	Args:
		player: Player node being copied
	"""
	# Cyan glow effect
	var tween = create_tween()
	modulate = Color.CYAN
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	tween.tween_property(self, "scale", Vector2.ONE * 1.2, 0.2)
	await tween.finished
	scale = Vector2.ONE

func _show_copy_indicator() -> void:
	"""Visual feedback that Wraith is about to copy."""
	# Pulse effect to show readiness
	var tween = create_tween()
	modulate = Color.CYAN
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	tween.tween_property(self, "modulate", Color.CYAN, 0.2)
	await tween.finished
	modulate = Color.WHITE

func copy_player_transformation(transformation_type: String, source_position: Vector2) -> void:
	"""Copy player's transformation after delay.

	Args:
		transformation_type: Type of transformation to copy
		source_position: Position of transformation source
	"""
	last_copied_type = transformation_type
	print("%s will copy %s" % [name, transformation_type])

	await get_tree().create_timer(copy_delay).timeout

	match transformation_type:
		"shadow_slide":
			await _copy_shadow_slide(source_position)
		"mirrorwalk":
			await _copy_mirrorwalk(source_position)
		"turn":
			await _copy_turn(source_position)
		"shadow_pivot":
			await _copy_shadow_pivot(source_position)
		"shadowshift":
			await _copy_shadowshift(source_position)

func _copy_shadow_slide(source_pos: Vector2) -> void:
	"""Copy shadow slide movement.

	Args:
		source_pos: Source position of the slide
	"""
	var player = get_tree().get_first_child_in_group("player")
	if not player:
		return

	var direction = (source_pos - global_position).normalized()
	var distance = GameManager.player_level * 16.0  # Tiles converted to pixels
	var target_pos = global_position + direction * distance

	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, 0.4)
	await tween.finished

func _copy_mirrorwalk(_source_pos: Vector2) -> void:
	"""Copy mirrorwalk reflection.

	Args:
		_source_pos: Source position (unused)
	"""
	print("%s reflects across mirror..." % name)
	# Wraith stays in place but shimmers to show reflection
	var tween = create_tween()
	modulate = Color.CYAN
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	await tween.finished

func _copy_turn(_source_pos: Vector2) -> void:
	"""Copy rotation.

	Args:
		_source_pos: Source position (unused)
	"""
	print("%s mirrors rotation..." % name)
	# Wraith rotates in place
	var tween = create_tween()
	tween.tween_property(self, "rotation", rotation + PI, 0.3)
	await tween.finished

func _copy_shadow_pivot(_source_pos: Vector2) -> void:
	"""Copy shadow pivot rotation around point.

	Args:
		_source_pos: Source position (unused)
	"""
	print("%s orbits around mirror axis..." % name)
	# Wraith orbits around itself
	var tween = create_tween()
	tween.tween_property(self, "rotation", rotation + PI / 2.0, 0.4)
	await tween.finished

func _copy_shadowshift(_source_pos: Vector2) -> void:
	"""Copy scale change.

	Args:
		_source_pos: Source position (unused)
	"""
	print("%s changes form..." % name)
	# Wraith scales up temporarily
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.3, 0.2)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	await tween.finished
