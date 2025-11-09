# res://scripts/levels/level_base.gd
extends Node2D
class_name LevelBase

# === LEVEL CONFIGURATION ===
@export var level_number: int = 1
@export var auto_start: bool = true

# === LEVEL DATA ===
var level_data: LevelDataLoader.LevelData = null
var grid_size: Vector2i = Vector2i(40, 25)

# === REFERENCES ===
var tilemap: TileMap
var entities_container: Node2D
var markers_container: Node2D

# === GAME STATE ===
var player: Node2D = null
var enemies: Array[Node2D] = []
var hazards: Array[Node2D] = []
var current_objective: String = ""
var level_complete: bool = false

# === SIGNALS ===
signal level_initialized()
signal level_victory()
signal level_defeat()

func _ready() -> void:
	"""Initialize level on load."""
	print("=== LEVEL %d INITIALIZING ===" % level_number)

	# Try to get node references (optional)
	tilemap = get_node_or_null("TileMap")
	entities_container = get_node_or_null("Entities")
	markers_container = get_node_or_null("Markers")

	# If containers don't exist, create them
	if not entities_container:
		entities_container = Node2D.new()
		entities_container.name = "Entities"
		add_child(entities_container)

	if not markers_container:
		markers_container = Node2D.new()
		markers_container.name = "Markers"
		add_child(markers_container)

	# Load level data
	var result = LevelDataLoader.load_level(level_number)
	if not result.valid:
		push_error("Failed to load level %d: %s" % [level_number, result.reason])
		return

	level_data = LevelDataLoader.get_current_level()
	print(LevelDataLoader.get_level_info())

	# Initialize the level
	initialize_level(level_number)

	# Connect to turn manager
	if TurnManager:
		TurnManager.level_won.connect(_on_level_won)
		TurnManager.level_lost.connect(_on_level_lost)

	level_initialized.emit()

	# Auto-start level if enabled
	if auto_start:
		await get_tree().create_timer(1.0).timeout
		_start_level()

func initialize_level(level_num: int) -> void:
	"""
	Initialize a level by loading data and setting up entities.

	Args:
		level_num: The level number to load
	"""
	if not level_data:
		return

	level_number = level_num

	# Extract grid size
	grid_size = Vector2i(level_data.arena_width, level_data.arena_height)

	# Setup arena (TileMap)
	_setup_tilemap()

	# Spawn player
	spawn_player()

	# Spawn enemies
	spawn_enemies()

	# Spawn hazards
	spawn_hazards()

	# Spawn barriers
	spawn_barriers()

	# Spawn exit
	spawn_exit()

	# Setup objectives
	current_objective = level_data.objectives.get("primary", "Survive")

	# Register with turn manager
	if TurnManager and player:
		TurnManager.set_player(player)
		for enemy in enemies:
			TurnManager.register_enemy(enemy)

	# Initialize tutorial if needed
	if level_data.tutorial_sequence.size() > 0:
		_setup_tutorial()

	print("LevelBase: Level %d initialized (%s)" % [level_num, level_data.name])

func _setup_tilemap() -> void:
	"""Setup the TileMap based on level data."""
	# Clear existing tiles
	if tilemap:
		tilemap.clear()

	# TODO: Load TileMap data from level_data
	# For now, create a simple floor pattern
	if tilemap:
		for x in range(grid_size.x):
			for y in range(grid_size.y):
				# Placeholder: add floor tiles
				# tilemap.set_cell(0, Vector2i(x, y), source_id, atlas_coords)
				pass

func spawn_player() -> void:
	"""Spawn the player avatar at starting position."""
	var player_scene = load("res://scenes/player/player_avatar.tscn")
	if not player_scene:
		push_error("LevelBase: Failed to load player_avatar.tscn")
		return

	var start_pos = LevelDataLoader.get_player_start_position()
	var start_dir = LevelDataLoader.get_player_start_direction()

	player = player_scene.instantiate() as Node2D
	if player:
		player.global_position = GameConstants.tile_to_pixel(start_pos)
		if player.has_method("update_direction"):
			player.update_direction(start_dir)

		entities_container.add_child(player)
		player.add_to_group("player")
		print("LevelBase: Player spawned at tile %s" % str(start_pos))

