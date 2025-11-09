# res://scripts/systems/telegraph_system.gd
extends Node

# === TELEGRAPH MODE ENUM ===
enum TelegraphMode {
	SEQUENTIAL,      # Show one enemy at a time
	SIMULTANEOUS     # Show all enemies at once
}

# === STATE ===
var current_mode: TelegraphMode = TelegraphMode.SEQUENTIAL
var active_indicators: Array[Node2D] = []
var telegraph_data: Dictionary = {}  # Cache of telegraph info {enemy: {action_type, target_pos, ...}}

# === TIMING ===
var sequential_animation_time: float = 0.75  # Per enemy
var indicator_fade_time: float = 1.5  # How long indicators stay visible

# === SIGNALS ===
signal telegraph_started()
signal telegraph_complete()
signal indicator_created(indicator: Node2D, enemy: Node2D)

func _ready() -> void:
	"""Initialize Telegraph System."""
	add_to_group("telegraph_system")
	print("Telegraph System initialized")

# === MODE MANAGEMENT ===
func set_telegraph_mode(mode: TelegraphMode) -> void:
	"""
	Set telegraph display mode.

	Args:
		mode: SEQUENTIAL or SIMULTANEOUS
	"""
	current_mode = mode
	print("Telegraph mode set to: %s" % TelegraphMode.keys()[mode])

func get_telegraph_mode_from_difficulty() -> TelegraphMode:
	"""
	Get telegraph mode based on current difficulty.

	Returns:
		TelegraphMode for current difficulty
	"""
	# Hard mode uses simultaneous (faster), others use sequential
	if DifficultySystem:
		var difficulty = DifficultySystem.difficulty_name
		if difficulty == "hard":
			return TelegraphMode.SIMULTANEOUS
	return TelegraphMode.SEQUENTIAL

# === MAIN TELEGRAPH FUNCTIONS ===
func show_sequential_telegraphs(enemies: Array[Node]) -> void:
	"""
	Show enemy telegraphs one at a time.

	Args:
		enemies: Array of enemy nodes to telegraph
	"""
	print("Telegraph System: Sequential mode starting (%d enemies)" % enemies.size())
	telegraph_started.emit()

	for enemy in enemies:
		# Get enemy's cached action
		if enemy not in telegraph_data:
			print("WARNING: No telegraph data for enemy %s" % enemy.name)
			continue

		var action_info = telegraph_data[enemy]

		# Create telegraph indicator
		var indicator = create_telegraph_indicator(enemy, action_info.action_type, action_info.get("target_pos", enemy.global_position))

		if indicator:
			active_indicators.append(indicator)
			indicator_created.emit(indicator, enemy)

			# Play animation
			await get_tree().create_timer(sequential_animation_time).timeout

			# Fade out in Easy mode, keep visible in others
			if DifficultySystem and DifficultySystem.difficulty_name == "easy":
				pass  # Keep visible
			else:
				# Fade out
				var tween = create_tween()
				tween.tween_property(indicator, "modulate:a", 0.0, 0.5)
				await tween.finished

	telegraph_complete.emit()

func show_simultaneous_telegraphs(enemies: Array[Node2D]) -> void:
	"""
	Show all enemy telegraphs at once.

	Args:
		enemies: Array of enemy nodes to telegraph
	"""
	print("Telegraph System: Simultaneous mode starting (%d enemies)" % enemies.size())
	telegraph_started.emit()

	var tweens: Array[Tween] = []

	# Create all indicators in parallel
	for enemy in enemies:
		if enemy not in telegraph_data:
			print("WARNING: No telegraph data for enemy %s" % enemy.name)
			continue

		var action_info = telegraph_data[enemy]
		var indicator = create_telegraph_indicator(enemy, action_info.action_type, action_info.get("target_pos", enemy.global_position))

		if indicator:
			active_indicators.append(indicator)
			indicator_created.emit(indicator, enemy)

			# Start fade animation
			var tween = create_tween()
			tweens.append(tween)
			tween.tween_property(indicator, "modulate:a", 1.0, 0.3)
			tween.tween_callback(func(): await get_tree().create_timer(indicator_fade_time).timeout)
			tween.tween_property(indicator, "modulate:a", 0.0, 0.5)

	# Wait for all tweens to finish
	for tween in tweens:
		await tween.finished

	telegraph_complete.emit()

# === INDICATOR CREATION ===
func create_telegraph_indicator(enemy: Node2D, action_type: String, target_pos: Vector2) -> Node2D:
	"""
	Create visual telegraph indicator for an enemy action.

	Args:
		enemy: Enemy performing the action
		action_type: Type of action (move, attack, etc.)
		target_pos: Target position for the action

	Returns:
		Indicator node or null
	"""
	var indicator = Node2D.new()
	indicator.name = "%s_Telegraph_%s" % [enemy.name, action_type]
	indicator.global_position = enemy.global_position

	# Determine enemy type and create appropriate visual
	var enemy_type = enemy.enemy_type if enemy.has_meta("enemy_type") else "unknown"

	match enemy_type:
		"hound":
			_create_hound_indicator(indicator, target_pos)
		"mirror_wraith":
			_create_wraith_indicator(indicator)
		"hollow_sentinel":
			_create_sentinel_indicator(indicator, target_pos)
		"architect":
			_create_architect_indicator(indicator, action_type)
		_:
			_create_default_indicator(indicator, action_type)

	# Add to scene
	get_tree().get_root().add_child(indicator)
	return indicator

