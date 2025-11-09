# Shadow Warlock Training - Data Directory

This directory contains all JSON configuration and data files for the Shadow Warlock Training game.

## Directory Structure

```
data/
├── levels/
│   ├── level_schema_example.json
│   ├── level_01.json
│   ├── level_02.json
│   └── ... (more levels)
├── balance/
│   ├── difficulty_settings.json
│   ├── enemy_config.json
│   ├── transformation_params.json
│   └── xp_tables.json
└── README.md (this file)
```

## File Descriptions

### levels/level_schema_example.json
Defines the complete schema for a game level. Each level file extends this structure.

**Key Fields:**
- `level_number`: Unique identifier (1-10)
- `name`: Display name
- `type`: "training", "tactical", or "boss"
- `arena`: Grid size in tiles (width_tiles, height_tiles)
- `player_start`: Starting position and direction
- `objectives`: Primary and secondary goals
- `enemies`: Array of enemy spawn data
- `hazards`: Array of hazard positions
- `barriers`: Wall definitions with start/end points
- `tutorial_sequence`: Tutorial steps (training levels only)
- `xp_reward`: XP granted on completion
- `unlocks_level`: Which level becomes available after completion

**Example Enemy Entry:**
```json
{
  "type": "hound",
  "position": [15, 12],
  "patrol_points": [[10, 12], [20, 12]]
}
```

**Tutorial Step Format:**
```json
{
  "step": 1,
  "text": "Tutorial message",
  "wait_for_input": true,
  "required_action": "shadow_slide",
  "mastery_count": 3
}
```

### balance/difficulty_settings.json
Defines difficulty modes: Easy, Normal, Hard

**Key Differences:**
- **Easy**: Sequential telegraphs, persistent indicators, 3 second duration, ghost previews enabled
- **Normal**: Sequential telegraphs, fade after 1.5 seconds, no previews
- **Hard**: Simultaneous telegraphs, 0.5 second duration, 20-second turn timer, minimal indicators

### balance/enemy_config.json
Configuration data for all enemy types:
- `hound`: Patrol, chase, pounce behavior
- `mirror_wraith`: Mimic and phase abilities
- `hollow_sentinel`: Beam attack and shield
- `architect`: Boss enemy with multiple phases

**Standard Fields:**
- `name`: Display name
- `sprite_color`: Hex color code
- `health`: Hit points
- `animation_duration_seconds`: Animation length
- `ai`: AI parameters (ranges, speeds, behaviors)
- `abilities`: Special abilities with descriptions
- `bestiary_entry`: Unlocked text when defeated

### balance/transformation_params.json
Detailed parameters for each transformation ability:
- `shadow_slide`: Movement mechanic
- `mirrorwalk`: Reflection mechanic
- `pivot`: Self-rotation mechanic
- `shadow_pivot`: External rotation mechanic
- `shadowshift`: Scaling mechanic
- `split_power`: Multi-target mode
- `multi_target_mastery`: Efficient multi-target mode
- `combo`: Combo system rules

**Scaling Formula for Shadowshift:**
```
min_scale = 1 / (level / 2 + 1)
max_scale = level / 2 + 1

Level 1: 0.5x to 2.0x
Level 3: 0.333x to 3.0x
Level 5: 0.25x to 4.0x
```

## Game Balance Reference

### XP Progression
- Total XP to Level 10: 900
- XP per level (linear): ~128.57
- Training levels reward 100 XP each

### Range Scaling
- Base range: 1 tile at Level 1
- Range per level: +1 tile
- Example: Level 3 = 3 tile range

### Target Type Power Costs
- SELF: No cost (100% power)
- OBJECT: -1 level (150% ability cost)
- ENEMY: -2 levels (200% ability cost)

### Multi-Target Limits
- **Split Power** (Level 3+):
  - Level 3: 2 targets
  - Level 5: 3 targets
- **Mastery** (Level 5+):
  - Level 5: 2 targets (-1 per target)
  - Level 7: 3 targets (-1 per target)
  - Level 9: 4 targets (-1 per target)
  - Level 10: Unlimited targets

### Combo Limits
- **Combo 2**: Level 4+
- **Combo 3**: Level 7+
- **Combo 4**: Level 8+

## Creating New Levels

1. **Create a new JSON file** in `data/levels/` named `level_NN.json` (where NN is the level number)
2. **Use level_schema_example.json** as a template
3. **Define the arena** with width/height in tiles
4. **Place enemies** using their type from `balance/enemy_config.json`
5. **Add tutorial steps** for training levels
6. **Test in Godot** by loading through LevelManager

Example minimal level:
```json
{
  "level_number": 5,
  "name": "New Level",
  "type": "tactical",
  "arena": {"width_tiles": 40, "height_tiles": 25},
  "player_start": {"position": [5, 12], "direction": [1, 0]},
  "objectives": {"primary": "Reach the exit", "secondary": []},
  "enemies": [
    {"type": "hound", "position": [20, 12]}
  ],
  "hazards": [],
  "barriers": [],
  "exit": {"position": [35, 12]},
  "xp_reward": 100,
  "unlocks_level": 6
}
```

## GDD References

All data files implement specifications from:
- **Section 7**: Level Design (levels/)
- **Section 8**: Difficulty & Balance (balance/)
- **Section 10**: Game Constants & Systems (all files)

## Validation

JSON files can be validated in Godot using the built-in JSON class:
```gdscript
var json := JSON.new()
var result := json.parse(file_content)
if result == OK:
    var data = json.data
```

Invalid files will prevent level loading and display error messages in the Godot console.