func spawn_enemies() -> void:
	"""Spawn enemies from level data."""
	var enemy_data_list = LevelDataLoader.get_enemies()

	for enemy_data in enemy_data_list:
		var enemy_type = enemy_data.get("type", "hound")
		var position = enemy_data.get("position", [10, 10])
		var patrol_points = enemy_data.get("patrol_waypoints", [])

		# Select enemy script based on type
		var enemy_script: String = ""
		match enemy_type:
			"hound":
				enemy_script = "res://scripts/enemies/hound.gd"
			"mirror_wraith":
				enemy_script = "res://scripts/enemies/mirror_wraith.gd"
			"hollow_sentinel":
				enemy_script = "res://scripts/enemies/hollow_sentinel.gd"
			"architect":
				enemy_script = "res://scripts/enemies/architect.gd"
			_:
				enemy_script = "res://scripts/enemies/enemy_base.gd"

		# Load enemy script
		var script = load(enemy_script)
		if not script:
			push_error("LevelBase: Failed to load %s" % enemy_script)
			continue

		# Create enemy node
		var enemy = CharacterBody2D.new()
		enemy.set_script(script)

		# Set position
		var world_pos = GameConstants.tile_to_pixel(Vector2i(int(position[0]), int(position[1])))
		enemy.global_position = world_pos

		# Add visual representation
		var sprite = Sprite2D.new()
		sprite.modulate = _get_enemy_color(enemy_type)
		enemy.add_child(sprite)

		# Add collision
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 6.0
		collision.shape = shape
		enemy.add_child(collision)

		# Set patrol waypoints if provided
		if patrol_points.size() > 0:
			var waypoints: Array[Vector2] = []
			for point in patrol_points:
				waypoints.append(GameConstants.tile_to_pixel(Vector2i(int(point[0]), int(point[1]))))
			enemy.patrol_waypoints = waypoints

		entities_container.add_child(enemy)
		enemy.add_to_group("enemies")
		enemies.append(enemy)

		print("LevelBase: %s spawned at tile %s" % [enemy_type, str(position)])

func spawn_hazards() -> void:
	"""Spawn hazards from level data."""
	var hazard_list = LevelDataLoader.get_hazards()

	for hazard_data in hazard_list:
		var hazard_type = hazard_data.get("type", "spike")
		var position = hazard_data.get("position", [15, 15])

		var hazard = Area2D.new()
		hazard.name = "Hazard_%s" % hazard_type

		# Create visual
		var sprite = Sprite2D.new()
		sprite.modulate = Color.RED
		hazard.add_child(sprite)

		# Create collision
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 4.0
		collision.shape = shape
		hazard.add_child(collision)

		# Set position
		var world_pos = GameConstants.tile_to_pixel(Vector2i(int(position[0]), int(position[1])))
		hazard.global_position = world_pos

		entities_container.add_child(hazard)
		hazard.add_to_group("hazards")
		hazards.append(hazard)

		print("LevelBase: %s spawned at tile %s" % [hazard_type, str(position)])

func spawn_barriers() -> void:
	"""Spawn barriers from level data."""
	var barrier_list = LevelDataLoader.get_barriers()

	for barrier_data in barrier_list:
		var barrier_type = barrier_data.get("type", "wall")
		var start = barrier_data.get("start", [10, 10])
		var end = barrier_data.get("end", [10, 14])

		# Create barrier line
		var barrier = Area2D.new()
		barrier.name = "Barrier_%s" % barrier_type

		var start_world = GameConstants.tile_to_pixel(Vector2i(int(start[0]), int(start[1])))
		var end_world = GameConstants.tile_to_pixel(Vector2i(int(end[0]), int(end[1])))

		# Set barrier position at midpoint
		barrier.global_position = (start_world + end_world) / 2.0

		# Add visual line
		var line = Line2D.new()
		line.add_point(start_world - barrier.global_position)
		line.add_point(end_world - barrier.global_position)
		line.width = 4.0
		line.default_color = Color.GRAY
		barrier.add_child(line)

		entities_container.add_child(barrier)
		barrier.add_to_group("barriers")

		print("LevelBase: Barrier spawned from %s to %s" % [str(start), str(end)])