func _create_hound_indicator(indicator: Node2D, target_pos: Vector2) -> void:
	"""Create Hound telegraph (dotted line path)."""
	var line = Line2D.new()
	line.add_point(indicator.global_position)
	line.add_point(target_pos)
	line.default_color = Color(1.0, 0.765, 0.066, 0.8)  # Yellow #FFC107
	line.width = 2.0

	indicator.add_child(line)

func _create_wraith_indicator(indicator: Node2D) -> void:
	"""Create Mirror Wraith telegraph (cyan glow + COPY READY text)."""
	# Cyan glow circle
	var circle = CircleShape2D.new()
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	collision.shape = circle
	collision.shape.radius = 30.0
	area.add_child(collision)
	area.modulate = Color(0.0, 0.749, 0.831, 0.4)  # Cyan #00BCD4
	indicator.add_child(area)

	# Text label
	var label = Label.new()
	label.text = "COPY READY"
	label.modulate = Color(0.0, 0.749, 0.831, 0.8)
	indicator.add_child(label)

func _create_sentinel_indicator(indicator: Node2D, target_pos: Vector2) -> void:
	"""Create Hollow Sentinel telegraph (light beam preview)."""
	var line = Line2D.new()
	line.add_point(indicator.global_position)
	line.add_point(target_pos)
	line.default_color = Color(0.957, 0.263, 0.212, 0.7)  # Red #F44336
	line.width = 3.0

	indicator.add_child(line)

func _create_architect_indicator(indicator: Node2D, action_type: String) -> void:
	"""Create Architect telegraph (multi-part attack indicator)."""
	# Purple glow for multi-target threat
	var circle = CircleShape2D.new()
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	collision.shape = circle
	collision.shape.radius = 40.0
	area.add_child(collision)
	area.modulate = Color(0.6, 0.2, 0.7, 0.3)  # Purple/Violet
	indicator.add_child(area)

	# Exclamation mark for danger
	var label = Label.new()
	label.text = "!"
	label.add_theme_font_size_override("font_size", 32)
	label.modulate = Color(0.6, 0.2, 0.7, 1.0)
	indicator.add_child(label)

func _create_default_indicator(indicator: Node2D, action_type: String) -> void:
	"""Create default telegraph indicator."""
	var label = Label.new()
	label.text = action_type.to_upper()
	label.modulate = Color.WHITE
	indicator.add_child(label)

# === TELEGRAPH DATA CACHING ===
func cache_telegraph_data(enemy: Node2D, action_type: String, target_pos: Vector2 = Vector2.ZERO, extra_data: Dictionary = {}) -> void:
	"""
	Cache telegraph data for an enemy.

	Args:
		enemy: Enemy node
		action_type: Type of action
		target_pos: Target position
		extra_data: Additional data to cache
	"""
	var data = {
		"action_type": action_type,
		"target_pos": target_pos
	}
	data.merge(extra_data)

	telegraph_data[enemy] = data
	print("Telegraph data cached for %s: %s" % [enemy.name, action_type])

func get_cached_telegraph(enemy: Node2D) -> Dictionary:
	"""
	Get cached telegraph data for an enemy.

	Args:
		enemy: Enemy node

	Returns:
		Cached telegraph data or empty dict
	"""
	return telegraph_data.get(enemy, {})

func clear_telegraph_data() -> void:
	"""Clear all cached telegraph data."""
	telegraph_data.clear()
	print("Telegraph data cleared")

# === INDICATOR MANAGEMENT ===
func clear_telegraphs() -> void:
	"""Remove all telegraph indicators from scene."""
	for indicator in active_indicators:
		if is_instance_valid(indicator):
			indicator.queue_free()
	active_indicators.clear()
	print("All telegraph indicators cleared")

func clear_telegraph_data_and_indicators() -> void:
	"""Clear both telegraph data and visual indicators."""
	clear_telegraphs()
	clear_telegraph_data()

# === DIFFICULTY-SPECIFIC FEATURES ===
func apply_difficulty_settings() -> void:
	"""Apply difficulty-specific telegraph settings."""
	if DifficultySystem:
		var difficulty = DifficultySystem.difficulty_name

		match difficulty:
			"easy":
				sequential_animation_time = 1.0
				indicator_fade_time = 2.0
				# Ghost previews handled separately

			"normal":
				sequential_animation_time = 0.75
				indicator_fade_time = 1.5

			"hard":
				sequential_animation_time = 0.5
				indicator_fade_time = 0.8
				set_telegraph_mode(TelegraphMode.SIMULTANEOUS)

		print("Telegraph settings applied for difficulty: %s" % difficulty)

# === UTILITY ===
func get_telegraph_info() -> Dictionary:
	"""
	Get telegraph system information.

	Returns:
		Dictionary with telegraph info
	"""
	return {
		"mode": TelegraphMode.keys()[current_mode],
		"active_indicators": active_indicators.size(),
		"cached_enemies": telegraph_data.size(),
		"sequential_animation_time": sequential_animation_time,
		"indicator_fade_time": indicator_fade_time
	}
