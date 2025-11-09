# res://scripts/autoload/game_constants.gd
extends Node

# === TRANSFORMATION RANGES ===
# All ranges scale at +1 tile per level beyond Level 1
const TILE_SIZE: int = 16  # pixels
const BASE_RANGE_TILES: int = 1  # Starting range at Level 1
const RANGE_PER_LEVEL_TILES: int = 1  # Additional tiles per level

# === TARGET TYPE COSTS ===
# Affecting different targets has different level costs
enum TargetType {
	SELF,
	OBJECT,
	ENEMY
}

const TARGET_COSTS: Dictionary = {
	TargetType.SELF: 0,    # No cost - full power
	TargetType.OBJECT: 1,  # -1 effective level
	TargetType.ENEMY: 2    # -2 effective level
}

# === XP SYSTEM ===
const XP_TO_LEVEL_10: int = 2700
const LEVEL_CAP: int = 10

# === SHADOWSHIFT SCALING ===
# Scale factors increase on ODD levels only
static func get_max_scale(player_level: int) -> float:
	var scale_level := (player_level + 1) / 2  # Integer division
	return float(scale_level + 1)
	# Level 1: 2.0x, Level 3: 3.0x, Level 5: 4.0x, Level 7: 5.0x, Level 9: 6.0x

static func get_min_scale(player_level: int) -> float:
	var scale_level := (player_level + 1) / 2
	return 1.0 / float(scale_level + 1)
	# Level 1: 0.5x (1/2), Level 3: 0.333x (1/3), Level 5: 0.25x (1/4), etc.

# === RANGE CALCULATION ===
static func get_transformation_range(player_level: int, transformation_type: String) -> int:
	"""
	Returns the base range in pixels for a transformation at a given level.
	Formula: 1 + (player_level - 1) * 1 = player_level tiles
	"""
	var tiles: int
	
	match transformation_type:
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
			tiles = player_level
	
	return tiles * TILE_SIZE

# === EFFECTIVE LEVEL CALCULATION ===
static func get_effective_level_for_target(player_level: int, target_type: TargetType) -> int:
	"""
	Returns the effective level after applying target type cost.
	Examples:
	  - Level 6, SELF: 6 - 0 = 6 (full power)
	  - Level 6, OBJECT: 6 - 1 = 5 (reduced)
	  - Level 6, ENEMY: 6 - 2 = 4 (more reduced)
	"""
	var cost: int = TARGET_COSTS[target_type]
	return max(1, player_level - cost)  # Minimum effective level is 1

# === MULTI-TARGET POWER CALCULATION ===
static func calculate_split_power(player_level: int, num_targets: int, target_type: TargetType) -> int:
	"""
	Split Power mode (Level 3+): Divide level among targets, THEN apply per-target costs.
	
	Example: Level 6, 2 objects
	  6 / 2 = 3 per target
	  3 - 1 (object cost) = 2 tiles each
	"""
	var level_per_target: int = player_level / num_targets  # Integer division
	var effective_level: int = level_per_target - TARGET_COSTS[target_type]
	return max(1, effective_level) * TILE_SIZE

static func calculate_mastery_power(player_level: int, num_targets: int, target_type: TargetType) -> int:
	"""
	Multi-Target Mastery mode (Level 5+): -1 per target (total), THEN apply per-target costs.
	More efficient than Split Power!
	
	Example: Level 6, 2 objects
	  6 - 2 = 4
	  4 - 1 (object cost) = 3 tiles each
	"""
	var base_level: int = player_level - num_targets
	var effective_level: int = base_level - TARGET_COSTS[target_type]
	return max(1, effective_level) * TILE_SIZE

# === ABILITY UNLOCK LEVELS ===
const ABILITY_UNLOCKS: Dictionary = {
	1: ["shadow_slide", "mirrorwalk_self", "turn", "shadowshift_2x"],
	2: ["affect_other", "ranges_+1"],
	3: ["split_power", "shadowshift_3x", "ranges_+1"],
	4: ["combo_2_powers", "ranges_+1"],
	5: ["multi_target_mastery", "shadowshift_4x", "ranges_+1"],
	6: ["affect_enemy", "ranges_+1"],
	7: ["combo_3_powers", "shadowshift_5x", "ranges_+1"],
	8: ["combo_4_powers", "ranges_+1"],
	9: ["shadowshift_6x", "ranges_+1"],
	10: ["ranges_+1", "maximum_power"]
}

# === SHADOWSHIFT RANGE CALCULATION ===
static func get_shadowshift_range(player_level: int, target_type: TargetType) -> Vector2:
	"""
	Returns (min_scale, max_scale) for Shadowshift at given level and target type.
	"""
	var max_scale: float = get_max_scale(player_level)
	var min_scale: float = get_min_scale(player_level)
	
	# Apply target restrictions
	match target_type:
		TargetType.SELF:
			# Full range: 30%-200% at Level 2, expanding to 6x/1/6 at Level 9
			return Vector2(min_scale, max_scale)
		TargetType.OBJECT:
			# Tighter range: 60%-150%
			return Vector2(max(min_scale, 0.6), min(max_scale, 1.5))
		TargetType.ENEMY:
			# Most restricted initially: 40%-250% at max
			return Vector2(max(min_scale, 0.4), min(max_scale, 2.5))
	
	return Vector2(min_scale, max_scale)
