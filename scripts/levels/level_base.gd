# res://scripts/levels/level_base.gd
extends Node2D

# === LEVEL DATA ===
var level_number: int = 1
var level_data: Dictionary = {}
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

func _ready() -> void:
	"""Initialize level on load."""
	# Get node references
	tilemap = get_node_or_null("TileMap")
	entities_container = get_node_or_null("Entities")
	markers_container = get_node_or_null("Markers")

	if not tilemap:
		push_error("LevelBase: TileMap node not found")
		return
	if not entities_container:
		push_error("LevelBase: Entities container not found")
		return
	if not markers_container:
		push_error("LevelBase: Markers container not found")
		return

	# Initialize the level
	initialize_level(level_number)

func initialize_level(level_num: int) -> void:
	"""
	Initialize a level by loading data and setting up entities.

	Args:
		level_num: The level number to load
	"""
	level_number = level_num

	# Load level data
	level_data = LevelManager.get_level_data(level_num)
	if level_data.is_empty():
		push_error("LevelBase: Failed to load level data for level %d" % level_num)
		return

	# Extract grid size
	if level_data.has("arena"):
		var arena = level_data["arena"]
		grid_size = Vector2i(arena.get("width_tiles", 40), arena.get("height_tiles", 25))

	# Setup arena (TileMap)
	_setup_tilemap()

	# Spawn player
	if level_data.has("player_start"):
		var start_data = level_data["player_start"]
		var start_pos = Vector2i(start_data.get("position", [5, 12]))
		var start_dir = Vector2(start_data.get("direction", [1, 0]))
		spawn_player(start_pos, start_dir)

	# Spawn enemies
	if level_data.has("enemies"):
		spawn_enemies(level_data["enemies"])

	# Spawn hazards
	if level_data.has("hazards"):
		spawn_hazards(level_data["hazards"])

	# Setup objectives
	if level_data.has("objectives"):
		current_objective = level_data["objectives"].get("primary", "Survive")

	# Initialize tutorial if needed
	if level_data.has("tutorial_sequence"):
		_setup_tutorial()

	print("LevelBase: Level %d initialized (%s)" % [level_num, level_data.get("name", "Unknown")])

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

func spawn_player(position: Vector2i, direction: Vector2) -> void:
	"""
	Spawn the player avatar at a position.

	Args:
		position: Tile position to spawn at
		direction: Initial facing direction
	"""
	# Load player scene
	var player_scene = load("res://scenes/player/player_avatar.tscn")
	if not player_scene:
		push_error("LevelBase: Failed to load player_avatar.tscn")
		return

	player = player_scene.instantiate()
	if player:
		# Set initial position and direction
		player.current_position = position
		player.current_direction = direction
		player.position = GridSystem.tile_to_world(position)
		entities_container.add_child(player)
		print("LevelBase: Player spawned at tile %s" % [position])

func spawn_enemies(enemy_data: Array) -> void:
	"""
	Spawn enemies from level data.

	Args:
		enemy_data: Array of enemy spawn data
	"""
	for enemy_info in enemy_data:
		var enemy_type: String = enemy_info.get("type", "hound")
		var position: Vector2i = Vector2i(enemy_info.get("position", [10, 10]))

		var enemy_scene_path: String = ""
		match enemy_type:
			"hound":
				enemy_scene_path = "res://scenes/enemies/hound.tscn"
			"mirror_wraith":
				enemy_scene_path = "res://scenes/enemies/mirror_wraith.tscn"
			"hollow_sentinel":
				enemy_scene_path = "res://scenes/enemies/hollow_sentinel.tscn"
			_:
				push_warning("LevelBase: Unknown enemy type: %s" % enemy_type)
				continue

		var enemy_scene = load(enemy_scene_path)
		if not enemy_scene:
			push_error("LevelBase: Failed to load %s" % enemy_scene_path)
			continue

		var enemy = enemy_scene.instantiate()
		if enemy:
			enemy.current_tile = position
			enemy.position = GridSystem.tile_to_world(position)
			entities_container.add_child(enemy)
			enemies.append(enemy)
			enemy.add_to_group("enemies")

			# Set patrol points if it's a hound
			if enemy_type == "hound" and enemy_info.has("patrol_points"):
				var patrol_points = enemy_info["patrol_points"]
				if enemy.has_method("set_patrol_points"):
					enemy.set_patrol_points(patrol_points)

			print("LevelBase: %s spawned at tile %s" % [enemy_type, position])

func spawn_hazards(hazard_data: Array) -> void:
	"""
	Spawn hazards from level data.

	Args:
		hazard_data: Array of hazard spawn data
	"""
	for hazard_info in hazard_data:
		var hazard_type: String = hazard_info.get("type", "spike_trap")
		var position: Vector2i = Vector2i(hazard_info.get("position", [10, 10]))

		# Create a simple hazard marker
		var hazard = Node2D.new()
		hazard.position = GridSystem.tile_to_world(position)
		hazard.name = hazard_type
		hazard.add_to_group("hazards")

		# TODO: Add visual representation
		entities_container.add_child(hazard)
		hazards.append(hazard)

		print("LevelBase: %s spaward at tile %s" % [hazard_type, position])

func _setup_tutorial() -> void:
	"""Setup tutorial system if this is a tutorial level."""
	if not level_data.has("tutorial_sequence"):
		return

	var tutorial_steps = level_data["tutorial_sequence"]
	if TutorialSystem:
		TutorialSystem.start_tutorial(tutorial_steps)
		print("LevelBase: Tutorial started")

func check_objectives() -> bool:
	"""
	Check if level objectives are complete.

	Returns:
		true if all objectives met, false otherwise
	"""
	# Check if player reached exit
	if player and level_data.has("exit"):
		var exit_pos = Vector2i(level_data["exit"].get("position", [35, 12]))
		if player.current_position == exit_pos:
			return true

	return false

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

func complete_level() -> void:
	"""Mark the level as complete."""
	if not level_complete:
		level_complete = true
		var xp_reward = level_data.get("xp_reward", 100)
		LevelManager.mark_level_complete(level_number, xp_reward)
		print("LevelBase: Level %d completed! +%d XP" % [level_number, xp_reward])
