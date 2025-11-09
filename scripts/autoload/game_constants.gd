# res://scripts/autoload/game_constants.gd
extends Node

# === TILE AND COORDINATE SYSTEM ===
# The game uses a grid-based tile system for strategic movement
const TILE_SIZE: int = 16  # pixels per tile

# === TRANSFORMATION RANGES ===
# All ranges scale at +1 tile per level beyond Level 1
const BASE_RANGE_TILES: int = 1  # Starting range at Level 1
const RANGE_PER_LEVEL_TILES: int = 1  # Additional tiles per level

# === TARGET TYPE COSTS ===
# Affecting different targets has different level costs
enum TargetType {
	SELF,      # Cost: 0 - full power (100%)
	OBJECT,    # Cost: 1 - reduced power (150% ability cost)
	ENEMY      # Cost: 2 - most reduced power (200% ability cost)
}

const TARGET_COSTS: Dictionary = {
	TargetType.SELF: 0,    # No cost - full power
	TargetType.OBJECT: 1,  # -1 effective level
	TargetType.ENEMY: 2    # -2 effective level
}

# === PROGRESSION SYSTEM ===
const LEVEL_CAP: int = 10        # Maximum player level
const XP_TO_LEVEL_10: int = 900  # Total XP needed to reach level 10

# === SHADOWSHIFT SCALING ===
# Scale factors increase on ODD levels only
static func get_max_scale(player_level: int) -> float:
	"""
	Returns maximum scale factor for Shadowshift at given level.
	Only changes on ODD levels (1, 3, 5, 7, 9).
	"""
	var scale_level: int = int((player_level + 1) / 2.0)
	return float(scale_level + 1)
	# Level 1: 2.0x, Level 3: 3.0x, Level 5: 4.0x, Level 7: 5.0x, Level 9: 6.0x

static func get_min_scale(player_level: int) -> float:
	"""
	Returns minimum scale factor for Shadowshift at given level.
	Inverse of max scale.
	"""
	var scale_level: int = int((player_level + 1) / 2.0)
	return 1.0 / float(scale_level + 1)
	# Level 1: 0.5x (1/2), Level 3: 0.333x (1/3), Level 5: 0.25x (1/4), etc.

# === RANGE CALCULATION ===
static func get_transformation_range(player_level: int, ability: String = "") -> int:
	"""
	Returns the base range in tiles for a transformation at a given level.
	Formula for most abilities: player_level tiles

	Args:
		player_level: Current player level (1-10)
		ability: Optional ability name for type-specific ranges

	Returns:
		Range in tiles
	"""
	var tiles: int

	match ability:
		"shadow_slide", "mirrorwalk":
			# Both scale the same: player_level tiles
			tiles = player_level
		"shadow_pivot":
			# Unlocked at Level 3, starts at 0 tiles (self-only)
			if player_level < 3:
				tiles = 0
			else:
				tiles = player_level - 2
		_:
			# Default: scales with level
			tiles = player_level

	return tiles

static func get_effective_level_for_target(player_level: int, target_type: TargetType) -> int:
	"""
	Returns the effective level after applying target type cost.

	Examples:
	  - Level 6, SELF: 6 - 0 = 6 (full power)
	  - Level 6, OBJECT: 6 - 1 = 5 (reduced power)
	  - Level 6, ENEMY: 6 - 2 = 4 (most reduced power)

	Args:
		player_level: Current player level
		target_type: Which type of target (SELF, OBJECT, or ENEMY)

	Returns:
		Effective level after cost (minimum 1)
	"""
	var cost: int = TARGET_COSTS[target_type]
	return max(1, player_level - cost)

# === MULTI-TARGET POWER CALCULATION ===
static func calculate_split_power(player_level: int, num_targets: int, target_type: TargetType) -> int:
	"""
	Split Power mode (Level 3+): Divide level among targets, THEN apply per-target costs.

	Example: Level 6, 2 objects
	  6 / 2 = 3 per target
	  3 - 1 (object cost) = 2 tiles each

	Args:
		player_level: Current player level
		num_targets: How many targets are being affected
		target_type: Type of targets

	Returns:
		Effective range per target in tiles
	"""
	var level_per_target: int = int(float(player_level) / float(num_targets))
	var effective_level: int = level_per_target - TARGET_COSTS[target_type]
	return max(1, effective_level)

static func calculate_mastery_power(player_level: int, num_targets: int, target_type: TargetType) -> int:
	"""
	Multi-Target Mastery mode (Level 5+): -1 per target (total), THEN apply per-target costs.
	More efficient than Split Power!

	Example: Level 6, 2 objects
	  6 - 2 = 4
	  4 - 1 (object cost) = 3 tiles each

	Args:
		player_level: Current player level
		num_targets: How many targets are being affected
		target_type: Type of targets

	Returns:
		Effective range per target in tiles
	"""
	var base_level: int = player_level - num_targets
	var effective_level: int = base_level - TARGET_COSTS[target_type]
	return max(1, effective_level)

# === ABILITY UNLOCK LEVELS ===
const ABILITY_UNLOCKS: Dictionary = {
	1: ["shadow_slide", "mirrorwalk", "turn"],
	2: ["shadowshift_self", "split_max_targets_2"],
	3: ["shadow_pivot", "split_power"],
	4: ["shadowshift_object", "combo_2"],
	5: ["multi_target_mastery", "mastery_max_targets_2"],
	6: ["shadowshift_enemy"],
	7: ["combo_3", "mastery_max_targets_3"],
	8: ["combo_4"],
	9: ["mastery_max_targets_4"],
	10: ["mastery_max_targets_99"]
}

# === SHADOWSHIFT RANGE CALCULATION ===
static func get_shadowshift_range(player_level: int, target_type: TargetType) -> Vector2:
	"""
	Returns (min_scale, max_scale) for Shadowshift at given level and target type.

	Args:
		player_level: Current player level
		target_type: Which type of target (SELF, OBJECT, or ENEMY)

	Returns:
		Vector2(min_scale, max_scale) - scaling range
	"""
	var max_scale: float = get_max_scale(player_level)
	var min_scale: float = get_min_scale(player_level)

	# Apply target restrictions
	match target_type:
		TargetType.SELF:
			# Full range: 0.5x-2.0x at Level 1, expanding to 1/6x-6.0x at Level 9
			return Vector2(min_scale, max_scale)
		TargetType.OBJECT:
			# Tighter range: 60%-150%
			return Vector2(max(min_scale, 0.6), min(max_scale, 1.5))
		TargetType.ENEMY:
			# Most restricted: 40%-250%
			return Vector2(max(min_scale, 0.4), min(max_scale, 2.5))

	return Vector2(min_scale, max_scale)

# === COORDINATE CONVERSION HELPERS ===
static func tile_to_pixel(tile_coord: Vector2i) -> Vector2:
	"""
	Converts tile coordinates to world pixel position (at tile center).

	Args:
		tile_coord: Position in tiles (grid coordinates)

	Returns:
		Position in pixels
	"""
	return Vector2(tile_coord) * TILE_SIZE + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)

static func pixel_to_tile(pixel_pos: Vector2) -> Vector2i:
	"""
	Converts world pixel position to tile coordinates.

	Args:
		pixel_pos: Position in pixels

	Returns:
		Position in tiles (grid coordinates)
	"""
	return (pixel_pos / TILE_SIZE).round()
