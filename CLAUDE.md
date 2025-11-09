# Claude Code Memory - Shadow Warlock Training Project

## Important Project Structure & Conventions

### Godot Virtual Filesystem (res://)
- `res://` is Godot's virtual filesystem path that maps to the project root
- Project root: `C:\Users\Seanm\Nextcloud2\Gamedev\GodotGames\shadow-warlock-training`
- `res://scripts/autoload/game_constants.gd` = `C:\Users\Seanm\Nextcloud2\Gamedev\GodotGames\shadow-warlock-training\scripts\autoload\game_constants.gd`
- DO NOT create a `res/` subdirectory - use paths relative to project root
- Always use absolute filesystem paths when using Write/Edit tools

### Current Project Configuration
- Engine: Godot 4.5
- Language: GDScript (tabs for indentation)
- Display: 640x480 viewport, pixel-perfect rendering (nearest filter)
- Physics: No gravity (top-down), GodotPhysics2D, 30 ticks/sec
- Platform: HTML5 Browser deployment

### AutoLoad Singletons Configured
Located in `res://scripts/autoload/`:
1. **GameConstants** - Game balance values, ranges, XP, ability unlocks
2. **GameManager** - Player progression, abilities, levels, settings
3. **SaveSystem** - Browser localStorage (web) / file-based (desktop) save/load

### Directory Structure
```
C:\Users\Seanm\Nextcloud2\Gamedev\GodotGames\shadow-warlock-training\
├── scripts/
│   ├── autoload/        [GameConstants, GameManager, SaveSystem]
│   ├── player/
│   ├── enemies/
│   ├── systems/
│   ├── transformations/
│   ├── ui/
│   └── levels/
├── scenes/
│   ├── main/
│   ├── player/
│   ├── enemies/
│   ├── levels/
│   │   ├── training/
│   │   ├── tactical/
│   │   └── boss/
│   ├── ui/
│   └── effects/
├── assets/
│   ├── sprites/
│   ├── audio/
│   └── fonts/
├── data/
│   ├── levels/
│   └── balance/
└── project.godot
```

## Task Progress - PHASE 1

- ✅ Task 1.1: Project Setup and Configuration (COMPLETE)
- ✅ Task 1.2: Enhanced GameConstants Autoload (COMPLETE)
- ✅ Task 1.3: Enhanced GameManager Autoload (COMPLETE)
- ✅ Task 1.4: SaveSystem Autoload with localStorage (COMPLETE)
- ✅ Task 1.5: Connect GameManager to SaveSystem (COMPLETE)
- ✅ Task 1.6: LevelManager Autoload (COMPLETE)
- ✅ Task 1.7: JSON Data Schema Design (COMPLETE)

## PHASE 1: FOUNDATION & ARCHITECTURE - COMPLETE ✅

All foundation and core systems are now implemented!

## Key Implementation Notes

### Static Fucntions
- Always call static functions through their instantiated objects.
	Example: Call GridSystem static funcs through var gs

### GameConstants
- Tile size: 16 pixels
- Level cap: 10
- Total XP to level 10: 900
- Target type costs: SELF(0), OBJECT(1), ENEMY(2)
- Range scales: +1 tile per level

### GameManager
- Tracks: level, XP, abilities, ranges, multi-target limits, progress, bestiary, settings
- Signals: level_up, xp_gained, ability_unlocked, level_completed
- save_game() and load_game() are stubs awaiting SaveSystem integration (Task 1.5)

### SaveSystem
- Browser localStorage (web) with fallback to file (desktop)
- Format: JSON with version, timestamp, game data
- Functions: save_game(), load_game(), delete_save(), has_save()
- Error handling for quota exceeded, corrupt data, missing interface

## Extended Thinking Policy
- Task 1.1 (Setup): OFF
- Task 1.2 (GameConstants): OFF
- Task 1.3 (GameManager): OFF
- Task 1.4 (SaveSystem): ON
- Task 1.5 (GameManager-SaveSystem): OFF
- Task 1.6 (LevelManager): OFF
- Task 1.7 (JSON Schema): ON
