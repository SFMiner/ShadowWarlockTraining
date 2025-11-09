# res://scripts/autoload/game_manager.gd
extends Node

# === PLAYER PROGRESSION ===
var player_level: int = 1
var total_xp: int = 0

# === ABILITIES ===
var abilities: Dictionary = {
	"shadow_slide": true,
	"mirrorwalk": true,
	"turn": true,
	"shadow_pivot": false,  # Unlocks Level 3
	"shadowshift_self": false,  # Unlocks Level 2
	"shadowshift_object": false,  # Unlocks Level 4
	"shadowshift_enemy": false,  # Unlocks Level 8
	"split_power": false,  # Unlocks Level 3
	"multi_target_mastery": false,  # Unlocks Level 5
	"combo_2": false,  # Unlocks Level 4
	"combo_3": false,  # Unlocks Level 7
	"combo_4": false  # Unlocks Level 8
}

# === CURRENT RANGES (calculated dynamically) ===
var ranges: Dictionary = {
	"shadow_slide": 0,
	"mirrorwalk": 0,
	"shadow_pivot": 0
}

# === MULTI-TARGET LIMITS ===
var multi_target: Dictionary = {
	"split_max_targets": 1,  # Level 3: 2, Level 5: 3, etc.
	"mastery_max_targets": 1,  # Level 5: 2, Level 7: 3, etc.
	"mastery_active": false  # Becomes true at Level 5
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

signal level_up(new_level: int)
signal xp_gained(amount: int)
signal ability_unlocked(ability_name: String)
signal level_completed(level_num: int)

func _ready() -> void:
	update_ranges()
	load_game()

# === XP & LEVELING ===
func gain_xp(amount: int) -> void:
	total_xp += amount
	xp_gained.emit(amount)
	check_level_up()

func check_level_up() -> void:
	# Simple linear progression to Level 10
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
	"""Check for new abilities unlocked at current level."""
	match player_level:
		2:
			unlock_ability("shadowshift_self")
			multi_target["split_max_targets"] = 2
		3:
			unlock_ability("shadow_pivot")
			unlock_ability("split_power")
			multi_target["split_max_targets"] = 2
		4:
			unlock_ability("shadowshift_object")
			unlock_ability("combo_2")
		5:
			unlock_ability("multi_target_mastery")
			multi_target["mastery_active"] = true
			multi_target["mastery_max_targets"] = 2
		6:
			unlock_ability("shadowshift_enemy")
		7:
			unlock_ability("combo_3")
			multi_target["mastery_max_targets"] = 3
		8:
			unlock_ability("combo_4")
		9:
			multi_target["mastery_max_targets"] = 4
		10:
			multi_target["mastery_max_targets"] = 99  # Effectively unlimited

func unlock_ability(ability_name: String) -> void:
	if not abilities[ability_name]:
		abilities[ability_name] = true
		ability_unlocked.emit(ability_name)

# === LEVEL MANAGEMENT ===
func complete_level(level_num: int, xp_reward: int) -> void:
	if level_num not in levels_complete:
		levels_complete.append(level_num)
	gain_xp(xp_reward)
	level_completed.emit(level_num)
	save_game()

func unlock_bestiary_entry(entry_name: String) -> void:
	if entry_name not in bestiary_unlocked:
		bestiary_unlocked.append(entry_name)
		save_game()

# === SAVE/LOAD SYSTEM ===
func save_game() -> void:
	var save_data: Dictionary = {
		"version": "3.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"player": {
			"level": player_level,
			"xp": total_xp
		},
		"abilities": abilities,
		"ranges": ranges,
		"multi_target": multi_target,
		"progress": {
			"levels_complete": levels_complete,
			"current_level": current_level,
			"resets_used": resets_used
		},
		"bestiary": bestiary_unlocked,
		"settings": {
			"volume_master": volume_master,
			"volume_music": volume_music,
			"volume_sfx": volume_sfx,
			"grid_overlay": grid_overlay,
			"angle_snap": angle_snap
		}
	}
	
	var file := FileAccess.open("user://shadow_warlock_v3_save.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists("user://shadow_warlock_v3_save.json"):
		return
	
	var file := FileAccess.open("user://shadow_warlock_v3_save.json", FileAccess.READ)
	if file:
		var json := JSON.new()
		var parse_result := json.parse(file.get_as_text())
		file.close()
		
		if parse_result == OK:
			var save_data: Dictionary = json.data
			player_level = save_data.player.level
			total_xp = save_data.player.xp
			abilities = save_data.abilities
			ranges = save_data.ranges
			multi_target = save_data.multi_target
			levels_complete = save_data.progress.levels_complete
			current_level = save_data.progress.current_level
			resets_used = save_data.progress.resets_used
			bestiary_unlocked = save_data.bestiary
			volume_master = save_data.settings.volume_master
			volume_music = save_data.settings.volume_music
			volume_sfx = save_data.settings.volume_sfx
			grid_overlay = save_data.settings.grid_overlay
			angle_snap = save_data.settings.angle_snap

func reset_progress() -> void:
	"""Completely reset all progress (for testing or full restart)."""
	player_level = 1
	total_xp = 0
	abilities = {
		"shadow_slide": true,
		"mirrorwalk": true,
		"turn": true,
		"shadow_pivot": false,
		"shadowshift_self": false,
		"shadowshift_object": false,
		"shadowshift_enemy": false,
		"split_power": false,
		"multi_target_mastery": false,
		"combo_2": false,
		"combo_3": false,
		"combo_4": false
	}
	levels_complete = []
	current_level = 1
	resets_used = 0
	bestiary_unlocked = []
	update_ranges()
	save_game()
