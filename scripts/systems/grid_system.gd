# res://scripts/systems/grid_system.gd
extends Node

# === TILE SIZE ===
var tile_size: int = GameConstants.TILE_SIZE  # 16 pixels

# === COORDINATE CONVERSION ===
static func world_to_tile(world_pos: Vector2) -> Vector2i:
	"""
	Convert world pixel position to tile coordinates.

	Args:
		world_pos: Position in world pixels

	Returns:
		Position in tile grid coordinates
	"""
	return (world_pos / GameConstants.TILE_SIZE).round()

static func tile_to_world(tile_pos: Vector2i) -> Vector2:
	"""
	Convert tile coordinates to world pixel position (at tile center).

	Args:
		tile_pos: Position in tile grid coordinates

	Returns:
		Position in world pixels (at tile center)
	"""
	return Vector2(tile_pos) * GameConstants.TILE_SIZE + Vector2(GameConstants.TILE_SIZE / 2.0, GameConstants.TILE_SIZE / 2.0)

# === VALIDATION ===
static func is_tile_valid(tile_pos: Vector2i, grid_size: Vector2i) -> bool:
	"""
	Check if a tile position is within grid bounds.

	Args:
		tile_pos: Position to check
		grid_size: Grid dimensions in tiles (width, height)

	Returns:
		true if tile is within bounds, false otherwise
	"""
	return (tile_pos.x >= 0 and tile_pos.x < grid_size.x and
			tile_pos.y >= 0 and tile_pos.y < grid_size.y)

# === TILE INFO ===
static func get_tile_center(tile_pos: Vector2i) -> Vector2:
	"""
	Get the world position of a tile's center.

	Args:
		tile_pos: Tile coordinates

	Returns:
		World pixel position at tile center
	"""
	return tile_to_world(tile_pos)

static func get_tile_bounds(tile_pos: Vector2i) -> Rect2:
	"""
	Get the world-space bounds of a tile.

	Args:
		tile_pos: Tile coordinates

	Returns:
		Rect2 defining the tile's bounds in world space
	"""
	var tile_size_f: float = GameConstants.TILE_SIZE
	var top_left: Vector2 = Vector2(tile_pos) * tile_size_f
	return Rect2(top_left, Vector2(tile_size_f, tile_size_f))

# === RANGE CALCULATIONS ===
static func get_tiles_in_range(center: Vector2i, range_tiles: int) -> Array[Vector2i]:
	"""
	Get all tiles within a certain range of a center tile (manhattan distance).

	Args:
		center: Center tile position
		range_tiles: Range in tiles

	Returns:
		Array of all tiles within range
	"""
	var tiles: Array[Vector2i] = []

	for x in range(center.x - range_tiles, center.x + range_tiles + 1):
		for y in range(center.y - range_tiles, center.y + range_tiles + 1):
			var tile_pos = Vector2i(x, y)
			if get_manhattan_distance(center, tile_pos) <= range_tiles:
				tiles.append(tile_pos)

	return tiles

static func get_manhattan_distance(from: Vector2i, to: Vector2i) -> int:
	"""
	Calculate Manhattan distance between two tiles.

	Args:
		from: Starting tile position
		to: Ending tile position

	Returns:
		Distance in tiles
	"""
	return abs(from.x - to.x) + abs(from.y - to.y)

static func get_euclidean_distance(from: Vector2i, to: Vector2i) -> float:
	"""
	Calculate Euclidean distance between two tiles.

	Args:
		from: Starting tile position
		to: Ending tile position

	Returns:
		Distance in tiles (as float)
	"""
	var diff: Vector2i = to - from
	return sqrt(diff.x * diff.x + diff.y * diff.y)

# === LINE OF SIGHT ===
static func get_line_of_tiles(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	"""
	Get all tiles along a line between two points (Bresenham-like).

	Args:
		from: Starting tile
		to: Ending tile

	Returns:
		Array of tiles along the line
	"""
	var tiles: Array[Vector2i] = []
	var current: Vector2i = from
	var delta: Vector2i = to - from
	var step_x: int = sign(delta.x)
	var step_y: int = sign(delta.y)
	var abs_x: int = abs(delta.x)
	var abs_y: int = abs(delta.y)

	if abs_x == 0 and abs_y == 0:
		return [from]

	if abs_x >= abs_y:
		# More horizontal movement
		var error: int = int(float(abs_x) / 2.0)
		while current != to:
			tiles.append(current)
			current.x += step_x
			error -= abs_y
			if error < 0:
				current.y += step_y
				error += abs_x
	else:
		# More vertical movement
		var error: int = int(float(abs_y) / 2.0)
		while current != to:
			tiles.append(current)
			current.y += step_y
			error -= abs_x
			if error < 0:
				current.x += step_x
				error += abs_y

	tiles.append(to)
	return tiles

# === DIRECTION HELPERS ===
static func get_direction_to_tile(from: Vector2i, to: Vector2i) -> Vector2:
	"""
	Get normalized direction vector from one tile to another.

	Args:
		from: Starting tile
		to: Target tile

	Returns:
		Normalized direction vector
	"""
	var diff: Vector2 = Vector2(to - from)
	if diff.length() == 0:
		return Vector2.ZERO
	return diff.normalized()

static func get_adjacent_tiles(tile_pos: Vector2i) -> Array[Vector2i]:
	"""
	Get the 4 adjacent tiles (up, down, left, right).

	Args:
		tile_pos: Center tile

	Returns:
		Array of adjacent tile positions
	"""
	return [
		tile_pos + Vector2i.UP,
		tile_pos + Vector2i.DOWN,
		tile_pos + Vector2i.LEFT,
		tile_pos + Vector2i.RIGHT
	]

static func get_adjacent_and_diagonal_tiles(tile_pos: Vector2i) -> Array[Vector2i]:
	"""
	Get all 8 surrounding tiles (4 adjacent + 4 diagonal).

	Args:
		tile_pos: Center tile

	Returns:
		Array of surrounding tile positions
	"""
	var tiles: Array[Vector2i] = []
	for x in range(-1, 2):
		for y in range(-1, 2):
			if x != 0 or y != 0:
				tiles.append(tile_pos + Vector2i(x, y))
	return tiles

# === REFLECTION HELPERS ===
static func reflect_point_across_line(point: Vector2, line_start: Vector2, line_end: Vector2) -> Vector2:
	"""
	Reflect a point across a line defined by two points.

	Args:
		point: Point to reflect
		line_start: Start of mirror line
		line_end: End of mirror line

	Returns:
		Reflected point position
	"""
	# Convert to line-local coordinates
	var line_vec: Vector2 = line_end - line_start
	var line_len_sq: float = line_vec.length_squared()

	if line_len_sq == 0:
		return point  # Line is a point, return original

	# Project point onto line
	var point_vec: Vector2 = point - line_start
	var t: float = point_vec.dot(line_vec) / line_len_sq
	var closest_point: Vector2 = line_start + t * line_vec

	# Reflect: point' = 2 * closest - point
	return 2 * closest_point - point

static func reflect_direction_across_line(direction: Vector2, line_start: Vector2, line_end: Vector2) -> Vector2:
	"""
	Reflect a direction vector across a line.

	Args:
		direction: Direction to reflect
		line_start: Start of mirror line
		line_end: End of mirror line

	Returns:
		Reflected direction vector
	"""
	var line_vec: Vector2 = (line_end - line_start).normalized()
	var normal: Vector2 = Vector2(-line_vec.y, line_vec.x)  # Perpendicular

	# Reflect: d' = d - 2(d·n)n
	return direction - 2 * direction.dot(normal) * normal
