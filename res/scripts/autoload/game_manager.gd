# res://scripts/autoload/game_manager.gd
extends Node

# === PLAYER PROGRESSION ===
var player_level: int = 1
var total_xp: int = 0

# === ABILITIES ===
# Tracks which abilities are unlocked based on player level
var abilities: Dictionary = {
	# Level 1: Available from start
	"shadow_slide": true,
	"mirrorwalk": true,
	"turn": true,

	# Level 2: Shadowshift (self)
	"shadowshift_self": false,

	# Level 3: Shadow Pivot, Split Power
	"shadow_pivot": false,
	"split_power": false,

	# Level 4: Shadowshift (object), Combo 2
	"shadowshift_object": false,
	"combo_2": false,

	# Level 5: Multi-Target Mastery
	"multi_target_mastery": false,

	# Level 6: Shadowshift (enemy)
	"shadowshift_enemy": false,

	# Level 7: Combo 3
	"combo_3": false,

	# Level 8: Combo 4
	"combo_4": false,
}

# === CURRENT RANGES (calculated dynamically) ===
var ranges: Dictionary = {
	"shadow_slide": 0,
	"mirrorwalk": 0,
	"shadow_pivot": 0
}

# === MULTI-TARGET LIMITS ===
var multi_target: Dictionary = {
	"split_max_targets": 1,     # Level 3: 2, Level 5: 3
	"mastery_max_targets": 1,   # Level 5: 2, Level 7: 3, Level 9: 4, Level 10: 99
	"mastery_active": false     # Becomes true at Level 5
}

# === LEVEL PROGRESS ===
var levels_complete: Array[int] = []
var current_level: int = 1
var resets_used: int = 0

# === BESTIARY ===
var bestiary_unlocked: Array[String] = []

# === SETTINGS ===
var volume_master: float = 1.0
var volume_music: float = 0.8
var volume_sfx: float = 1.0
var grid_overlay: bool = false
var angle_snap: bool = true

# === SIGNALS ===
signal level_up(new_level: int)
signal xp_gained(amount: int)
signal ability_unlocked(ability_name: String)
signal level_completed(level_num: int)

func _ready() -> void:
	update_ranges()
	load_game()

# === XP & LEVELING ===
func gain_xp(amount: int) -> void:
	"""Add XP and check for level up."""
	total_xp += amount
	xp_gained.emit(amount)
	check_level_up()

func check_level_up() -> void:
	"""Check if player should level up based on total XP."""
	# Linear progression: 900 XP total to reach Level 10
	# That's 128.57 XP per level (rounded)
	var xp_per_level: int = GameConstants.XP_TO_LEVEL_10 / (GameConstants.LEVEL_CAP - 1)
	var required_level: int = min(GameConstants.LEVEL_CAP, 1 + (total_xp / xp_per_level))

	while player_level < required_level:
		player_level += 1
		level_up.emit(player_level)
		update_ranges()
		check_ability_unlocks()

func update_ranges() -> void:
	"""Update transformation ranges based on current player level."""
	ranges["shadow_slide"] = GameConstants.get_transformation_range(player_level, "shadow_slide")
	ranges["mirrorwalk"] = GameConstants.get_transformation_range(player_level, "mirrorwalk")
	ranges["shadow_pivot"] = GameConstants.get_transformation_range(player_level, "shadow_pivot")

func check_ability_unlocks() -> void:
	"""Check for new abilities unlocked at current level per GDD Section 10.1."""
	match player_level:
		2:
			# Level 2: Shadowshift (self) unlocked
			unlock_ability("shadowshift_self")
			multi_target["split_max_targets"] = 2
		3:
			# Level 3: Shadow Pivot, Split Power unlocked
			unlock_ability("shadow_pivot")
			unlock_ability("split_power")
		4:
			# Level 4: Shadowshift (object), Combo 2 unlocked
			unlock_ability("shadowshift_object")
			unlock_ability("combo_2")
		5:
			# Level 5: Multi-Target Mastery unlocked
			unlock_ability("multi_target_mastery")
			multi_target["mastery_active"] = true
			multi_target["mastery_max_targets"] = 2
		6:
			# Level 6: Shadowshift (enemy) unlocked
			unlock_ability("shadowshift_enemy")
		7:
			# Level 7: Combo 3 unlocked
			unlock_ability("combo_3")
			multi_target["mastery_max_targets"] = 3
		8:
			# Level 8: Combo 4 unlocked
			unlock_ability("combo_4")
		9:
			# Level 9: Mastery targets increased
			multi_target["mastery_max_targets"] = 4
		10:
			# Level 10: Mastery targets effectively unlimited
			multi_target["mastery_max_targets"] = 99

func unlock_ability(ability_name: String) -> void:
	"""Unlock a specific ability if not already unlocked."""
	if not abilities.get(ability_name, false):
		abilities[ability_name] = true
		ability_unlocked.emit(ability_name)

# === LEVEL MANAGEMENT ===
func complete_level(level_num: int, xp_reward: int) -> void:
	"""Mark a level as complete and award XP."""
	if level_num not in levels_complete:
		levels_complete.append(level_num)
	gain_xp(xp_reward)
	level_completed.emit(level_num)
	save_game()

func unlock_bestiary_entry(entry_name: String) -> void:
	"""Unlock a bestiary entry for defeating an enemy."""
	if entry_name not in bestiary_unlocked:
		bestiary_unlocked.append(entry_name)
		save_game()

# === SAVE/LOAD SYSTEM (Stubs - implement in Task 1.5) ===
func save_game() -> void:
	"""Save game progress to SaveSystem (stub - will be implemented in Task 1.5)."""
	# TODO: Call SaveSystem.save_game() with all game state
	pass

func load_game() -> void:
	"""Load game progress from SaveSystem (stub - will be implemented in Task 1.5)."""
	# TODO: Call SaveSystem.load_game() and apply loaded data
	pass

func reset_progress() -> void:
	"""Completely reset all progress for new game or testing."""
	player_level = 1
	total_xp = 0
	abilities = {
		"shadow_slide": true,
		"mirrorwalk": true,
		"turn": true,
		"shadowshift_self": false,
		"shadow_pivot": false,
		"split_power": false,
		"shadowshift_object": false,
		"combo_2": false,
		"multi_target_mastery": false,
		"shadowshift_enemy": false,
		"combo_3": false,
		"combo_4": false,
	}
	multi_target = {
		"split_max_targets": 1,
		"mastery_max_targets": 1,
		"mastery_active": false
	}
	levels_complete = []
	current_level = 1
	resets_used = 0
	bestiary_unlocked = []
	volume_master = 1.0
	volume_music = 0.8
	volume_sfx = 1.0
	grid_overlay = false
	angle_snap = true
	update_ranges()
	save_game()