func spawn_exit() -> void:
	"""Spawn level exit."""
	var exit_pos = LevelDataLoader.get_exit_position()
	var exit = Marker2D.new()
	exit.name = "Exit"

	var world_pos = GameConstants.tile_to_pixel(exit_pos)
	exit.global_position = world_pos

	markers_container.add_child(exit)
	exit.add_to_group("exits")

	print("LevelBase: Exit spawned at tile %s" % str(exit_pos))

func _setup_tutorial() -> void:
	"""Setup tutorial system if this is a tutorial level."""
	if level_data.tutorial_sequence.size() == 0:
		return

	# TODO: Connect to TutorialSystem when implemented
	print("LevelBase: Tutorial initialized with %d steps" % level_data.tutorial_sequence.size())

func _get_enemy_color(enemy_type: String) -> Color:
	"""Get color for enemy type visualization.

	Args:
		enemy_type: Type of enemy

	Returns:
		Color for the enemy
	"""
	match enemy_type:
		"hound":
			return Color(1.0, 0.5, 0.5)  # Red
		"mirror_wraith":
			return Color(0.0, 1.0, 1.0)  # Cyan
		"hollow_sentinel":
			return Color(1.0, 1.0, 0.5)  # Yellow
		"architect":
			return Color(0.5, 0.5, 1.0)  # Blue
		_:
			return Color.WHITE

func _start_level() -> void:
	"""Start the level turn cycle."""
	print("\n=== LEVEL %d STARTED ===" % level_number)

	if TurnManager:
		# Reset TurnManager state in case it's carrying over from previous level
		TurnManager.turn_number = 0
		TurnManager.current_phase = TurnManager.Phase.IDLE
		TurnManager.clear_action_queue()
		TurnManager.start_turn()

func check_objectives() -> bool:
	"""Check if level objectives are complete.

	Returns:
		true if all objectives met
	"""
	# Check if all enemies defeated
	if enemies.size() == 0:
		return true

	# Filter out dead enemies
	var alive_enemies = 0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.is_in_group("enemies"):
			alive_enemies += 1

	return alive_enemies == 0

func reset_level() -> void:
	"""Reset the level to initial state."""
	print("LevelBase: Resetting level %d" % level_number)
	# Clear entities
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()

	if is_instance_valid(player):
		player.queue_free()
	player = null

	# Reinitialize
	initialize_level(level_number)

func _on_level_won() -> void:
	"""Handle level victory."""
	if level_complete:
		return

	level_complete = true
	print("\n*** LEVEL %d WON ***\n" % level_number)

	# Award XP and mark level complete
	var xp = LevelDataLoader.get_xp_reward()
	if GameManager:
		GameManager.complete_level(level_number, xp)
		print("Gained %d XP" % xp)

	level_victory.emit()

	# Return to menu after delay
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_level_lost() -> void:
	"""Handle level defeat."""
	if level_complete:
		return

	level_complete = true
	print("\n*** LEVEL %d LOST ***\n" % level_number)

	level_defeat.emit()

	# Restart level after delay
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func get_objective_text() -> String:
	"""Get human-readable objective text.

	Returns:
		Objective description
	"""
	if not level_data:
		return "No objective"

	var primary = level_data.objectives.get("primary", "Survive and learn")
	var secondary = level_data.objectives.get("secondary", [])

	var text = "Primary: %s" % primary
	if secondary.size() > 0:
		text += "\nSecondary:"
		for obj in secondary:
			text += "\n  - %s" % obj

	return text
